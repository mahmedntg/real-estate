import 'dart:convert';

import 'package:aqar_app/core/format.dart';
import 'package:aqar_app/core/labels.dart';
import 'package:aqar_app/core/location_fields.dart';
import 'package:aqar_app/core/session.dart';
import 'package:aqar_app/core/ui.dart';
import 'package:aqar_app/data/api.dart';
import 'package:aqar_app/data/models.dart';
import 'package:aqar_app/features/auth/register_page.dart';
import 'package:aqar_app/features/auth/verify_page.dart';
import 'package:aqar_app/features/profile/profile_page.dart';
import 'package:aqar_app/features/property/land_diagram.dart';
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

  testWidgets('qirat areas include the sahm part', (tester) async {
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
            builder: (context) => Text(qiratsSahmLabel(context, 12.5, 6)),
          ),
        ),
      );
      return tester.widget<Text>(find.byType(Text)).data!;
    }

    expect(await areaText(const Locale('en')), '12.50 qirats 6 sahm');
    expect(await areaText(const Locale('ar')), '12.50 قيراط 6 سهم');
  });

  test('whatsapp links strip formatting characters', () {
    expect(whatsAppUrl('+20 100 555 0104'), 'https://wa.me/201005550104');
    expect(whatsAppUrl('201005550104'), 'https://wa.me/201005550104');
  });

  test('phone normalisation keeps a single leading plus', () {
    expect(normalizePhone('+20 101 111 0003'), '+201011110003');
    expect(normalizePhone('+20-101-111-0003'), '+201011110003');
    expect(normalizePhone('20+1011110003'), '201011110003');
    expect(normalizePhone('01011110003'), '01011110003');
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
      find.widgetWithText(TextFormField, 'Phone'),
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
      'title_en': 'Plot',
      'title_ar': '',
      'description_en': 'A plot.',
      'description_ar': '',
      'property_type': 'LAND',
      'listing_type': 'SALE',
      'country_code': 'EG',
      'governorate_code': 'GIZA',
      'area_code': 'OCTOBER_6',
      'price': 3200000,
      'area_sqm': 500,
      'furnished': false,
      'images': <Map<String, dynamic>>[],
      'owner': {'id': 'u1', 'full_name': 'Owner'},
      'favorite': false,
      'mine': false,
      'created_at': '2026-11-16T10:00:00Z',
      'updated_at': '2026-11-16T10:00:00Z',
      'land_kind': 'BUILDING',
      'building_permit': true,
      'negotiable': true,
      'north_side_m': 20,
      'south_side_m': 22,
      'east_side_m': 26,
      'west_side_m': 25,
      'boundary_north': '12 m street',
      'boundary_south': 'Neighbouring plot',
      'boundary_east': 'Neighbouring plot',
      'boundary_west': '10 m street',
    });

    expect(detail.northSideM, 20);
    expect(detail.southSideM, 22);
    expect(detail.westSideM, 25);
    expect(detail.boundaryNorth, '12 m street');
    expect(detail.boundaryWest, '10 m street');

    final payload = PropertyDraft.fromDetail(detail).toJson();
    expect(payload['north_side_m'], 20);
    expect(payload['south_side_m'], 22);
    expect(payload['east_side_m'], 26);
    expect(payload['west_side_m'], 25);
    expect(payload['boundary_north'], '12 m street');
    expect(payload['boundary_south'], 'Neighbouring plot');
    expect(payload['boundary_east'], 'Neighbouring plot');
    expect(payload['boundary_west'], '10 m street');
  });

  testWidgets('land diagram renders all four sides and the area label',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LandDiagram(
            northLabel: 'North: 50 m',
            southLabel: 'South: 60 m',
            eastLabel: 'East: 30 m',
            westLabel: 'West: 26 m',
            areaLabel: '5.00 qirats 12 sahm',
          ),
        ),
      ),
    );

    expect(find.byType(LandDiagram), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('listings without a photo show the bundled default image',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 160,
          height: 100,
          child: AppNetworkImage(''),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, defaultListingImage);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new mobile number is verified before the profile saves',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'session': jsonEncode(
        const Session(
          token: 'token',
          user: User(
            id: 'u1',
            fullName: 'Demo Owner',
            email: 'owner@aqar.app',
            role: UserRole.user,
            phone: '+201005550101',
            whatsapp: '+201005550101',
          ),
        ).toJson(),
      ),
    });
    final prefs = await SharedPreferences.getInstance();
    final api = _FakeApi();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          apiProvider.overrideWithValue(api),
        ],
        child: MaterialApp(
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: const ProfilePage(),
        ),
      ),
    );

    await tester.tap(find.text('Contact details'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(1),
      '+20 109 999 0012',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Verify your new mobile number'), findsOneWidget);
    expect(find.textContaining('+201099990012'), findsOneWidget);
    expect(api.calls, ['start:+201099990012']);

    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(api.calls, [
      'start:+201099990012',
      'confirm:+201099990012:123456',
      'update:Demo Owner:+201005550101:',
    ]);
    expect(find.text('Profile updated'), findsOneWidget);
    expect(find.text('+201099990012'), findsOneWidget);
  });
}

class _FakeApi extends AqarApi {
  _FakeApi()
      : super(() => 'token', baseUrl: 'http://localhost', onUnauthorized: () {});

  final List<String> calls = [];
  User _user = const User(
    id: 'u1',
    fullName: 'Demo Owner',
    email: 'owner@aqar.app',
    role: UserRole.user,
    phone: '+201005550101',
    whatsapp: '+201005550101',
  );

  @override
  Future<String> startPhoneChange(String phone) async {
    calls.add('start:$phone');
    return phone;
  }

  @override
  Future<User> confirmPhoneChange(String phone, String code) async {
    calls.add('confirm:$phone:$code');
    _user = User(
      id: _user.id,
      fullName: _user.fullName,
      email: _user.email,
      role: _user.role,
      phone: phone,
      whatsapp: _user.whatsapp,
      facebookUrl: _user.facebookUrl,
    );
    return _user;
  }

  @override
  Future<User> updateProfile({
    required String fullName,
    String? whatsapp,
    String? facebookUrl,
  }) async {
    calls.add('update:$fullName:${whatsapp ?? ''}:${facebookUrl ?? ''}');
    _user = User(
      id: _user.id,
      fullName: fullName,
      email: _user.email,
      role: _user.role,
      phone: _user.phone,
      whatsapp: whatsapp,
      facebookUrl: facebookUrl,
    );
    return _user;
  }
}
