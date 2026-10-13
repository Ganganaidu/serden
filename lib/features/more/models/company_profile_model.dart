import 'package:equatable/equatable.dart';

int? _asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
double? _asDouble(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}');

/// A project photo (`ProProjectPhotoDto`). The file lives in blob storage under
/// `pro-images/{proId}/ProjectsImages/{fileName}`.
class ProPhoto extends Equatable {
  final int photoId;
  final int proId;
  final String fileName;
  final String? caption;

  const ProPhoto({
    required this.photoId,
    required this.proId,
    required this.fileName,
    this.caption,
  });

  factory ProPhoto.fromJson(Map<String, dynamic> json) => ProPhoto(
    photoId: _asInt(json['photoId']) ?? 0,
    proId: _asInt(json['proId']) ?? 0,
    fileName: json['fileName'] as String? ?? '',
    caption: json['caption'] as String?,
  );

  @override
  List<Object?> get props => [photoId, proId, fileName, caption];
}

/// A selectable category or highlight from the admin-managed lists.
class ProfileOption extends Equatable {
  final int id;
  final String name;

  /// Category group, or the highlight's description.
  final String? subtitle;

  const ProfileOption({required this.id, required this.name, this.subtitle});

  @override
  List<Object?> get props => [id, name, subtitle];
}

/// One area served. Standardized areas carry a [locationId]; older free-text
/// entries have none and are kept as they are.
class ServiceArea extends Equatable {
  final int id;
  final String areaName;
  final int? locationId;
  final String? typeLabel;

  const ServiceArea({
    this.id = 0,
    required this.areaName,
    this.locationId,
    this.typeLabel,
  });

  /// From a `ServiceAreaDto` (`/pros/{id}/service-areas`).
  factory ServiceArea.fromAreaJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>?;
    return ServiceArea(
      id: _asInt(json['id']) ?? 0,
      areaName: json['areaName'] as String? ?? '',
      locationId: location == null ? null : _asInt(location['id']),
      typeLabel: location?['typeLabel'] as String?,
    );
  }

  /// From a `LocationDto` (`/Locations/search`).
  factory ServiceArea.fromLocationJson(Map<String, dynamic> json) =>
      ServiceArea(
        areaName: json['label'] as String? ?? json['name'] as String? ?? '',
        locationId: _asInt(json['id']),
        typeLabel: json['typeLabel'] as String?,
      );

  @override
  List<Object?> get props => [id, areaName, locationId, typeLabel];
}

/// Lists the form picks from, loaded alongside the profile.
class ProfileCatalogs extends Equatable {
  final List<ProfileOption> categories;
  final List<ProfileOption> highlights;

  /// State code → state name (e.g. `TX` → `Texas`).
  final Map<String, String> states;

  const ProfileCatalogs({
    this.categories = const [],
    this.highlights = const [],
    this.states = const {},
  });

  @override
  List<Object?> get props => [categories, highlights, states];
}

/// A company listing. The core fields mirror the API's `ProViewModel`; the
/// category, highlight, area and photo lists come from their own endpoints.
class CompanyProfile extends Equatable {
  /// 0 / null means the company has no listing yet (saving creates it).
  final int? proId;
  final int? userId;
  final String? serdenProId;
  final String? slug;
  final String? publicId;
  final bool isActive;

  final String proName;
  final String aboutCompany;
  final String streetAddress;
  final String? addressLine2;
  final String city;
  final String state;
  final String zipCode;
  final double? latitude;
  final double? longitude;
  final String phone;
  final String email;
  final String website;
  final String licenseNumber;
  final String insuranceNumber;
  final int? yearFounded;
  final String businessHours;
  final String facebookUrl;
  final String instagramUrl;
  final String linkedInUrl;
  final String twitterUrl;
  final String youTubeUrl;
  final bool isInDirectory;

  /// Bare blob filename (e.g. `logo-1a2b3.png`).
  final String? proLogo;

  final List<int> categoryIds;
  final List<int> serviceTagIds;
  final List<ServiceArea> serviceAreas;

  /// False until the API's location script has run: areas are then free text.
  final bool areasReady;
  final List<ProPhoto> projectPhotos;

  const CompanyProfile({
    this.proId,
    this.userId,
    this.serdenProId,
    this.slug,
    this.publicId,
    this.isActive = true,
    this.proName = '',
    this.aboutCompany = '',
    this.streetAddress = '',
    this.addressLine2,
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.latitude,
    this.longitude,
    this.phone = '',
    this.email = '',
    this.website = '',
    this.licenseNumber = '',
    this.insuranceNumber = '',
    this.yearFounded,
    this.businessHours = '',
    this.facebookUrl = '',
    this.instagramUrl = '',
    this.linkedInUrl = '',
    this.twitterUrl = '',
    this.youTubeUrl = '',
    this.isInDirectory = true,
    this.proLogo,
    this.categoryIds = const [],
    this.serviceTagIds = const [],
    this.serviceAreas = const [],
    this.areasReady = false,
    this.projectPhotos = const [],
  });

  bool get isNew => proId == null || proId == 0;

  factory CompanyProfile.fromJson(Map<String, dynamic> json) => CompanyProfile(
    proId: _asInt(json['proId']),
    userId: _asInt(json['userId']),
    serdenProId: json['serdenProId'] as String?,
    slug: json['slug'] as String?,
    publicId: json['publicId'] as String?,
    isActive: json['isActive'] as bool? ?? true,
    proName: json['proName'] as String? ?? '',
    aboutCompany: json['aboutCompany'] as String? ?? '',
    streetAddress: json['streetAddress'] as String? ?? '',
    addressLine2: json['addressLine2'] as String?,
    city: json['city'] as String? ?? '',
    state: json['state'] as String? ?? '',
    zipCode: json['zipCode'] as String? ?? '',
    latitude: _asDouble(json['latitude']),
    longitude: _asDouble(json['longitude']),
    phone: json['phone'] as String? ?? '',
    email: json['email'] as String? ?? '',
    website: json['website'] as String? ?? '',
    licenseNumber: json['licenseNumber'] as String? ?? '',
    insuranceNumber: json['insuranceNumber'] as String? ?? '',
    yearFounded: _asInt(json['yearFounded']),
    businessHours: json['businessHours'] as String? ?? '',
    facebookUrl: json['facebookUrl'] as String? ?? '',
    instagramUrl: json['instagramUrl'] as String? ?? '',
    linkedInUrl: json['linkedInUrl'] as String? ?? '',
    twitterUrl: json['twitterUrl'] as String? ?? '',
    youTubeUrl:
        json['youTubeUrl'] as String? ?? json['youtubeUrl'] as String? ?? '',
    isInDirectory: json['isInDirectory'] as bool? ?? true,
    proLogo: json['proLogo'] as String?,
  );

  /// Body for `POST /Pros` and `PUT /Pros/{id}` (the API's `ProViewModel`).
  /// The update overwrites every column, so values the form doesn't edit
  /// (logo, coordinates, address line 2) are sent back unchanged.
  Map<String, dynamic> toJson() => {
    'proId': proId ?? 0,
    if (userId != null) 'userId': userId,
    if (serdenProId != null) 'serdenProId': serdenProId,
    'slug': slug,
    'proName': proName,
    'proLogo': proLogo,
    'phone': phone,
    'website': website,
    'aboutCompany': aboutCompany,
    'streetAddress': streetAddress,
    'addressLine2': addressLine2,
    'city': city,
    'state': state,
    'zipCode': zipCode,
    'latitude': latitude,
    'longitude': longitude,
    'isActive': isActive,
    'publicId': publicId,
    'licenseNumber': licenseNumber,
    'insuranceNumber': insuranceNumber,
    'yearFounded': yearFounded,
    'facebookUrl': facebookUrl,
    'instagramUrl': instagramUrl,
    'linkedInUrl': linkedInUrl,
    'twitterUrl': twitterUrl,
    'youTubeUrl': youTubeUrl,
    'businessHours': businessHours,
    'email': email,
    'isInDirectory': isInDirectory,
  };

  CompanyProfile copyWith({
    int? proId,
    String? proLogo,
    bool clearLogo = false,
    List<int>? categoryIds,
    List<int>? serviceTagIds,
    List<ServiceArea>? serviceAreas,
    bool? areasReady,
    List<ProPhoto>? projectPhotos,
  }) => CompanyProfile(
    proId: proId ?? this.proId,
    userId: userId,
    serdenProId: serdenProId,
    slug: slug,
    publicId: publicId,
    isActive: isActive,
    proName: proName,
    aboutCompany: aboutCompany,
    streetAddress: streetAddress,
    addressLine2: addressLine2,
    city: city,
    state: state,
    zipCode: zipCode,
    latitude: latitude,
    longitude: longitude,
    phone: phone,
    email: email,
    website: website,
    licenseNumber: licenseNumber,
    insuranceNumber: insuranceNumber,
    yearFounded: yearFounded,
    businessHours: businessHours,
    facebookUrl: facebookUrl,
    instagramUrl: instagramUrl,
    linkedInUrl: linkedInUrl,
    twitterUrl: twitterUrl,
    youTubeUrl: youTubeUrl,
    isInDirectory: isInDirectory,
    proLogo: clearLogo ? null : (proLogo ?? this.proLogo),
    categoryIds: categoryIds ?? this.categoryIds,
    serviceTagIds: serviceTagIds ?? this.serviceTagIds,
    serviceAreas: serviceAreas ?? this.serviceAreas,
    areasReady: areasReady ?? this.areasReady,
    projectPhotos: projectPhotos ?? this.projectPhotos,
  );

  @override
  List<Object?> get props => [
    proId,
    userId,
    serdenProId,
    slug,
    publicId,
    isActive,
    proName,
    aboutCompany,
    streetAddress,
    addressLine2,
    city,
    state,
    zipCode,
    latitude,
    longitude,
    phone,
    email,
    website,
    licenseNumber,
    insuranceNumber,
    yearFounded,
    businessHours,
    facebookUrl,
    instagramUrl,
    linkedInUrl,
    twitterUrl,
    youTubeUrl,
    isInDirectory,
    proLogo,
    categoryIds,
    serviceTagIds,
    serviceAreas,
    areasReady,
    projectPhotos,
  ];
}
