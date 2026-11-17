// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Aqar';

  @override
  String get tagline => 'Find your next home';

  @override
  String get navHome => 'Home';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navChats => 'Chats';

  @override
  String get navProfile => 'Profile';

  @override
  String get searchHint => 'Search by area, title, or keyword';

  @override
  String get filters => 'Filters';

  @override
  String get filtersTitle => 'Filters';

  @override
  String get sortLabel => 'Sort by';

  @override
  String get sortNewest => 'Newest';

  @override
  String get sortPriceAsc => 'Price: low to high';

  @override
  String get sortPriceDesc => 'Price: high to low';

  @override
  String get propertyType => 'Property type';

  @override
  String get listingType => 'Listing type';

  @override
  String get governorate => 'Governorate';

  @override
  String get area => 'Area';

  @override
  String get country => 'Country';

  @override
  String get minPrice => 'Min price';

  @override
  String get maxPrice => 'Max price';

  @override
  String get bedrooms => 'Bedrooms';

  @override
  String get bathrooms => 'Bathrooms';

  @override
  String get furnishedOnly => 'Furnished only';

  @override
  String get any => 'Any';

  @override
  String get anyArea => 'Any area';

  @override
  String get apply => 'Apply';

  @override
  String get reset => 'Reset';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get retry => 'Try again';

  @override
  String get loading => 'Loading…';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get networkError => 'Cannot reach the server. Check your connection.';

  @override
  String get requiredField => 'This field is required';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get passwordTooShort => 'Use at least 8 characters';

  @override
  String get invalidNumber => 'Enter a valid number';

  @override
  String get positiveNumber => 'Enter a value greater than zero';

  @override
  String propertiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count properties',
      one: '1 property',
      zero: 'No properties',
    );
    return '$_temp0';
  }

  @override
  String get noResultsTitle => 'No properties found';

  @override
  String get noResultsBody => 'Try changing your filters or search terms.';

  @override
  String get favoritesEmpty => 'No favorites yet';

  @override
  String get favoritesEmptyBody =>
      'Tap the heart on a listing to save it here.';

  @override
  String get myListingsEmpty => 'You have not listed any properties yet.';

  @override
  String get chatsEmpty => 'No conversations yet';

  @override
  String get chatsEmptyBody =>
      'Message an owner from a property page to start chatting.';

  @override
  String get login => 'Log in';

  @override
  String get register => 'Sign up';

  @override
  String get logout => 'Log out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full name';

  @override
  String get phone => 'Phone';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'Log in to save favorites and message owners.';

  @override
  String get registerSubtitle => 'Create an account to list and message.';

  @override
  String get noAccountPrompt => 'Don\'t have an account?';

  @override
  String get haveAccountPrompt => 'Already have an account?';

  @override
  String get demoCredentials => 'Demo accounts';

  @override
  String get demoOwner => 'Owner demo';

  @override
  String get demoRenter => 'Renter demo';

  @override
  String get propertyTypeApartment => 'Apartment';

  @override
  String get propertyTypeVilla => 'Villa';

  @override
  String get propertyTypeLand => 'Land';

  @override
  String get propertyTypeOffice => 'Office';

  @override
  String get propertyTypeShop => 'Shop';

  @override
  String get forSale => 'For sale';

  @override
  String get forRent => 'For rent';

  @override
  String get furnished => 'Furnished';

  @override
  String get unfurnished => 'Unfurnished';

  @override
  String bedroomsShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bd',
      one: '1 bd',
    );
    return '$_temp0';
  }

  @override
  String bathroomsShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ba',
      one: '1 ba',
    );
    return '$_temp0';
  }

  @override
  String areaShort(String value) {
    return '$value m²';
  }

  @override
  String pricePerMonth(String price) {
    return '$price / month';
  }

  @override
  String get description => 'Description';

  @override
  String get details => 'Details';

  @override
  String get owner => 'Owner';

  @override
  String get messageOwner => 'Message owner';

  @override
  String get signInToMessage => 'Log in to message the owner';

  @override
  String get favorite => 'Save to favorites';

  @override
  String get unfavorite => 'Remove from favorites';

  @override
  String get signInToFavorite => 'Log in to save favorites';

  @override
  String get sendMessage => 'Send';

  @override
  String get messageHint => 'Write a message…';

  @override
  String get startingChatTitle => 'Contact the owner';

  @override
  String get startingChatHint =>
      'Introduce yourself and ask about the property.';

  @override
  String get startChat => 'Send message';

  @override
  String get chatEmpty => 'No messages yet. Say hello!';

  @override
  String get startChatGreeting => 'Hi, is this property still available?';

  @override
  String get myListings => 'My listings';

  @override
  String get newListing => 'New listing';

  @override
  String get editListing => 'Edit listing';

  @override
  String get createListing => 'Publish listing';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get listingSaved => 'Listing saved';

  @override
  String get listingDeleted => 'Listing deleted';

  @override
  String get deleteListingTitle => 'Delete this listing?';

  @override
  String get deleteListingBody =>
      'This permanently removes the listing and its images.';

  @override
  String get photos => 'Photos';

  @override
  String get addPhotos => 'Add photos';

  @override
  String maxImages(int count) {
    return 'Up to $count images';
  }

  @override
  String get noPhotos => 'No photos yet';

  @override
  String get basicInfo => 'Basics';

  @override
  String get pricing => 'Pricing';

  @override
  String get location => 'Location';

  @override
  String get titleEn => 'Title (English)';

  @override
  String get titleAr => 'Title (Arabic)';

  @override
  String get descriptionEn => 'Description (English)';

  @override
  String get descriptionAr => 'Description (Arabic)';

  @override
  String get price => 'Price';

  @override
  String get areaSqm => 'Area (m²)';

  @override
  String get landDetails => 'Land details';

  @override
  String get landAgricultural => 'Agricultural land';

  @override
  String get landBuilding => 'Building plot';

  @override
  String get areaQirats => 'Area (qirats)';

  @override
  String get areaSahm => 'Sahm';

  @override
  String get feddanHint => '1 feddan = 24 qirats · 1 qirat = 24 sahm';

  @override
  String get sahmHint => '24 sahm = 1 qirat';

  @override
  String get sahmRequiresQirats => 'Enter qirats before sahm';

  @override
  String get sahmRange => 'Sahm is between 0 and 23';

  @override
  String get plotDimensions => 'Plot dimensions';

  @override
  String get plotSidesHint => 'Enter all four sides, or leave them empty';

  @override
  String get plotSidesRequired =>
      'Enter all four plot sides, or leave them empty';

  @override
  String get sideEast => 'East (m)';

  @override
  String get sideWest => 'West (m)';

  @override
  String get sideNorth => 'North (m)';

  @override
  String get sideSouth => 'South (m)';

  @override
  String plotSideValue(String label, String value) {
    return '$label: $value m';
  }

  @override
  String get streetWidth => 'Street width (m)';

  @override
  String qiratsShort(String value) {
    return '$value qirats';
  }

  @override
  String sahmShort(int value) {
    return '$value sahm';
  }

  @override
  String streetWidthShort(String value) {
    return '$value m street';
  }

  @override
  String get buildingPermit => 'Building permit';

  @override
  String get permitAvailable => 'Building permit available';

  @override
  String get permitMissing => 'No building permit';

  @override
  String get negotiable => 'Price negotiable';

  @override
  String get negotiableBadge => 'Negotiable';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get uploadFailed => 'Image upload failed';

  @override
  String get thisIsYourListing => 'This is your listing';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get admin => 'Admin';

  @override
  String get profileSignedInAs => 'Signed in as';

  @override
  String get loginToContinue => 'Please log in to continue';

  @override
  String get invalidListing => 'This listing is no longer available';

  @override
  String get invalidCredentials => 'Invalid email or password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get imageLimitReached => 'You can add up to 8 images';

  @override
  String get removeImage => 'Remove image';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get invalidPhone => 'Enter a valid phone number';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String verifyEmailSubtitle(String email) {
    return 'Enter the 6-digit code we sent to $email';
  }

  @override
  String get verificationCode => 'Verification code';

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Resend code';

  @override
  String get codeSent => 'A new code has been sent';

  @override
  String get emailNotVerified => 'Verify your email before logging in';

  @override
  String get verifyPrompt => 'Verify email';

  @override
  String get invalidCode => 'The code is incorrect or expired';

  @override
  String get codeLength => 'Enter the 6-digit code';

  @override
  String get video => 'Video';

  @override
  String get addVideo => 'Add video';

  @override
  String get removeVideo => 'Remove video';

  @override
  String get videoHint => 'Optional · MP4, WebM or MOV up to 50 MB';

  @override
  String get videoTooLarge => 'Video must be 50 MB or smaller';

  @override
  String get videoAttached => 'Saved with this listing';

  @override
  String get videoPendingUpload => 'Uploads when you save';

  @override
  String get titleRequiredOneLanguage =>
      'Enter a title in at least one language';

  @override
  String get descriptionRequiredOneLanguage =>
      'Enter a description in at least one language';

  @override
  String get governorateHint => 'Search governorates';

  @override
  String get clearSelection => 'Clear';

  @override
  String get previousImage => 'Previous photo';

  @override
  String get nextImage => 'Next photo';

  @override
  String get boundaries => 'Boundaries';

  @override
  String get boundaryNorth => 'North boundary';

  @override
  String get boundarySouth => 'South boundary';

  @override
  String get boundaryEast => 'East boundary';

  @override
  String get boundaryWest => 'West boundary';

  @override
  String get ownerContact => 'Contact details';

  @override
  String get callSeller => 'Call';

  @override
  String get whatsapp => 'WhatsApp';

  @override
  String get facebook => 'Facebook';

  @override
  String get whatsappNumber => 'WhatsApp number (optional)';

  @override
  String get facebookUrl => 'Facebook link (optional)';

  @override
  String get phoneRequired => 'Enter your phone number';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get invalidUrl =>
      'Enter a valid link starting with http:// or https://';

  @override
  String get phoneChangeHint =>
      'Changing your mobile number requires a verification code.';

  @override
  String get verifyNewNumber => 'Verify your new mobile number';

  @override
  String codeSentToNumber(String phone) {
    return 'Enter the 6-digit code sent on WhatsApp to $phone';
  }

  @override
  String get downloadAndroidApp => 'Download Android app';

  @override
  String get downloadAndroidAppBody => 'Install the native app on your phone';
}
