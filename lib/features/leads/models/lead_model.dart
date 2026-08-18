import 'package:equatable/equatable.dart';

enum LeadStatus { newLead, contacted, quoted, won, lost }

extension LeadStatusX on LeadStatus {
  String get apiValue => switch (this) {
        LeadStatus.newLead => 'new',
        LeadStatus.contacted => 'contacted',
        LeadStatus.quoted => 'quoted',
        LeadStatus.won => 'won',
        LeadStatus.lost => 'lost',
      };

  static LeadStatus fromApi(String? s) => switch (s?.toLowerCase()) {
        'new' => LeadStatus.newLead,
        'contacted' => LeadStatus.contacted,
        'quoted' => LeadStatus.quoted,
        'won' => LeadStatus.won,
        'lost' => LeadStatus.lost,
        _ => LeadStatus.newLead,
      };
}

class LeadNote extends Equatable {
  final int leadNoteId;
  final int requestId;
  final String? noteText;
  final DateTime? createdDateUtc;

  const LeadNote({
    required this.leadNoteId,
    required this.requestId,
    this.noteText,
    this.createdDateUtc,
  });

  factory LeadNote.fromJson(Map<String, dynamic> json) => LeadNote(
        leadNoteId: json['leadNoteId'] as int? ?? 0,
        requestId: json['requestId'] as int? ?? 0,
        noteText: json['noteText'] as String?,
        createdDateUtc: json['createdDateUtc'] == null
            ? null
            : DateTime.tryParse(json['createdDateUtc'] as String),
      );

  @override
  List<Object?> get props =>
      [leadNoteId, requestId, noteText, createdDateUtc];
}

class LeadPhotoDto extends Equatable {
  final String? fileName;
  final String? blobPath;
  final String? url;

  const LeadPhotoDto({this.fileName, this.blobPath, this.url});

  factory LeadPhotoDto.fromJson(Map<String, dynamic> json) => LeadPhotoDto(
        fileName: json['fileName'] as String?,
        blobPath: json['blobPath'] as String?,
        url: json['url'] as String?,
      );

  @override
  List<Object?> get props => [fileName, blobPath, url];
}

class LeadHistory extends Equatable {
  final int leadHistoryId;
  final int requestId;
  final String? eventText;
  final DateTime? createdDateUtc;

  const LeadHistory({
    required this.leadHistoryId,
    required this.requestId,
    this.eventText,
    this.createdDateUtc,
  });

  factory LeadHistory.fromJson(Map<String, dynamic> json) => LeadHistory(
        leadHistoryId: json['leadHistoryId'] as int? ?? 0,
        requestId: json['requestId'] as int? ?? 0,
        eventText: json['eventText'] as String?,
        createdDateUtc: json['createdDateUtc'] == null
            ? null
            : DateTime.tryParse(json['createdDateUtc'] as String),
      );

  @override
  List<Object?> get props =>
      [leadHistoryId, requestId, eventText, createdDateUtc];
}

class Lead extends Equatable {
  final int requestId;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? streetAddress;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? requestText;
  final int? proCategoryId;
  final String? categoryName;
  final int proId;
  final String publicId;
  final DateTime createdDate;
  final LeadStatus status;
  final String? notes;
  final double? leadCost;
  final String? leadSource;
  final List<LeadNote> leadNotes;
  final List<LeadHistory> leadHistories;

  const Lead({
    required this.requestId,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.streetAddress,
    this.addressLine2,
    this.city,
    this.state,
    this.zipCode,
    this.requestText,
    this.proCategoryId,
    this.categoryName,
    required this.proId,
    required this.publicId,
    required this.createdDate,
    required this.status,
    this.notes,
    this.leadCost,
    this.leadSource,
    this.leadNotes = const [],
    this.leadHistories = const [],
  });

  String get fullName {
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) parts.add(firstName!);
    if (lastName != null && lastName!.isNotEmpty) parts.add(lastName!);
    return parts.isEmpty ? 'Unknown' : parts.join(' ');
  }

  String get place {
    final parts = <String>[];
    if (city != null && city!.isNotEmpty) {
      final cs = [city!, if (state != null && state!.isNotEmpty) state!].join(', ');
      parts.add('$cs${zipCode != null && zipCode!.isNotEmpty ? ' ${zipCode!}' : ''}');
    }
    return parts.join(' ');
  }

  bool get isNew => status == LeadStatus.newLead;
  bool get isFresh => DateTime.now().difference(createdDate).inHours < 48;

  String get timeDisplay {
    final diff = DateTime.now().difference(createdDate);
    if (diff.inHours < 1) return 'Just now';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[createdDate.month - 1]} ${createdDate.day}';
  }

  Lead copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? streetAddress,
    String? addressLine2,
    String? city,
    String? state,
    String? zipCode,
    String? requestText,
    int? proCategoryId,
    String? categoryName,
    LeadStatus? status,
    String? notes,
    double? leadCost,
    String? leadSource,
    List<LeadNote>? leadNotes,
    List<LeadHistory>? leadHistories,
  }) =>
      Lead(
        requestId: requestId,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        streetAddress: streetAddress ?? this.streetAddress,
        addressLine2: addressLine2 ?? this.addressLine2,
        city: city ?? this.city,
        state: state ?? this.state,
        zipCode: zipCode ?? this.zipCode,
        requestText: requestText ?? this.requestText,
        proCategoryId: proCategoryId ?? this.proCategoryId,
        categoryName: categoryName ?? this.categoryName,
        proId: proId,
        publicId: publicId,
        createdDate: createdDate,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        leadCost: leadCost ?? this.leadCost,
        leadSource: leadSource ?? this.leadSource,
        leadNotes: leadNotes ?? this.leadNotes,
        leadHistories: leadHistories ?? this.leadHistories,
      );

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
        requestId: json['requestId'] as int? ?? 0,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        streetAddress: json['streetAddress'] as String?,
        addressLine2: json['addressLine2'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        zipCode: json['zipCode'] as String?,
        requestText: json['requestText'] as String?,
        proCategoryId: json['proCategoryId'] as int?,
        categoryName: json['categoryName'] as String?,
        proId: json['proId'] as int? ?? 0,
        publicId: json['publicId'] as String? ?? '',
        createdDate: json['createdDate'] == null
            ? DateTime.now()
            : DateTime.tryParse(json['createdDate'] as String) ?? DateTime.now(),
        status: LeadStatusX.fromApi(json['status'] as String?),
        notes: json['notes'] as String?,
        leadCost: (json['leadCost'] as num?)?.toDouble(),
        leadSource: json['leadSource'] as String?,
        leadNotes: (json['leadNotes'] as List<dynamic>?)
                ?.map((e) => LeadNote.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        leadHistories: (json['leadHistories'] as List<dynamic>?)
                ?.map((e) => LeadHistory.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (streetAddress != null) 'streetAddress': streetAddress,
        if (addressLine2 != null) 'addressLine2': addressLine2,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (zipCode != null) 'zipCode': zipCode,
        if (requestText != null) 'requestText': requestText,
        if (proCategoryId != null) 'proCategoryId': proCategoryId,
        if (categoryName != null) 'categoryName': categoryName,
        'proId': proId,
        'publicId': publicId,
        'createdDate': createdDate.toIso8601String(),
        'status': status.apiValue,
        if (notes != null) 'notes': notes,
        if (leadCost != null) 'leadCost': leadCost,
        if (leadSource != null) 'leadSource': leadSource,
      };

  @override
  List<Object?> get props => [
        requestId,
        firstName,
        lastName,
        phone,
        email,
        streetAddress,
        city,
        state,
        zipCode,
        requestText,
        status,
        notes,
        publicId,
        leadNotes,
      ];
}

final List<Lead> mockLeads = [
  Lead(
    requestId: 1,
    firstName: 'Ca',
    lastName: 'Tilton',
    phone: '(360) 555-0111',
    email: 'ca.tilton@email.com',
    requestText: 'Remodel a kitchen',
    city: 'Vancouver',
    state: 'WA',
    zipCode: '98685',
    proId: 1,
    publicId: 'mock-1',
    createdDate: DateTime.now().subtract(const Duration(hours: 2)),
    status: LeadStatus.newLead,
  ),
  Lead(
    requestId: 2,
    firstName: 'David',
    lastName: 'Tremain',
    phone: '(360) 555-0122',
    email: 'david.tremain@email.com',
    requestText: 'Remodel a bathroom',
    city: 'Vancouver',
    state: 'WA',
    zipCode: '98660',
    proId: 1,
    publicId: 'mock-2',
    createdDate: DateTime.now().subtract(const Duration(days: 1)),
    status: LeadStatus.newLead,
  ),
  Lead(
    requestId: 3,
    firstName: 'Tommie',
    lastName: 'Joiner',
    phone: '(360) 555-0133',
    requestText: 'Remodel a kitchen',
    city: 'Vancouver',
    state: 'WA',
    zipCode: '98683',
    proId: 1,
    publicId: 'mock-3',
    createdDate: DateTime.now().subtract(const Duration(days: 27)),
    status: LeadStatus.contacted,
  ),
  Lead(
    requestId: 4,
    firstName: 'George',
    lastName: 'Cazel',
    phone: '(360) 555-0144',
    requestText: 'Remodel or renovate one or more rooms',
    city: 'Vancouver',
    state: 'WA',
    zipCode: '98684',
    proId: 1,
    publicId: 'mock-4',
    createdDate: DateTime.now().subtract(const Duration(days: 32)),
    status: LeadStatus.quoted,
  ),
  Lead(
    requestId: 5,
    firstName: 'Doug',
    lastName: 'Windress',
    requestText: 'Renovate or repair a home',
    city: 'Vancouver',
    state: 'WA',
    zipCode: '98682',
    proId: 1,
    publicId: 'mock-5',
    createdDate: DateTime.now().subtract(const Duration(days: 37)),
    status: LeadStatus.quoted,
  ),
  Lead(
    requestId: 6,
    firstName: 'Carmella',
    lastName: 'Weis',
    requestText: 'Remodel a kitchen',
    city: 'Camas',
    state: 'WA',
    zipCode: '98607',
    proId: 1,
    publicId: 'mock-6',
    createdDate: DateTime.now().subtract(const Duration(days: 45)),
    status: LeadStatus.won,
  ),
  Lead(
    requestId: 7,
    firstName: 'Virginia',
    lastName: 'Jimenez',
    requestText: 'Build an addition',
    city: 'Vancouver',
    state: 'WA',
    zipCode: '98662',
    proId: 1,
    publicId: 'mock-7',
    createdDate: DateTime.now().subtract(const Duration(days: 50)),
    status: LeadStatus.lost,
  ),
];
