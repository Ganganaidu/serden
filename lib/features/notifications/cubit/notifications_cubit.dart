import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/notification_model.dart';
import '../repository/notification_repository.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationRepository _repository;

  NotificationsCubit({required NotificationRepository repository})
      : _repository = repository,
        super(const NotificationsInitial());

  Future<void> fetch() async {
    emit(const NotificationsLoading());
    final result = await _repository.fetchNotifications();
    result.fold(
      (failure) => emit(NotificationsError(failure.message)),
      (notifications) =>
          emit(NotificationsLoaded(notifications: notifications)),
    );
  }

  void search(String query) {
    final s = state;
    if (s is NotificationsLoaded) {
      emit(NotificationsLoaded(notifications: s.notifications, query: query));
    }
  }

  Future<void> markAsRead(int id) async {
    await _repository.markAsRead(id);
    final s = state;
    if (s is NotificationsLoaded) {
      final updated = s.notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList();
      emit(NotificationsLoaded(notifications: updated, query: s.query));
    }
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    final s = state;
    if (s is NotificationsLoaded) {
      final updated = s.notifications.map((n) => n.copyWith(isRead: true)).toList();
      emit(NotificationsLoaded(notifications: updated, query: s.query));
    }
  }
}
