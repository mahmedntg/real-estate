// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'عقار';

  @override
  String get tagline => 'اعثر على منزلك القادم';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navFavorites => 'المفضلة';

  @override
  String get navChats => 'المحادثات';

  @override
  String get navProfile => 'حسابي';

  @override
  String get searchHint => 'ابحث بالمنطقة أو العنوان أو كلمة مفتاحية';

  @override
  String get filters => 'التصفية';

  @override
  String get filtersTitle => 'التصفية';

  @override
  String get sortLabel => 'الترتيب حسب';

  @override
  String get sortNewest => 'الأحدث';

  @override
  String get sortPriceAsc => 'السعر: من الأقل إلى الأعلى';

  @override
  String get sortPriceDesc => 'السعر: من الأعلى إلى الأقل';

  @override
  String get propertyType => 'نوع العقار';

  @override
  String get listingType => 'نوع العرض';

  @override
  String get governorate => 'المحافظة';

  @override
  String get area => 'المنطقة';

  @override
  String get country => 'الدولة';

  @override
  String get minPrice => 'أقل سعر';

  @override
  String get maxPrice => 'أعلى سعر';

  @override
  String get bedrooms => 'غرف النوم';

  @override
  String get bathrooms => 'الحمامات';

  @override
  String get furnishedOnly => 'مفروش فقط';

  @override
  String get any => 'الكل';

  @override
  String get anyArea => 'كل المناطق';

  @override
  String get apply => 'تطبيق';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get close => 'إغلاق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get somethingWentWrong => 'حدث خطأ ما. يرجى المحاولة مجددًا.';

  @override
  String get networkError => 'تعذّر الوصول إلى الخادم. تحقق من اتصالك.';

  @override
  String get requiredField => 'هذا الحقل مطلوب';

  @override
  String get invalidEmail => 'أدخل بريدًا إلكترونيًا صحيحًا';

  @override
  String get passwordTooShort => 'استخدم 8 أحرف على الأقل';

  @override
  String get invalidNumber => 'أدخل رقمًا صحيحًا';

  @override
  String get positiveNumber => 'أدخل قيمة أكبر من صفر';

  @override
  String propertiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عقار',
      many: '$count عقارًا',
      few: '$count عقارات',
      two: 'عقاران',
      one: 'عقار واحد',
      zero: 'لا توجد عقارات',
    );
    return '$_temp0';
  }

  @override
  String get noResultsTitle => 'لا توجد عقارات';

  @override
  String get noResultsBody => 'جرّب تغيير عوامل التصفية أو كلمات البحث.';

  @override
  String get favoritesEmpty => 'لا توجد مفضلات بعد';

  @override
  String get favoritesEmptyBody => 'اضغط على القلب في أي عقار لحفظه هنا.';

  @override
  String get myListingsEmpty => 'لم تنشر أي عقارات بعد.';

  @override
  String get chatsEmpty => 'لا توجد محادثات بعد';

  @override
  String get chatsEmptyBody => 'راسل المالك من صفحة العقار لبدء محادثة.';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get phone => 'رقم الهاتف (اختياري)';

  @override
  String get welcomeBack => 'مرحبًا بعودتك';

  @override
  String get loginSubtitle => 'سجّل الدخول لحفظ المفضلة ومراسلة المالكين.';

  @override
  String get registerSubtitle => 'أنشئ حسابًا لنشر العقارات ومراسلة الآخرين.';

  @override
  String get noAccountPrompt => 'ليس لديك حساب؟';

  @override
  String get haveAccountPrompt => 'لديك حساب بالفعل؟';

  @override
  String get demoCredentials => 'حسابات تجريبية';

  @override
  String get demoOwner => 'حساب المالك';

  @override
  String get demoRenter => 'حساب المستأجر';

  @override
  String get propertyTypeApartment => 'شقة';

  @override
  String get propertyTypeVilla => 'فيلا';

  @override
  String get propertyTypeLand => 'أرض';

  @override
  String get propertyTypeOffice => 'مكتب';

  @override
  String get propertyTypeShop => 'محل';

  @override
  String get forSale => 'للبيع';

  @override
  String get forRent => 'للإيجار';

  @override
  String get furnished => 'مفروش';

  @override
  String get unfurnished => 'غير مفروش';

  @override
  String bedroomsShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count غرفة',
      many: '$count غرفة',
      few: '$count غرف',
      two: 'غرفتان',
      one: 'غرفة واحدة',
      zero: 'لا غرف',
    );
    return '$_temp0';
  }

  @override
  String bathroomsShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حمام',
      many: '$count حمامًا',
      few: '$count حمامات',
      two: 'حمامان',
      one: 'حمام واحد',
      zero: 'لا حمامات',
    );
    return '$_temp0';
  }

  @override
  String areaShort(String value) {
    return '$value م²';
  }

  @override
  String pricePerMonth(String price) {
    return '$price / شهريًا';
  }

  @override
  String get description => 'الوصف';

  @override
  String get details => 'التفاصيل';

  @override
  String get owner => 'المالك';

  @override
  String get messageOwner => 'مراسلة المالك';

  @override
  String get signInToMessage => 'سجّل الدخول لمراسلة المالك';

  @override
  String get favorite => 'حفظ في المفضلة';

  @override
  String get unfavorite => 'إزالة من المفضلة';

  @override
  String get signInToFavorite => 'سجّل الدخول لحفظ المفضلة';

  @override
  String get sendMessage => 'إرسال';

  @override
  String get messageHint => 'اكتب رسالة…';

  @override
  String get startingChatTitle => 'مراسلة المالك';

  @override
  String get startingChatHint => 'عرّف بنفسك واسأل عن العقار.';

  @override
  String get startChat => 'إرسال الرسالة';

  @override
  String get chatEmpty => 'لا توجد رسائل بعد. ابدأ بالتحية!';

  @override
  String get startChatGreeting => 'مرحبًا، هل هذا العقار ما زال متاحًا؟';

  @override
  String get myListings => 'عقاراتي';

  @override
  String get newListing => 'عقار جديد';

  @override
  String get editListing => 'تعديل العقار';

  @override
  String get createListing => 'نشر العقار';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get listingSaved => 'تم حفظ العقار';

  @override
  String get listingDeleted => 'تم حذف العقار';

  @override
  String get deleteListingTitle => 'حذف هذا العقار؟';

  @override
  String get deleteListingBody => 'سيؤدي هذا إلى حذف العقار وصوره نهائيًا.';

  @override
  String get photos => 'الصور';

  @override
  String get addPhotos => 'إضافة صور';

  @override
  String maxImages(int count) {
    return 'حتى $count صور';
  }

  @override
  String get noPhotos => 'لا توجد صور بعد';

  @override
  String get basicInfo => 'الأساسيات';

  @override
  String get pricing => 'التسعير';

  @override
  String get location => 'الموقع';

  @override
  String get titleEn => 'العنوان (الإنجليزية)';

  @override
  String get titleAr => 'العنوان (العربية)';

  @override
  String get descriptionEn => 'الوصف (الإنجليزية)';

  @override
  String get descriptionAr => 'الوصف (العربية)';

  @override
  String get price => 'السعر';

  @override
  String get areaSqm => 'المساحة (م²)';

  @override
  String get landDetails => 'بيانات الأرض';

  @override
  String get landAgricultural => 'أرض زراعية';

  @override
  String get landBuilding => 'قطعة أرض للبناء';

  @override
  String get areaQirats => 'المساحة (قيراط)';

  @override
  String qiratsShort(String value) {
    return '$value قيراط';
  }

  @override
  String get feddanHint => 'الفدان = 24 قيراطًا ≈ 4,200 م²';

  @override
  String get frontage => 'الواجهة (م)';

  @override
  String get depth => 'العمق (م)';

  @override
  String get streetWidth => 'عرض الشارع (م)';

  @override
  String dimensionsShort(String frontage, String depth) {
    return '$frontage × $depth م';
  }

  @override
  String streetWidthShort(String value) {
    return 'شارع بعرض $value م';
  }

  @override
  String get buildingPermit => 'رخصة البناء';

  @override
  String get permitAvailable => 'رخصة بناء متوفرة';

  @override
  String get permitMissing => 'بدون رخصة بناء';

  @override
  String get negotiable => 'السعر قابل للتفاوض';

  @override
  String get negotiableBadge => 'قابل للتفاوض';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get uploadFailed => 'فشل رفع الصورة';

  @override
  String get thisIsYourListing => 'هذا عقارك';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get admin => 'مشرف';

  @override
  String get profileSignedInAs => 'مسجّل الدخول باسم';

  @override
  String get loginToContinue => 'يرجى تسجيل الدخول للمتابعة';

  @override
  String get invalidListing => 'هذا العقار غير متاح';

  @override
  String get invalidCredentials => 'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get imageLimitReached => 'يمكنك إضافة 8 صور كحد أقصى';

  @override
  String get removeImage => 'إزالة الصورة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get invalidPhone => 'أدخل رقم هاتف صحيحًا';

  @override
  String get verifyEmailTitle => 'تحقّق من بريدك الإلكتروني';

  @override
  String verifyEmailSubtitle(String email) {
    return 'أدخل الرمز المكوّن من 6 أرقام الذي أرسلناه إلى $email';
  }

  @override
  String get verificationCode => 'رمز التحقق';

  @override
  String get verify => 'تحقّق';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String get codeSent => 'تم إرسال رمز جديد';

  @override
  String get emailNotVerified => 'يرجى تأكيد بريدك الإلكتروني قبل تسجيل الدخول';

  @override
  String get verifyPrompt => 'تأكيد البريد الإلكتروني';

  @override
  String get invalidCode => 'الرمز غير صحيح أو منتهي الصلاحية';

  @override
  String get codeLength => 'أدخل الرمز المكوّن من 6 أرقام';

  @override
  String get video => 'الفيديو';

  @override
  String get addVideo => 'إضافة فيديو';

  @override
  String get removeVideo => 'إزالة الفيديو';

  @override
  String get videoHint => 'اختياري · MP4 أو WebM أو MOV حتى 50 ميجابايت';

  @override
  String get videoTooLarge => 'يجب ألا يتجاوز الفيديو 50 ميجابايت';

  @override
  String get videoAttached => 'محفوظ مع هذا العقار';

  @override
  String get videoPendingUpload => 'سيُرفع عند الحفظ';

  @override
  String get titleRequiredOneLanguage => 'أدخل العنوان بلغة واحدة على الأقل';

  @override
  String get descriptionRequiredOneLanguage =>
      'أدخل الوصف بلغة واحدة على الأقل';

  @override
  String get governorateHint => 'ابحث عن المحافظة';

  @override
  String get clearSelection => 'مسح';

  @override
  String get previousImage => 'الصورة السابقة';

  @override
  String get nextImage => 'الصورة التالية';

  @override
  String get boundaries => 'الحدود';

  @override
  String get boundaryNorth => 'الحد البحري';

  @override
  String get boundarySouth => 'الحد القبلي';

  @override
  String get boundaryEast => 'الحد الشرقي';

  @override
  String get boundaryWest => 'الحد الغربي';
}
