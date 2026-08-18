part of 'notifications_cubit.dart';

abstract class NotificationsState extends Equatable {
  const NotificationsState();
  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  final List<AppNotification> notifications;
  final String query;

  const NotificationsLoaded({required this.notifications, this.query = ''});

  List<AppNotification> get filtered {
    if (query.isEmpty) return notifications;
    final q = query.toLowerCase();
    return notifications
        .where((n) => n.title.toLowerCase().contains(q))
        .toList();
  }

  bool get hasUnread => notifications.any((n) => !n.isRead);
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  List<Object?> get props => [notifications, query];
}

class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);
  @override
  List<Object?> get props => [message];
}
