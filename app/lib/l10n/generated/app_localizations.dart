import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Aqar'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Find your next home'**
  String get tagline;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get navChats;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by area, title, or keyword'**
  String get searchHint;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// No description provided for @sortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortLabel;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// No description provided for @sortPriceAsc.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get sortPriceAsc;

  /// No description provided for @sortPriceDesc.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get sortPriceDesc;

  /// No description provided for @propertyType.
  ///
  /// In en, this message translates to:
  /// **'Property type'**
  String get propertyType;

  /// No description provided for @listingType.
  ///
  /// In en, this message translates to:
  /// **'Listing type'**
  String get listingType;

  /// No description provided for @governorate.
  ///
  /// In en, this message translates to:
  /// **'Governorate'**
  String get governorate;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min price'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max price'**
  String get maxPrice;

  /// No description provided for @bedrooms.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms'**
  String get bedrooms;

  /// No description provided for @bathrooms.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms'**
  String get bathrooms;

  /// No description provided for @furnishedOnly.
  ///
  /// In en, this message translates to:
  /// **'Furnished only'**
  String get furnishedOnly;

  /// No description provided for @any.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get any;

  /// No description provided for @anyArea.
  ///
  /// In en, this message translates to:
  /// **'Any area'**
  String get anyArea;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check your connection.'**
  String get networkError;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get invalidNumber;

  /// No description provided for @positiveNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a value greater than zero'**
  String get positiveNumber;

  /// No description provided for @propertiesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No properties} =1{1 property} other{{count} properties}}'**
  String propertiesCount(int count);

  /// No description provided for @noResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No properties found'**
  String get noResultsTitle;

  /// No description provided for @noResultsBody.
  ///
  /// In en, this message translates to:
  /// **'Try changing your filters or search terms.'**
  String get noResultsBody;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favoritesEmpty;

  /// No description provided for @favoritesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on a listing to save it here.'**
  String get favoritesEmptyBody;

  /// No description provided for @myListingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have not listed any properties yet.'**
  String get myListingsEmpty;

  /// No description provided for @chatsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatsEmpty;

  /// No description provided for @chatsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Message an owner from a property page to start chatting.'**
  String get chatsEmptyBody;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phone;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to save favorites and message owners.'**
  String get loginSubtitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to list and message.'**
  String get registerSubtitle;

  /// No description provided for @noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountPrompt;

  /// No description provided for @haveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccountPrompt;

  /// No description provided for @demoCredentials.
  ///
  /// In en, this message translates to:
  /// **'Demo accounts'**
  String get demoCredentials;

  /// No description provided for @demoOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner demo'**
  String get demoOwner;

  /// No description provided for @demoRenter.
  ///
  /// In en, this message translates to:
  /// **'Renter demo'**
  String get demoRenter;

  /// No description provided for @propertyTypeApartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get propertyTypeApartment;

  /// No description provided for @propertyTypeVilla.
  ///
  /// In en, this message translates to:
  /// **'Villa'**
  String get propertyTypeVilla;

  /// No description provided for @propertyTypeLand.
  ///
  /// In en, this message translates to:
  /// **'Land'**
  String get propertyTypeLand;

  /// No description provided for @propertyTypeOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get propertyTypeOffice;

  /// No description provided for @propertyTypeShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get propertyTypeShop;

  /// No description provided for @forSale.
  ///
  /// In en, this message translates to:
  /// **'For sale'**
  String get forSale;

  /// No description provided for @forRent.
  ///
  /// In en, this message translates to:
  /// **'For rent'**
  String get forRent;

  /// No description provided for @furnished.
  ///
  /// In en, this message translates to:
  /// **'Furnished'**
  String get furnished;

  /// No description provided for @unfurnished.
  ///
  /// In en, this message translates to:
  /// **'Unfurnished'**
  String get unfurnished;

  /// No description provided for @bedroomsShort.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bd} other{{count} bd}}'**
  String bedroomsShort(int count);

  /// No description provided for @bathroomsShort.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ba} other{{count} ba}}'**
  String bathroomsShort(int count);

  /// No description provided for @areaShort.
  ///
  /// In en, this message translates to:
  /// **'{value} m²'**
  String areaShort(String value);

  /// No description provided for @pricePerMonth.
  ///
  /// In en, this message translates to:
  /// **'{price} / month'**
  String pricePerMonth(String price);

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @messageOwner.
  ///
  /// In en, this message translates to:
  /// **'Message owner'**
  String get messageOwner;

  /// No description provided for @signInToMessage.
  ///
  /// In en, this message translates to:
  /// **'Log in to message the owner'**
  String get signInToMessage;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Save to favorites'**
  String get favorite;

  /// No description provided for @unfavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get unfavorite;

  /// No description provided for @signInToFavorite.
  ///
  /// In en, this message translates to:
  /// **'Log in to save favorites'**
  String get signInToFavorite;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendMessage;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get messageHint;

  /// No description provided for @startingChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact the owner'**
  String get startingChatTitle;

  /// No description provided for @startingChatHint.
  ///
  /// In en, this message translates to:
  /// **'Introduce yourself and ask about the property.'**
  String get startingChatHint;

  /// No description provided for @startChat.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get startChat;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Say hello!'**
  String get chatEmpty;

  /// No description provided for @startChatGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, is this property still available?'**
  String get startChatGreeting;

  /// No description provided for @myListings.
  ///
  /// In en, this message translates to:
  /// **'My listings'**
  String get myListings;

  /// No description provided for @newListing.
  ///
  /// In en, this message translates to:
  /// **'New listing'**
  String get newListing;

  /// No description provided for @editListing.
  ///
  /// In en, this message translates to:
  /// **'Edit listing'**
  String get editListing;

  /// No description provided for @createListing.
  ///
  /// In en, this message translates to:
  /// **'Publish listing'**
  String get createListing;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @listingSaved.
  ///
  /// In en, this message translates to:
  /// **'Listing saved'**
  String get listingSaved;

  /// No description provided for @listingDeleted.
  ///
  /// In en, this message translates to:
  /// **'Listing deleted'**
  String get listingDeleted;

  /// No description provided for @deleteListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this listing?'**
  String get deleteListingTitle;

  /// No description provided for @deleteListingBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the listing and its images.'**
  String get deleteListingBody;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get addPhotos;

  /// No description provided for @maxImages.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} images'**
  String maxImages(int count);

  /// No description provided for @noPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get noPhotos;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get basicInfo;

  /// No description provided for @pricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get pricing;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @titleEn.
  ///
  /// In en, this message translates to:
  /// **'Title (English)'**
  String get titleEn;

  /// No description provided for @titleAr.
  ///
  /// In en, this message translates to:
  /// **'Title (Arabic)'**
  String get titleAr;

  /// No description provided for @descriptionEn.
  ///
  /// In en, this message translates to:
  /// **'Description (English)'**
  String get descriptionEn;

  /// No description provided for @descriptionAr.
  ///
  /// In en, this message translates to:
  /// **'Description (Arabic)'**
  String get descriptionAr;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @areaSqm.
  ///
  /// In en, this message translates to:
  /// **'Area (m²)'**
  String get areaSqm;

  /// No description provided for @landDetails.
  ///
  /// In en, this message translates to:
  /// **'Land details'**
  String get landDetails;

  /// No description provided for @landAgricultural.
  ///
  /// In en, this message translates to:
  /// **'Agricultural land'**
  String get landAgricultural;

  /// No description provided for @landBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building plot'**
  String get landBuilding;

  /// No description provided for @areaQirats.
  ///
  /// In en, this message translates to:
  /// **'Area (qirats)'**
  String get areaQirats;

  /// No description provided for @qiratsShort.
  ///
  /// In en, this message translates to:
  /// **'{value} qirats'**
  String qiratsShort(String value);

  /// No description provided for @feddanHint.
  ///
  /// In en, this message translates to:
  /// **'1 feddan = 24 qirats ≈ 4,200 m²'**
  String get feddanHint;

  /// No description provided for @frontage.
  ///
  /// In en, this message translates to:
  /// **'Frontage (m)'**
  String get frontage;

  /// No description provided for @depth.
  ///
  /// In en, this message translates to:
  /// **'Depth (m)'**
  String get depth;

  /// No description provided for @streetWidth.
  ///
  /// In en, this message translates to:
  /// **'Street width (m)'**
  String get streetWidth;

  /// No description provided for @dimensionsShort.
  ///
  /// In en, this message translates to:
  /// **'{frontage} × {depth} m'**
  String dimensionsShort(String frontage, String depth);

  /// No description provided for @streetWidthShort.
  ///
  /// In en, this message translates to:
  /// **'{value} m street'**
  String streetWidthShort(String value);

  /// No description provided for @buildingPermit.
  ///
  /// In en, this message translates to:
  /// **'Building permit'**
  String get buildingPermit;

  /// No description provided for @permitAvailable.
  ///
  /// In en, this message translates to:
  /// **'Building permit available'**
  String get permitAvailable;

  /// No description provided for @permitMissing.
  ///
  /// In en, this message translates to:
  /// **'No building permit'**
  String get permitMissing;

  /// No description provided for @negotiable.
  ///
  /// In en, this message translates to:
  /// **'Price negotiable'**
  String get negotiable;

  /// No description provided for @negotiableBadge.
  ///
  /// In en, this message translates to:
  /// **'Negotiable'**
  String get negotiableBadge;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Image upload failed'**
  String get uploadFailed;

  /// No description provided for @thisIsYourListing.
  ///
  /// In en, this message translates to:
  /// **'This is your listing'**
  String get thisIsYourListing;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @profileSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get profileSignedInAs;

  /// No description provided for @loginToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please log in to continue'**
  String get loginToContinue;

  /// No description provided for @invalidListing.
  ///
  /// In en, this message translates to:
  /// **'This listing is no longer available'**
  String get invalidListing;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidCredentials;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @imageLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You can add up to 8 images'**
  String get imageLimitReached;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get removeImage;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get invalidPhone;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we sent to {email}'**
  String verifyEmailSubtitle(String email);

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @codeSent.
  ///
  /// In en, this message translates to:
  /// **'A new code has been sent'**
  String get codeSent;

  /// No description provided for @emailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Verify your email before logging in'**
  String get emailNotVerified;

  /// No description provided for @verifyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get verifyPrompt;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'The code is incorrect or expired'**
  String get invalidCode;

  /// No description provided for @codeLength.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get codeLength;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @addVideo.
  ///
  /// In en, this message translates to:
  /// **'Add video'**
  String get addVideo;

  /// No description provided for @removeVideo.
  ///
  /// In en, this message translates to:
  /// **'Remove video'**
  String get removeVideo;

  /// No description provided for @videoHint.
  ///
  /// In en, this message translates to:
  /// **'Optional · MP4, WebM or MOV up to 50 MB'**
  String get videoHint;

  /// No description provided for @videoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Video must be 50 MB or smaller'**
  String get videoTooLarge;

  /// No description provided for @videoAttached.
  ///
  /// In en, this message translates to:
  /// **'Saved with this listing'**
  String get videoAttached;

  /// No description provided for @videoPendingUpload.
  ///
  /// In en, this message translates to:
  /// **'Uploads when you save'**
  String get videoPendingUpload;

  /// No description provided for @titleRequiredOneLanguage.
  ///
  /// In en, this message translates to:
  /// **'Enter a title in at least one language'**
  String get titleRequiredOneLanguage;

  /// No description provided for @descriptionRequiredOneLanguage.
  ///
  /// In en, this message translates to:
  /// **'Enter a description in at least one language'**
  String get descriptionRequiredOneLanguage;

  /// No description provided for @governorateHint.
  ///
  /// In en, this message translates to:
  /// **'Search governorates'**
  String get governorateHint;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearSelection;

  /// No description provided for @previousImage.
  ///
  /// In en, this message translates to:
  /// **'Previous photo'**
  String get previousImage;

  /// No description provided for @nextImage.
  ///
  /// In en, this message translates to:
  /// **'Next photo'**
  String get nextImage;

  /// No description provided for @boundaries.
  ///
  /// In en, this message translates to:
  /// **'Boundaries'**
  String get boundaries;

  /// No description provided for @boundaryNorth.
  ///
  /// In en, this message translates to:
  /// **'North boundary'**
  String get boundaryNorth;

  /// No description provided for @boundarySouth.
  ///
  /// In en, this message translates to:
  /// **'South boundary'**
  String get boundarySouth;

  /// No description provided for @boundaryEast.
  ///
  /// In en, this message translates to:
  /// **'East boundary'**
  String get boundaryEast;

  /// No description provided for @boundaryWest.
  ///
  /// In en, this message translates to:
  /// **'West boundary'**
  String get boundaryWest;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
