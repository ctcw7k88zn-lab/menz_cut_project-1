import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../services/app_api.dart';
import '../services/realtime_service.dart';

/// Enhanced Notifications provider using AsyncNotifier for better error handling
class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  final RealtimeService _realtimeService = RealtimeService();
  final Uuid _uuid = const Uuid();

  @override
  Future<List<NotificationModel>> build() async {
    // Initialize with empty list - will be loaded per user
    final notifications = <NotificationModel>[];
    
    // Subscribe to realtime updates
    _subscribeToRealtimeUpdates();
    
    return notifications;
  }

  /// Subscribe to realtime notification updates
  void _subscribeToRealtimeUpdates() {
    _realtimeService.notificationsStream.listen((newNotification) {
      state.whenData((notifications) {
        state = AsyncValue.data([newNotification, ...notifications]);
      });
    });
  }

  /// Load notifications for a specific user
  Future<void> loadNotificationsForUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      final notifications = await AppApi.getNotificationsByUser(userId);
      state = AsyncValue.data(notifications);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await AppApi.markNotificationAsRead(notificationId);
      
      state.whenData((notifications) {
        final updatedNotifications = notifications.map((notification) {
          if (notification.id == notificationId) {
            return notification.copyWith(isRead: true);
          }
          return notification;
        }).toList();
        state = AsyncValue.data(updatedNotifications);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      state.whenData((notifications) {
        final unreadNotifications = notifications.where(
          (notification) => !notification.isRead,
        );
        
        for (final notification in unreadNotifications) {
          markNotificationAsRead(notification.id);
        }
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await AppApi.deleteNotification(notificationId);
      
      state.whenData((notifications) {
        state = AsyncValue.data(notifications.where(
          (notification) => notification.id != notificationId,
        ).toList());
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      state.whenData((notifications) {
        for (final notification in notifications) {
          deleteNotification(notification.id);
        }
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Get unread notification count
  int getUnreadNotificationCount() {
    return state.whenData((notifications) {
      return notifications.where(
        (notification) => !notification.isRead,
      ).length;
    }).value ?? 0;
  }

  /// Get notifications by type
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return state.whenData((notifications) {
      return notifications.where(
        (notification) => notification.type == type,
      ).toList();
    }).value ?? [];
  }

  /// Get latest notifications
  List<NotificationModel> getLatestNotifications({int limit = 10}) {
    return state.whenData((notifications) {
      final sortedNotifications = List<NotificationModel>.from(notifications);
      sortedNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sortedNotifications.take(limit).toList();
    }).value ?? [];
  }

  /// Get unread notifications
  List<NotificationModel> getUnreadNotifications() {
    return state.whenData((notifications) {
      return notifications.where(
        (notification) => !notification.isRead,
      ).toList();
    }).value ?? [];
  }

  /// Get read notifications
  List<NotificationModel> getReadNotifications() {
    return state.whenData((notifications) {
      return notifications.where(
        (notification) => notification.isRead,
      ).toList();
    }).value ?? [];
  }

  /// Create a local notification (for testing or immediate feedback)
  void createLocalNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) {
    final notification = NotificationModel(
      id: _uuid.v4(),
      userId: userId,
      type: type,
      title: title,
      message: message,
      data: data ?? {},
      isRead: false,
      createdAt: DateTime.now(),
    );
    
    state.whenData((notifications) {
      state = AsyncValue.data([notification, ...notifications]);
    });
  }

  /// Refresh notifications
  Future<void> refreshNotifications() async {
    final currentState = state;
    if (currentState.hasValue && currentState.value!.isNotEmpty) {
      final firstNotification = currentState.value!.first;
      await loadNotificationsForUser(firstNotification.userId);
    }
  }
}

/// Enhanced Notifications provider using AsyncNotifier
final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(() {
  return NotificationsNotifier();
});

/// Notifications by user provider
final notificationsByUserProvider = FutureProvider.family<List<NotificationModel>, String>((ref, userId) async {
  final notificationsNotifier = ref.read(notificationsProvider.notifier);
  await notificationsNotifier.loadNotificationsForUser(userId);
  final notificationsAsync = ref.read(notificationsProvider);
  return notificationsAsync.when(
    data: (notifications) => notifications,
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Unread notification count provider
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notificationsNotifier = ref.read(notificationsProvider.notifier);
  return notificationsNotifier.getUnreadNotificationCount();
});

/// Latest notifications provider
final latestNotificationsProvider = Provider.family<List<NotificationModel>, int>((ref, limit) {
  final notificationsNotifier = ref.read(notificationsProvider.notifier);
  return notificationsNotifier.getLatestNotifications(limit: limit);
});

/// Unread notifications provider
final unreadNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  final notificationsNotifier = ref.read(notificationsProvider.notifier);
  return notificationsNotifier.getUnreadNotifications();
});

/// Read notifications provider
final readNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  final notificationsNotifier = ref.read(notificationsProvider.notifier);
  return notificationsNotifier.getReadNotifications();
});