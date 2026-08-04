import 'package:equatable/equatable.dart';

class Client extends Equatable {
  final int clientId;
  final int proId;
  final String? publicId;
  final String name;
  final String? email;
  final String? phoneMobile;
  final String? phoneOther;
  final String? address;
  final String? address2;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? privateNotes;
  final bool isActive;
  final DateTime? createdDate;
  final DateTime? modifiedDate;
  // Not returned by the API — future stats aggregation endpoint
  final int jobs;
  final double lifetimeValue;

  const Client({
    required this.clientId,
    required this.proId,
    this.publicId,
    required this.name,
    this.email,
    this.phoneMobile,
    this.phoneOther,
    this.address,
    this.address2,
    this.city,
    this.state,
    this.zipCode,
    this.privateNotes,
    this.isActive = true,
    this.createdDate,
    this.modifiedDate,
    this.jobs = 0,
    this.lifetimeValue = 0,
  });

  // Backward-compat getters used by list/detail screens
  String get id => clientId.toString();
  String get phone => phoneMobile ?? '';

  String get place {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) {
      parts.add('${city!}${state != null && state!.isNotEmpty ? ', $state' : ''}');
    }
    return parts.join(' · ');
  }

  String get billingAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (address2 != null && address2!.isNotEmpty) parts.add(address2!);
    if (city != null && city!.isNotEmpty) {
      final cityState = [
        city!,
        if (state != null && state!.isNotEmpty) state!,
      ].join(', ');
      parts.add('$cityState${zipCode != null && zipCode!.isNotEmpty ? ' $zipCode' : ''}');
    }
    return parts.join(', ');
  }

  bool get isNew => jobs == 0;

  Client copyWith({
    String? name,
    String? email,
    String? phoneMobile,
    String? phoneOther,
    String? address,
    String? address2,
    String? city,
    String? state,
    String? zipCode,
    String? privateNotes,
    bool? isActive,
  }) =>
      Client(
        clientId: clientId,
        proId: proId,
        publicId: publicId,
        name: name ?? this.name,
        email: email,
        phoneMobile: phoneMobile,
        phoneOther: phoneOther,
        address: address,
        address2: address2,
        city: city,
        state: state,
        zipCode: zipCode,
        privateNotes: privateNotes,
        isActive: isActive ?? this.isActive,
        createdDate: createdDate,
        modifiedDate: modifiedDate,
        jobs: jobs,
        lifetimeValue: lifetimeValue,
      );

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        clientId: json['clientId'] as int? ?? 0,
        proId: json['proId'] as int? ?? 0,
        publicId: json['publicId'] as String?,
        name: json['name'] as String? ?? '',
        email: json['email'] as String?,
        phoneMobile: json['phoneMobile'] as String?,
        phoneOther: json['phoneOther'] as String?,
        address: json['address'] as String?,
        address2: json['address2'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        zipCode: json['zipCode'] as String?,
        privateNotes: json['privateNotes'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        createdDate: json['createdDate'] == null
            ? null
            : DateTime.tryParse(json['createdDate'] as String),
        modifiedDate: json['modifiedDate'] == null
            ? null
            : DateTime.tryParse(json['modifiedDate'] as String),
      );

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'proId': proId,
        'name': name,
        if (email != null) 'email': email,
        if (phoneMobile != null) 'phoneMobile': phoneMobile,
        if (phoneOther != null) 'phoneOther': phoneOther,
        if (address != null) 'address': address,
        if (address2 != null) 'address2': address2,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (zipCode != null) 'zipCode': zipCode,
        if (privateNotes != null) 'privateNotes': privateNotes,
        'isActive': isActive,
      };

  @override
  List<Object?> get props => [
        clientId,
        proId,
        name,
        email,
        phoneMobile,
        phoneOther,
        address,
        address2,
        city,
        state,
        zipCode,
        privateNotes,
        isActive,
      ];
}

final List<Client> mockClients = [
  const Client(clientId: 1, proId: 1, name: 'Avery Atkinson', address: '730 Maple Ct', city: 'Hillsboro', state: 'OR', zipCode: '97124', jobs: 3, lifetimeValue: 21400, email: 'avery.atkinson@workmail.com', phoneMobile: '(503) 998-2241'),
  const Client(clientId: 2, proId: 1, name: 'Bianca Bellini', address: '58 Harbor View Rd', city: 'Vancouver', state: 'WA', zipCode: '98661', jobs: 1, lifetimeValue: 6200, email: 'bianca.b@email.com', phoneMobile: '(360) 555-0114'),
  const Client(clientId: 3, proId: 1, name: 'Camila Cardoso', address: '68 Willow Rd', city: 'Gresham', state: 'OR', zipCode: '97030', jobs: 2, lifetimeValue: 15750, email: 'camila.cardoso@email.com', phoneMobile: '(503) 555-0187'),
  const Client(clientId: 4, proId: 1, name: 'Dana & Cole Reyes', address: '14104 NW 10th Ct', city: 'Vancouver', state: 'WA', zipCode: '98685', jobs: 1, lifetimeValue: 8900, email: 'reyes.family@email.com', phoneMobile: '(360) 555-0126'),
  const Client(clientId: 5, proId: 1, name: 'Devon Chase', address: '216 Fremont Pl', city: 'Portland', state: 'OR', zipCode: '97227', jobs: 0, lifetimeValue: 0, email: 'devon.chase@email.com', phoneMobile: '(503) 555-0163'),
  const Client(clientId: 6, proId: 1, name: 'Joseph Ulrich', address: '412 Alder St', city: 'Portland', state: 'OR', zipCode: '97201', jobs: 1, lifetimeValue: 10600, email: 'joseph.ulrich@email.com', phoneMobile: '(503) 730-9144'),
  const Client(clientId: 7, proId: 1, name: 'Mary Ellen Melville', address: '77 Lakeview Dr', city: 'Camas', state: 'WA', zipCode: '98607', jobs: 2, lifetimeValue: 9600, email: 'maryellen.m@email.com', phoneMobile: '(360) 555-0139'),
  const Client(clientId: 8, proId: 1, name: 'Susan Perry', address: '1930 Cedar Ln', city: 'Beaverton', state: 'OR', zipCode: '97006', jobs: 1, lifetimeValue: 14800, email: 'susan.perry@email.com', phoneMobile: '(503) 555-0171'),
  const Client(clientId: 9, proId: 1, name: 'Zachary Bosma', address: '506 NE 88th Ave', city: 'Vancouver', state: 'WA', zipCode: '98664', jobs: 1, lifetimeValue: 2500, email: 'zach.bosma@email.com', phoneMobile: '(360) 555-0192'),
];
