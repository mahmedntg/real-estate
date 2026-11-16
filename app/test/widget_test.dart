import 'package:aqar_app/core/format.dart';
import 'package:aqar_app/core/labels.dart';
import 'package:aqar_app/core/location_fields.dart';
import 'package:aqar_app/core/session.dart';
import 'package:aqar_app/data/models.dart';
import 'package:aqar_app/features/auth/register_page.dart';
import 'package:aqar_app/features/auth/verify_page.dart';
import 'package:aqar_app/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Arabic locale renders right-to-left', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Builder(
          builder: (context) => Text(AppLocalizations.of(context).appName),
        ),
      ),
    );

    expect(find.text('عقار'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('عقار'))),
      TextDirection.rtl,
    );
  });

  testWidgets('English locale renders left-to-right', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Builder(
          builder: (context) => Text(AppLocalizations.of(context).appName),
        ),
      ),
    );

    expect(find.text('Aqar'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('Aqar'))),
      TextDirection.ltr,
    );
  });

  testWidgets('rent prices use the market currency symbol', (tester) async {
    const egypt = Country(
      code: 'EG',
      nameEn: 'Egypt',
      nameAr: 'مصر',
      currencyCode: 'EGP',
      currencySymbolEn: 'EGP',
      currencySymbolAr: 'ج.م',
      taglineEn: 'Find your next home',
      taglineAr: 'اعثر على منزلك القادم',
      governorates: [],
    );

    Future<String> priceText(Locale locale) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Builder(
            builder: (context) => Text(
              listingPrice(
                context,
                18000,
                ListingType.rent,
                currencySymbol: egypt.currencySymbol(
                  Localizations.localeOf(context).languageCode,
                ),
              ),
            ),
          ),
        ),
      );
      return tester.widget<Text>(find.byType(Text)).data!;
    }

    expect(await priceText(const Locale('en')), '18,000 EGP / month');
    expect(await priceText(const Locale('ar')), '18,000 ج.م / شهريًا');
  });

  testWidgets('qirat areas format per locale', (tester) async {
    Future<String> areaText(Locale locale) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Builder(
            builder: (context) => Text(qiratsLabel(context, 12.5)),
          ),
        ),
      );
      return tester.widget<Text>(find.byType(Text)).data!;
    }

    expect(await areaText(const Locale('en')), '12.50 qirats');
    expect(await areaText(const Locale('ar')), '12.50 قيراط');
  });

  testWidgets('titles fall back to the other language when empty',
      (tester) async {
    Future<String> titleText(
      Locale locale, {
      required String en,
      required String ar,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Builder(
            builder: (context) => Text(
              localizedTitle(context, en: en, ar: ar),
            ),
          ),
        ),
      );
      return tester.widget<Text>(find.byType(Text)).data!;
    }

    expect(
      await titleText(const Locale('en'), en: '', ar: 'شقة في القاهرة'),
      'شقة في القاهرة',
    );
    expect(
      await titleText(const Locale('ar'), en: 'Cairo apartment', ar: ''),
      'Cairo apartment',
    );
    expect(
      await titleText(const Locale('ar'), en: 'Cairo apartment', ar: 'شقة'),
      'شقة',
    );
  });

  testWidgets('governorate autocomplete filters and selects', (tester) async {
    const governorates = [
      Governorate(
        code: 'CAIRO',
        nameEn: 'Cairo',
        nameAr: 'القاهرة',
        areas: [],
      ),
      Governorate(
        code: 'ALEXANDRIA',
        nameEn: 'Alexandria',
        nameAr: 'الإسكندرية',
        areas: [],
      ),
    ];
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Scaffold(
          body: GovernorateAutocomplete(
            governorates: governorates,
            selected: null,
            label: 'Governorate',
            hint: 'Search governorates',
            clearTooltip: 'Clear',
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'alex');
    await tester.pump();
    expect(find.text('Alexandria'), findsOneWidget);
    expect(find.text('Cairo'), findsNothing);

    await tester.tap(find.text('Alexandria'));
    await tester.pump();
    expect(selected, 'ALEXANDRIA');
  });

  testWidgets('register validates confirmation and phone', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: const RegisterPage(),
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'Test User',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'user@aqar.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone (optional)'),
      '12',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'Demo@12345',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm password'),
      'Demo@1234',
    );

    final submit = find.widgetWithText(FilledButton, 'Sign up');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pump();

    expect(find.text('Enter a valid phone number'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('verify page asks for the emailed code', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: const VerifyPage(email: 'user@aqar.test'),
        ),
      ),
    );

    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.controller?.text ?? '', isEmpty);
    expect(find.textContaining('user@aqar.test'), findsOneWidget);
    expect(find.textContaining('Demo mode'), findsNothing);
  });

  test('land boundary lines survive the API round-trip', () {
    final detail = PropertyDetail.fromJson({
      'id': 'p1',
      'titleEn': 'Plot',
      'titleAr': '',
      'descriptionEn': 'A plot.',
      'descriptionAr': '',
      'propertyType': 'LAND',
      'listingType': 'SALE',
      'countryCode': 'EG',
      'governorateCode': 'GIZA',
      'areaCode': 'OCTOBER_6',
      'price': 3200000,
      'areaSqm': 500,
      'furnished': false,
      'images': <Map<String, dynamic>>[],
      'owner': {'id': 'u1', 'fullName': 'Owner'},
      'favorite': false,
      'mine': false,
      'createdAt': '2026-11-16T10:00:00Z',
      'updatedAt': '2026-11-16T10:00:00Z',
      'landKind': 'BUILDING',
      'buildingPermit': true,
      'negotiable': true,
      'boundaryNorth': '12 m street',
      'boundarySouth': 'Neighbouring plot',
      'boundaryEast': 'Neighbouring plot',
      'boundaryWest': '10 m street',
    });

    expect(detail.boundaryNorth, '12 m street');
    expect(detail.boundaryWest, '10 m street');

    final payload = PropertyDraft.fromDetail(detail).toJson();
    expect(payload['boundaryNorth'], '12 m street');
    expect(payload['boundarySouth'], 'Neighbouring plot');
    expect(payload['boundaryEast'], 'Neighbouring plot');
    expect(payload['boundaryWest'], '10 m street');
  });
}
