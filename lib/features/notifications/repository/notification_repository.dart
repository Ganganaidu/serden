import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<AppNotification>>> fetchNotifications();
  Future<Either<Failure, void>> markAsRead(int notificationId);
  Future<Either<Failure, void>> markAllAsRead();
}

class NotificationRepositoryImpl implements NotificationRepository {
  final List<AppNotification> _items = List.from(mockNotifications);

  @override
  Future<Either<Failure, List<AppNotification>>> fetchNotifications() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Right(List.from(_items));
  }

  @override
  Future<Either<Failure, void>> markAsRead(int notificationId) async {
    final i = _items.indexWhere((n) => n.id == notificationId);
    if (i != -1) _items[i] = _items[i].copyWith(isRead: true);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
    return const Right(null);
  }
}
