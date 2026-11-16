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
        nameEn: json['nameEn'] as String,
        nameAr: json['nameAr'] as String,
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
        nameEn: json['nameEn'] as String,
        nameAr: json['nameAr'] as String,
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
        nameEn: json['nameEn'] as String,
        nameAr: json['nameAr'] as String,
        currencyCode: json['currencyCode'] as String,
        currencySymbolEn: json['currencySymbolEn'] as String,
        currencySymbolAr: json['currencySymbolAr'] as String,
        taglineEn: json['taglineEn'] as String,
        taglineAr: json['taglineAr'] as String,
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
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        role: UserRole.fromApi(json['role'] as String),
      );

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final UserRole role;

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
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
        verificationRequired: json['verificationRequired'] as bool? ?? false,
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
      PropertyOwner(id: json['id'] as String, fullName: json['fullName'] as String);

  final String id;
  final String fullName;
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
    this.negotiable = false,
  });

  factory PropertySummary.fromJson(Map<String, dynamic> json) => PropertySummary(
        id: json['id'] as String,
        titleEn: json['titleEn'] as String,
        titleAr: json['titleAr'] as String,
        propertyType: PropertyType.fromApi(json['propertyType'] as String),
        listingType: ListingType.fromApi(json['listingType'] as String),
        countryCode: json['countryCode'] as String,
        governorateCode: json['governorateCode'] as String,
        areaCode: json['areaCode'] as String?,
        price: json['price'] as num,
        areaSqm: json['areaSqm'] as num?,
        bedrooms: (json['bedrooms'] as num?)?.toInt(),
        bathrooms: (json['bathrooms'] as num?)?.toInt(),
        furnished: json['furnished'] as bool? ?? false,
        coverImage: json['coverImage'] as String?,
        favorite: json['favorite'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        landKind: LandKind.fromApi(json['landKind'] as String?),
        areaQirats: json['areaQirats'] as num?,
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
    this.frontageM,
    this.depthM,
    this.streetWidthM,
    this.buildingPermit,
    this.boundaryNorth,
    this.boundarySouth,
    this.boundaryEast,
    this.boundaryWest,
    this.negotiable = false,
  });

  factory PropertyDetail.fromJson(Map<String, dynamic> json) => PropertyDetail(
        id: json['id'] as String,
        titleEn: json['titleEn'] as String,
        titleAr: json['titleAr'] as String,
        descriptionEn: json['descriptionEn'] as String,
        descriptionAr: json['descriptionAr'] as String,
        propertyType: PropertyType.fromApi(json['propertyType'] as String),
        listingType: ListingType.fromApi(json['listingType'] as String),
        countryCode: json['countryCode'] as String,
        governorateCode: json['governorateCode'] as String,
        areaCode: json['areaCode'] as String?,
        price: json['price'] as num,
        areaSqm: json['areaSqm'] as num?,
        bedrooms: (json['bedrooms'] as num?)?.toInt(),
        bathrooms: (json['bathrooms'] as num?)?.toInt(),
        furnished: json['furnished'] as bool? ?? false,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        images: [
          for (final image in (json['images'] as List? ?? const []))
            PropertyImage.fromJson(image as Map<String, dynamic>),
        ],
        videoUrl: json['videoUrl'] as String?,
        owner: PropertyOwner.fromJson(json['owner'] as Map<String, dynamic>),
        favorite: json['favorite'] as bool? ?? false,
        mine: json['mine'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        landKind: LandKind.fromApi(json['landKind'] as String?),
        areaQirats: json['areaQirats'] as num?,
        frontageM: json['frontageM'] as num?,
        depthM: json['depthM'] as num?,
        streetWidthM: json['streetWidthM'] as num?,
        buildingPermit: json['buildingPermit'] as bool?,
        boundaryNorth: json['boundaryNorth'] as String?,
        boundarySouth: json['boundarySouth'] as String?,
        boundaryEast: json['boundaryEast'] as String?,
        boundaryWest: json['boundaryWest'] as String?,
        negotiable: json['negotiable'] as bool? ?? false,
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
  final num? frontageM;
  final num? depthM;
  final num? streetWidthM;
  final bool? buildingPermit;
  final String? boundaryNorth;
  final String? boundarySouth;
  final String? boundaryEast;
  final String? boundaryWest;
  final bool negotiable;
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
    this.frontageM,
    this.depthM,
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
        frontageM: detail.frontageM,
        depthM: detail.depthM,
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
  final num? frontageM;
  final num? depthM;
  final num? streetWidthM;
  final bool? buildingPermit;
  final String? boundaryNorth;
  final String? boundarySouth;
  final String? boundaryEast;
  final String? boundaryWest;
  final bool negotiable;

  Map<String, dynamic> toJson() => {
        'titleEn': titleEn,
        'titleAr': titleAr,
        'descriptionEn': descriptionEn,
        'descriptionAr': descriptionAr,
        'propertyType': propertyType.apiValue,
        'listingType': listingType.apiValue,
        'countryCode': countryCode,
        'governorateCode': governorateCode,
        'areaCode': areaCode,
        'price': price,
        'areaSqm': areaSqm,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'furnished': furnished,
        'landKind': landKind?.apiValue,
        'areaQirats': areaQirats,
        'frontageM': frontageM,
        'depthM': depthM,
        'streetWidthM': streetWidthM,
        'buildingPermit': buildingPermit,
        'boundaryNorth': boundaryNorth,
        'boundarySouth': boundarySouth,
        'boundaryEast': boundaryEast,
        'boundaryWest': boundaryWest,
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
        propertyId: json['propertyId'] as String,
        propertyTitleEn: json['propertyTitleEn'] as String,
        propertyTitleAr: json['propertyTitleAr'] as String,
        coverImage: json['coverImage'] as String?,
        otherPartyId: json['otherPartyId'] as String,
        otherPartyName: json['otherPartyName'] as String,
        ownerView: json['ownerView'] as bool? ?? false,
        lastMessage: json['lastMessage'] as String? ?? '',
        lastMessageAt: json['lastMessageAt'] == null
            ? null
            : DateTime.parse(json['lastMessageAt'] as String),
        unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
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
        senderId: json['senderId'] as String,
        senderName: json['senderName'] as String,
        body: json['body'] as String,
        read: json['read'] as bool? ?? false,
        mine: json['mine'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
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
        totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
        totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
        hasNext: json['hasNext'] as bool? ?? false,
      );

  final List<T> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
}
