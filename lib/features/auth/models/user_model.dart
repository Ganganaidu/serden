import 'package:equatable/equatable.dart';

/// Mirrors the backend's `SerdenUser` DTO returned by
/// /api/Users/login, /api/Users/register (via login), /api/Users/refresh,
/// and /api/Users/publicid.
///
/// [proId] is NOT part of SerdenUser — it comes from a separate
/// GET /api/Pros/user/{userId} call made after login and is stored
/// alongside the user for use in Pro-scoped API endpoints (clients,
/// estimates, invoices, etc.).
class UserModel extends Equatable {
  final int userId;
  final int? proId;
  final String? publicId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? role;
  final String? subscriptionStatus;
  final DateTime? subscriptionEndDate;

  const UserModel({
    required this.userId,
    this.proId,
    this.publicId,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.role,
    this.subscriptionStatus,
    this.subscriptionEndDate,
  });

  String get fullName => '$firstName $lastName'.trim();

  UserModel copyWith({
    int? proId,
    String? firstName,
    String? lastName,
    String? email,
  }) =>
      UserModel(
        userId: userId,
        proId: proId ?? this.proId,
        publicId: publicId,
        username: username,
        email: email ?? this.email,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        role: role,
        subscriptionStatus: subscriptionStatus,
        subscriptionEndDate: subscriptionEndDate,
      );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        userId: json['userId'] as int? ?? 0,
        proId: json['proId'] as int?,
        publicId: json['publicId'] as String?,
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        role: json['role'] as String?,
        subscriptionStatus: json['subscriptionStatus'] as String?,
        subscriptionEndDate: json['subscriptionEndDate'] == null
            ? null
            : DateTime.tryParse(json['subscriptionEndDate'] as String),
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        if (proId != null) 'proId': proId,
        'publicId': publicId,
        'username': username,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'subscriptionStatus': subscriptionStatus,
        'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        userId,
        proId,
        publicId,
        username,
        email,
        firstName,
        lastName,
        role,
        subscriptionStatus,
        subscriptionEndDate,
      ];
}
