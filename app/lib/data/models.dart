enum PropertyType {
  apartment('APARTMENT'),
  villa('VILLA'),
  land('LAND'),
  office('OFFICE'),
  shop('SHOP');

  const PropertyType(this.apiValue);

  final String apiValue;

  static PropertyType fromApi(String value) =>
      values.firstWhere((type) => type.apiValue == value, orElse: () => apartment);
}

enum ListingType {
  sale('SALE'),
  rent('RENT');

  const ListingType(this.apiValue);

  final String apiValue;

  static ListingType fromApi(String value) =>
      values.firstWhere((type) => type.apiValue == value, orElse: () => rent);
}

enum LandKind {
  agricultural('AGRICULTURAL'),
  building('BUILDING');

  const LandKind(this.apiValue);

  final String apiValue;

  static LandKind? fromApi(String? value) {
    for (final kind in values) {
      if (kind.apiValue == value) {
        return kind;
      }
    }
    return null;
  }
}

class Area {
  const Area({required this.code, required this.nameEn, required this.nameAr});

  factory Area.fromJson(Map<String, dynamic> json) => Area(
        code: json['code'] as String,
        nameEn: json['name_en'] as String,
        nameAr: json['name_ar'] as String,
      );

  final String code;
  final String nameEn;
  final String nameAr;
}

class Governorate {
  const Governorate({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.areas,
  });

  factory Governorate.fromJson(Map<String, dynamic> json) => Governorate(
        code: json['code'] as String,
        nameEn: json['name_en'] as String,
        nameAr: json['name_ar'] as String,
        areas: [
          for (final area in (json['areas'] as List? ?? const []))
            Area.fromJson(area as Map<String, dynamic>),
        ],
      );

  final String code;
  final String nameEn;
  final String nameAr;
  final List<Area> areas;
}

class Country {
  const Country({
    required this.code,
    required this.nameEn,
    required this.nameAr,
    required this.currencyCode,
    required this.currencySymbolEn,
    required this.currencySymbolAr,
    required this.taglineEn,
    required this.taglineAr,
    required this.governorates,
  });

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        code: json['code'] as String,
        nameEn: json['name_en'] as String,
        nameAr: json['name_ar'] as String,
        currencyCode: json['currency_code'] as String,
        currencySymbolEn: json['currency_symbol_en'] as String,
        currencySymbolAr: json['currency_symbol_ar'] as String,
        taglineEn: json['tagline_en'] as String,
        taglineAr: json['tagline_ar'] as String,
        governorates: [
          for (final governorate in (json['governorates'] as List? ?? const []))
            Governorate.fromJson(governorate as Map<String, dynamic>),
        ],
      );

  final String code;
  final String nameEn;
  final String nameAr;
  final String currencyCode;
  final String currencySymbolEn;
  final String currencySymbolAr;
  final String taglineEn;
  final String taglineAr;
  final List<Governorate> governorates;

  String currencySymbol(String languageCode) =>
      languageCode == 'ar' ? currencySymbolAr : currencySymbolEn;
}

class LocationCatalog {
  const LocationCatalog(this.countries);

  factory LocationCatalog.fromJson(List<dynamic> json) => LocationCatalog([
        for (final country in json)
          Country.fromJson(country as Map<String, dynamic>),
      ]);

  final List<Country> countries;

  Country? byCode(String? code) {
    for (final country in countries) {
      if (country.code == code) {
        return country;
      }
    }
    return countries.isEmpty ? null : countries.first;
  }

  Governorate? governorate(Country? country, String? code) {
    if (country == null || code == null) {
      return null;
    }
    for (final governorate in country.governorates) {
      if (governorate.code == code) {
        return governorate;
      }
    }
    return null;
  }

  Area? area(Governorate? governorate, String? code) {
    if (governorate == null || code == null) {
      return null;
    }
    for (final area in governorate.areas) {
      if (area.code == code) {
        return area;
      }
    }
    return null;
  }
}

enum UserRole {
  user('USER'),
  admin('ADMIN');

  const UserRole(this.apiValue);

  final String apiValue;

  static UserRole fromApi(String value) =>
      values.firstWhere((role) => role.apiValue == value, orElse: () => user);
}

class User {
  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.whatsapp,
    this.facebookUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        whatsapp: json['whatsapp'] as String?,
        facebookUrl: json['facebook_url'] as String?,
        role: UserRole.fromApi(json['role'] as String),
      );

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? whatsapp;
  final String? facebookUrl;
  final UserRole role;

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'whatsapp': whatsapp,
        'facebook_url': facebookUrl,
        'role': role.apiValue,
      };
}

class Session {
  const Session({required this.token, required this.user});

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        token: json['token'] as String,
        user: User.fromJson(json['user'] as Map<String, dynamic>),
      );

  final String token;
  final User user;

  Map<String, dynamic> toJson() => {'token': token, 'user': user.toJson()};
}

class RegisterResult {
  const RegisterResult({required this.email, required this.verificationRequired});

  factory RegisterResult.fromJson(Map<String, dynamic> json) => RegisterResult(
        email: json['email'] as String,
        verificationRequired: json['verification_required'] as bool? ?? false,
      );

  final String email;
  final bool verificationRequired;
}

class PropertyImage {
  const PropertyImage({required this.id, required this.url});

  factory PropertyImage.fromJson(Map<String, dynamic> json) =>
      PropertyImage(id: json['id'] as String, url: json['url'] as String);

  final String id;
  final String url;
}

class PropertyOwner {
  const PropertyOwner({required this.id, required this.fullName});

  factory PropertyOwner.fromJson(Map<String, dynamic> json) =>
      PropertyOwner(id: json['id'] as String, fullName: json['full_name'] as String);

  final String id;
  final String fullName;
}

class SellerContact {
  const SellerContact({this.phone, this.whatsapp, this.facebookUrl});

  factory SellerContact.fromJson(Map<String, dynamic> json) => SellerContact(
        phone: json['phone'] as String?,
        whatsapp: json['whatsapp'] as String?,
        facebookUrl: json['facebook_url'] as String?,
      );

  final String? phone;
  final String? whatsapp;
  final String? facebookUrl;
}

class PropertySummary {
  const PropertySummary({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.propertyType,
    required this.listingType,
    required this.countryCode,
    required this.governorateCode,
    required this.price,
    required this.furnished,
    required this.favorite,
    required this.createdAt,
    this.areaCode,
    this.areaSqm,
    this.bedrooms,
    this.bathrooms,
    this.coverImage,
    this.landKind,
    this.areaQirats,
    this.areaSahm,
    this.negotiable = false,
  });

  factory PropertySummary.fromJson(Map<String, dynamic> json) => PropertySummary(
        id: json['id'] as String,
        titleEn: json['title_en'] as String,
        titleAr: json['title_ar'] as String,
        propertyType: PropertyType.fromApi(json['property_type'] as String),
        listingType: ListingType.fromApi(json['listing_type'] as String),
        countryCode: json['country_code'] as String,
        governorateCode: json['governorate_code'] as String,
        areaCode: json['area_code'] as String?,
        price: json['price'] as num,
        areaSqm: json['area_sqm'] as num?,
        bedrooms: (json['bedrooms'] as num?)?.toInt(),
        bathrooms: (json['bathrooms'] as num?)?.toInt(),
        furnished: json['furnished'] as bool? ?? false,
        coverImage: json['cover_image'] as String?,
        favorite: json['favorite'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        landKind: LandKind.fromApi(json['land_kind'] as String?),
        areaQirats: json['area_qirats'] as num?,
        areaSahm: (json['area_sahm'] as num?)?.toInt(),
        negotiable: json['negotiable'] as bool? ?? false,
      );

  final String id;
  final String titleEn;
  final String titleAr;
  final PropertyType propertyType;
  final ListingType listingType;
  final String countryCode;
  final String governorateCode;
  final String? areaCode;
  final num price;
  final num? areaSqm;
  final int? bedrooms;
  final int? bathrooms;
  final bool furnished;
  final String? coverImage;
  final bool favorite;
  final DateTime createdAt;
  final LandKind? landKind;
  final num? areaQirats;
  final int? areaSahm;
  final bool negotiable;

  PropertySummary copyWith({bool? favorite}) => PropertySummary(
        id: id,
        titleEn: titleEn,
        titleAr: titleAr,
        propertyType: propertyType,
        listingType: listingType,
        countryCode: countryCode,
        governorateCode: governorateCode,
        areaCode: areaCode,
        price: price,
        areaSqm: areaSqm,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        furnished: furnished,
        coverImage: coverImage,
        favorite: favorite ?? this.favorite,
        createdAt: createdAt,
        landKind: landKind,
        areaQirats: areaQirats,
        areaSahm: areaSahm,
        negotiable: negotiable,
      );
}

class PropertyDetail {
  const PropertyDetail({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.propertyType,
    required this.listingType,
    required this.countryCode,
    required this.governorateCode,
    required this.price,
    required this.furnished,
    required this.images,
    required this.owner,
    required this.favorite,
    required this.mine,
    required this.createdAt,
    required this.updatedAt,
    this.videoUrl,
    this.areaCode,
    this.areaSqm,
    this.bedrooms,
    this.bathrooms,
    this.latitude,
    this.longitude,
    this.landKind,
    this.areaQirats,
    this.areaSahm,
    this.northSideM,
    this.southSideM,
    this.eastSideM,
    this.westSideM,
    this.streetWidthM,
    this.buildingPermit,
    this.boundaryNorth,
    this.boundarySouth,
    this.boundaryEast,
    this.boundaryWest,
    this.negotiable = false,
    this.contact,
  });

  factory PropertyDetail.fromJson(Map<String, dynamic> json) => PropertyDetail(
        id: json['id'] as String,
        titleEn: json['title_en'] as String,
        titleAr: json['title_ar'] as String,
        descriptionEn: json['description_en'] as String,
        descriptionAr: json['description_ar'] as String,
        propertyType: PropertyType.fromApi(json['property_type'] as String),
        listingType: ListingType.fromApi(json['listing_type'] as String),
        countryCode: json['country_code'] as String,
        governorateCode: json['governorate_code'] as String,
        areaCode: json['area_code'] as String?,
        price: json['price'] as num,
        areaSqm: json['area_sqm'] as num?,
        bedrooms: (json['bedrooms'] as num?)?.toInt(),
        bathrooms: (json['bathrooms'] as num?)?.toInt(),
        furnished: json['furnished'] as bool? ?? false,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        images: [
          for (final image in (json['images'] as List? ?? const []))
            PropertyImage.fromJson(image as Map<String, dynamic>),
        ],
        videoUrl: json['video_url'] as String?,
        owner: PropertyOwner.fromJson(json['owner'] as Map<String, dynamic>),
        favorite: json['favorite'] as bool? ?? false,
        mine: json['mine'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        landKind: LandKind.fromApi(json['land_kind'] as String?),
        areaQirats: json['area_qirats'] as num?,
        areaSahm: (json['area_sahm'] as num?)?.toInt(),
        northSideM: json['north_side_m'] as num?,
        southSideM: json['south_side_m'] as num?,
        eastSideM: json['east_side_m'] as num?,
        westSideM: json['west_side_m'] as num?,
        streetWidthM: json['street_width_m'] as num?,
        buildingPermit: json['building_permit'] as bool?,
        boundaryNorth: json['boundary_north'] as String?,
        boundarySouth: json['boundary_south'] as String?,
        boundaryEast: json['boundary_east'] as String?,
        boundaryWest: json['boundary_west'] as String?,
        negotiable: json['negotiable'] as bool? ?? false,
        contact: json['contact'] == null
            ? null
            : SellerContact.fromJson(json['contact'] as Map<String, dynamic>),
      );

  final String id;
  final String titleEn;
  final String titleAr;
  final String descriptionEn;
  final String descriptionAr;
  final PropertyType propertyType;
  final ListingType listingType;
  final String countryCode;
  final String governorateCode;
  final String? areaCode;
  final num price;
  final num? areaSqm;
  final int? bedrooms;
  final int? bathrooms;
  final bool furnished;
  final double? latitude;
  final double? longitude;
  final List<PropertyImage> images;
  final String? videoUrl;
  final PropertyOwner owner;
  final bool favorite;
  final bool mine;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LandKind? landKind;
  final num? areaQirats;
  final int? areaSahm;
  final num? northSideM;
  final num? southSideM;
  final num? eastSideM;
  final num? westSideM;
  final num? streetWidthM;
  final bool? buildingPermit;
  final String? boundaryNorth;
  final String? boundarySouth;
  final String? boundaryEast;
  final String? boundaryWest;
  final bool negotiable;
  final SellerContact? contact;
}

class PropertyDraft {
  const PropertyDraft({
    required this.titleEn,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.propertyType,
    required this.listingType,
    required this.countryCode,
    required this.governorateCode,
    required this.price,
    required this.furnished,
    this.areaCode,
    this.areaSqm,
    this.bedrooms,
    this.bathrooms,
    this.landKind,
    this.areaQirats,
    this.areaSahm,
    this.northSideM,
    this.southSideM,
    this.eastSideM,
    this.westSideM,
    this.streetWidthM,
    this.buildingPermit,
    this.boundaryNorth,
    this.boundarySouth,
    this.boundaryEast,
    this.boundaryWest,
    this.negotiable = false,
  });

  factory PropertyDraft.fromDetail(PropertyDetail detail) => PropertyDraft(
        titleEn: detail.titleEn,
        titleAr: detail.titleAr,
        descriptionEn: detail.descriptionEn,
        descriptionAr: detail.descriptionAr,
        propertyType: detail.propertyType,
        listingType: detail.listingType,
        countryCode: detail.countryCode,
        governorateCode: detail.governorateCode,
        areaCode: detail.areaCode,
        price: detail.price,
        areaSqm: detail.areaSqm,
        bedrooms: detail.bedrooms,
        bathrooms: detail.bathrooms,
        furnished: detail.furnished,
        landKind: detail.landKind,
        areaQirats: detail.areaQirats,
        areaSahm: detail.areaSahm,
        northSideM: detail.northSideM,
        southSideM: detail.southSideM,
        eastSideM: detail.eastSideM,
        westSideM: detail.westSideM,
        streetWidthM: detail.streetWidthM,
        buildingPermit: detail.buildingPermit,
        boundaryNorth: detail.boundaryNorth,
        boundarySouth: detail.boundarySouth,
        boundaryEast: detail.boundaryEast,
        boundaryWest: detail.boundaryWest,
        negotiable: detail.negotiable,
      );

  final String titleEn;
  final String titleAr;
  final String descriptionEn;
  final String descriptionAr;
  final PropertyType propertyType;
  final ListingType listingType;
  final String countryCode;
  final String governorateCode;
  final String? areaCode;
  final num price;
  final num? areaSqm;
  final int? bedrooms;
  final int? bathrooms;
  final bool furnished;
  final LandKind? landKind;
  final num? areaQirats;
  final int? areaSahm;
  final num? northSideM;
  final num? southSideM;
  final num? eastSideM;
  final num? westSideM;
  final num? streetWidthM;
  final bool? buildingPermit;
  final String? boundaryNorth;
  final String? boundarySouth;
  final String? boundaryEast;
  final String? boundaryWest;
  final bool negotiable;

  Map<String, dynamic> toJson() => {
        'title_en': titleEn,
        'title_ar': titleAr,
        'description_en': descriptionEn,
        'description_ar': descriptionAr,
        'property_type': propertyType.apiValue,
        'listing_type': listingType.apiValue,
        'country_code': countryCode,
        'governorate_code': governorateCode,
        'area_code': areaCode,
        'price': price,
        'area_sqm': areaSqm,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'furnished': furnished,
        'land_kind': landKind?.apiValue,
        'area_qirats': areaQirats,
        'area_sahm': areaSahm,
        'north_side_m': northSideM,
        'south_side_m': southSideM,
        'east_side_m': eastSideM,
        'west_side_m': westSideM,
        'street_width_m': streetWidthM,
        'building_permit': buildingPermit,
        'boundary_north': boundaryNorth,
        'boundary_south': boundarySouth,
        'boundary_east': boundaryEast,
        'boundary_west': boundaryWest,
        'negotiable': negotiable,
      };
}

class Conversation {
  const Conversation({
    required this.id,
    required this.propertyId,
    required this.propertyTitleEn,
    required this.propertyTitleAr,
    required this.otherPartyId,
    required this.otherPartyName,
    required this.ownerView,
    required this.lastMessage,
    required this.unreadCount,
    this.coverImage,
    this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        propertyId: json['property_id'] as String,
        propertyTitleEn: json['property_title_en'] as String,
        propertyTitleAr: json['property_title_ar'] as String,
        coverImage: json['cover_image'] as String?,
        otherPartyId: json['other_party_id'] as String,
        otherPartyName: json['other_party_name'] as String,
        ownerView: json['owner_view'] as bool? ?? false,
        lastMessage: json['last_message'] as String? ?? '',
        lastMessageAt: json['last_message_at'] == null
            ? null
            : DateTime.parse(json['last_message_at'] as String),
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String propertyId;
  final String propertyTitleEn;
  final String propertyTitleAr;
  final String? coverImage;
  final String otherPartyId;
  final String otherPartyName;
  final bool ownerView;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
}

class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.read,
    required this.mine,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        senderId: json['sender_id'] as String,
        senderName: json['sender_name'] as String,
        body: json['body'] as String,
        read: json['read'] as bool? ?? false,
        mine: json['mine'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  final String id;
  final String senderId;
  final String senderName;
  final String body;
  final bool read;
  final bool mine;
  final DateTime createdAt;
}

class PageResult<T> {
  const PageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
  });

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) parseItem,
  ) =>
      PageResult(
        items: [
          for (final item in (json['items'] as List? ?? const []))
            parseItem(item as Map<String, dynamic>),
        ],
        page: (json['page'] as num?)?.toInt() ?? 0,
        size: (json['size'] as num?)?.toInt() ?? 0,
        totalElements: (json['total_elements'] as num?)?.toInt() ?? 0,
        totalPages: (json['total_pages'] as num?)?.toInt() ?? 0,
        hasNext: json['has_next'] as bool? ?? false,
      );

  final List<T> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
}
