import 'package:equatable/equatable.dart';

enum NotificationType { lead, estimate, invoice, client, general }

class AppNotification extends Equatable {
  final int id;
  final NotificationType type;
  final String title;
  final String entityId;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.entityId,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as int,
        type: NotificationType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => NotificationType.general,
        ),
        title: json['title'] as String,
        entityId: json['entityId'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'entityId': entityId,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        entityId: entityId,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
      );

  @override
  List<Object?> get props => [id, type, title, entityId, createdAt, isRead];
}

final mockNotifications = <AppNotification>[
  AppNotification(
    id: 1,
    type: NotificationType.lead,
    title: 'New lead #114 was received from Kevin Gilper.',
    entityId: '114',
    createdAt: DateTime(2026, 8, 12, 13, 50),
    isRead: false,
  ),
  AppNotification(
    id: 2,
    type: NotificationType.lead,
    title: 'New lead #112 was received from EEXE EXE.',
    entityId: '112',
    createdAt: DateTime(2026, 7, 16, 22, 3),
    isRead: false,
  ),
  AppNotification(
    id: 3,
    type: NotificationType.estimate,
    title: 'Estimate #1172 was viewed by Joseph Ulrich.',
    entityId: '1172',
    createdAt: DateTime(2026, 8, 10, 9, 30),
    isRead: true,
  ),
  AppNotification(
    id: 4,
    type: NotificationType.invoice,
    title: 'Invoice payment of \$3,500 received from Susan Perry.',
    entityId: '87',
    createdAt: DateTime(2026, 8, 8, 14, 15),
    isRead: true,
  ),
  AppNotification(
    id: 5,
    type: NotificationType.estimate,
    title: 'Estimate #1171 was approved by Susan Perry.',
    entityId: '1171',
    createdAt: DateTime(2026, 8, 5, 11, 0),
    isRead: true,
  ),
  AppNotification(
    id: 6,
    type: NotificationType.client,
    title: 'David Woods added a new review.',
    entityId: '3',
    createdAt: DateTime(2026, 7, 28, 16, 45),
    isRead: true,
  ),
];
