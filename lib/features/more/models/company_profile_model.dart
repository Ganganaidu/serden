import 'package:equatable/equatable.dart';

class ProPhoto extends Equatable {
  final String? fileName;
  final String? blobPath;
  final String? url;

  const ProPhoto({this.fileName, this.blobPath, this.url});

  factory ProPhoto.fromJson(Map<String, dynamic> json) => ProPhoto(
        fileName: json['fileName'] as String?,
        blobPath: json['blobPath'] as String?,
        url: json['url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (fileName != null) 'fileName': fileName,
        if (blobPath != null) 'blobPath': blobPath,
        if (url != null) 'url': url,
      };

  @override
  List<Object?> get props => [fileName, blobPath, url];
}

class CompanyProfile extends Equatable {
  final int? proId;
  final String? proName;
  final String? aboutCompany;
  final String? streetAddress;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? phone;
  final String? email;
  final String? website;
  final String? licenseNumber;
  final String? insuranceNumber;
  final String? yearFounded;
  final String? businessHours;
  final String? areaServed;
  final List<String> serviceCategories;
  final List<String> highlights;
  final String? facebookUrl;
  final String? instagramUrl;
  final String? linkedInUrl;
  final String? xUrl;
  final String? youtubeUrl;
  final bool listedInDirectory;

  /// Bare filename returned by the API (e.g. "logo.jpg"). Build the full URL
  /// using AppConstants.proLogoUrl(proLogo!) before displaying.
  final String? proLogo;

  /// Project portfolio photos returned by the API.
  final List<ProPhoto> projectPhotos;

  const CompanyProfile({
    this.proId,
    this.proName,
    this.aboutCompany,
    this.streetAddress,
    this.city,
    this.state,
    this.zipCode,
    this.phone,
    this.email,
    this.website,
    this.licenseNumber,
    this.insuranceNumber,
    this.yearFounded,
    this.businessHours,
    this.areaServed,
    this.serviceCategories = const [],
    this.highlights = const [],
    this.facebookUrl,
    this.instagramUrl,
    this.linkedInUrl,
    this.xUrl,
    this.youtubeUrl,
    this.listedInDirectory = true,
    this.proLogo,
    this.projectPhotos = const [],
  });

  factory CompanyProfile.fromJson(Map<String, dynamic> json) => CompanyProfile(
        proId: json['proId'] as int?,
        proName: json['proName'] as String?,
        aboutCompany: json['aboutCompany'] as String?,
        streetAddress: json['streetAddress'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        zipCode: json['zipCode'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        website: json['website'] as String?,
        licenseNumber: json['licenseNumber'] as String?,
        insuranceNumber: json['insuranceNumber'] as String?,
        yearFounded: json['yearFounded']?.toString(),
        businessHours: json['businessHours'] as String?,
        areaServed: json['areaServed'] as String?,
        serviceCategories: (json['serviceCategories'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        highlights: (json['highlights'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        facebookUrl: json['facebookUrl'] as String?,
        instagramUrl: json['instagramUrl'] as String?,
        linkedInUrl: json['linkedInUrl'] as String?,
        xUrl: json['xUrl'] as String?,
        youtubeUrl: json['youtubeUrl'] as String?,
        listedInDirectory: json['listedInDirectory'] as bool? ?? true,
        proLogo: json['proLogo'] as String?,
        projectPhotos: (json['projectPhotos'] as List<dynamic>?)
                ?.map((e) => ProPhoto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        if (proId != null) 'proId': proId,
        'proName': proName ?? '',
        'aboutCompany': aboutCompany ?? '',
        'streetAddress': streetAddress ?? '',
        'city': city ?? '',
        'state': state ?? '',
        'zipCode': zipCode ?? '',
        'phone': phone ?? '',
        'email': email ?? '',
        'website': website ?? '',
        'licenseNumber': licenseNumber ?? '',
        'insuranceNumber': insuranceNumber ?? '',
        'yearFounded': yearFounded != null && yearFounded!.isNotEmpty
            ? int.tryParse(yearFounded!)
            : null,
        'businessHours': businessHours ?? '',
        'areaServed': areaServed ?? '',
        'serviceCategories': serviceCategories,
        'highlights': highlights,
        'facebookUrl': facebookUrl ?? '',
        'instagramUrl': instagramUrl ?? '',
        'linkedInUrl': linkedInUrl ?? '',
        'xUrl': xUrl ?? '',
        'youtubeUrl': youtubeUrl ?? '',
        'listedInDirectory': listedInDirectory,
        if (proLogo != null) 'proLogo': proLogo,
      };

  CompanyProfile copyWith({
    int? proId,
    String? proName,
    String? aboutCompany,
    String? streetAddress,
    String? city,
    String? state,
    String? zipCode,
    String? phone,
    String? email,
    String? website,
    String? licenseNumber,
    String? insuranceNumber,
    String? yearFounded,
    String? businessHours,
    String? areaServed,
    List<String>? serviceCategories,
    List<String>? highlights,
    String? facebookUrl,
    String? instagramUrl,
    String? linkedInUrl,
    String? xUrl,
    String? youtubeUrl,
    bool? listedInDirectory,
    String? proLogo,
    List<ProPhoto>? projectPhotos,
  }) =>
      CompanyProfile(
        proId: proId ?? this.proId,
        proName: proName ?? this.proName,
        aboutCompany: aboutCompany ?? this.aboutCompany,
        streetAddress: streetAddress ?? this.streetAddress,
        city: city ?? this.city,
        state: state ?? this.state,
        zipCode: zipCode ?? this.zipCode,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        website: website ?? this.website,
        licenseNumber: licenseNumber ?? this.licenseNumber,
        insuranceNumber: insuranceNumber ?? this.insuranceNumber,
        yearFounded: yearFounded ?? this.yearFounded,
        businessHours: businessHours ?? this.businessHours,
        areaServed: areaServed ?? this.areaServed,
        serviceCategories: serviceCategories ?? this.serviceCategories,
        highlights: highlights ?? this.highlights,
        facebookUrl: facebookUrl ?? this.facebookUrl,
        instagramUrl: instagramUrl ?? this.instagramUrl,
        linkedInUrl: linkedInUrl ?? this.linkedInUrl,
        xUrl: xUrl ?? this.xUrl,
        youtubeUrl: youtubeUrl ?? this.youtubeUrl,
        listedInDirectory: listedInDirectory ?? this.listedInDirectory,
        proLogo: proLogo ?? this.proLogo,
        projectPhotos: projectPhotos ?? this.projectPhotos,
      );

  @override
  List<Object?> get props => [
        proId,
        proName,
        aboutCompany,
        streetAddress,
        city,
        state,
        zipCode,
        phone,
        email,
        website,
        licenseNumber,
        insuranceNumber,
        yearFounded,
        businessHours,
        areaServed,
        serviceCategories,
        highlights,
        facebookUrl,
        instagramUrl,
        linkedInUrl,
        xUrl,
        youtubeUrl,
        listedInDirectory,
        proLogo,
        projectPhotos,
      ];
}
