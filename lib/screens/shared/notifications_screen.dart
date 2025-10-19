import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/notifications_provider.dart';
import '../../models/notification_model.dart';
import '../../widgets/lottie_loader.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Notifications are automatically loaded by the provider
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsProvider);
    final notifications = notificationsState.when(
      data: (data) => data,
      loading: () => <NotificationModel>[],
      error: (_, __) => <NotificationModel>[],
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.backgroundWhite, Color(0xFFF1F5F9)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Notifications',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                onPressed: _markAllAsRead,
                                icon: const Icon(Icons.done_all, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Appointments'),
                  Tab(text: 'Promotions'),
                ],
              ),
            ),

            // Filter Chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _buildFilterChip('All', _selectedFilter == 'All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Unread', _selectedFilter == 'Unread'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Today', _selectedFilter == 'Today'),
                    const Spacer(),
                    IconButton(
                      onPressed: _refreshNotifications,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNotificationsList(notifications, 'all'),
                  _buildNotificationsList(notifications, 'appointment'),
                  _buildNotificationsList(notifications, 'promotion'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryMauve : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryMauve : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationModel> notifications, String type) {
    // Filter notifications by type
    List<NotificationModel> filteredNotifications = notifications.where((notification) {
      switch (type) {
        case 'appointment':
          return notification.type == NotificationType.newAppointment;
        case 'promotion':
          return notification.type == NotificationType.general;
        default:
          return true;
      }
    }).toList();

    // Apply additional filters
    if (_selectedFilter == 'Unread') {
      filteredNotifications = filteredNotifications.where((n) => !n.isRead).toList();
    } else if (_selectedFilter == 'Today') {
      final today = DateTime.now();
      filteredNotifications = filteredNotifications.where((n) {
        return n.createdAt.day == today.day &&
               n.createdAt.month == today.month &&
               n.createdAt.year == today.year;
      }).toList();
    }

    if (filteredNotifications.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredNotifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationCard(filteredNotifications[index]);
      },
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    String lottieAsset;
    
    switch (type) {
      case 'appointment':
        message = 'No appointment notifications';
        lottieAsset = 'assets/lottie/empty_calendar.json';
        break;
      case 'promotion':
        message = 'No promotion notifications';
        lottieAsset = 'assets/lottie/empty_calendar.json';
        break;
      default:
        message = 'No notifications yet';
        lottieAsset = 'assets/lottie/empty_calendar.json';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LottieLoader(
            assetPath: 'assets/lottie/empty_calendar.json',
            message: 'No notifications yet',
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: AppTheme.heading2.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when something important happens',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AppTheme.glassCard(
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notification.isRead ? Colors.white : AppTheme.primaryMauve.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: notification.isRead 
                  ? Border.all(color: Colors.grey[200]!)
                  : Border.all(color: AppTheme.primaryMauve.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Notification Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                                color: notification.isRead ? AppTheme.textPrimary : AppTheme.primaryMauve,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryMauve,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(notification.createdAt),
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          if (notification.type == NotificationType.newAppointment)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryMauve.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Appointment',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.primaryMauve,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else if (notification.type == NotificationType.general)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGold.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Promotion',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.accentGold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action Button
                if (notification.type == NotificationType.newAppointment)
                  IconButton(
                    onPressed: () => _handleAppointmentAction(notification),
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newAppointment:
        return Icons.calendar_today;
      case NotificationType.general:
        return Icons.local_offer;
      case NotificationType.appointmentReminder:
        return Icons.notifications;
      case NotificationType.newMessage:
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.newAppointment:
        return AppTheme.primaryMauve;
      case NotificationType.general:
        return AppTheme.accentGold;
      case NotificationType.appointmentReminder:
        return AppTheme.infoColor;
      case NotificationType.newMessage:
        return AppTheme.successColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    if (!notification.isRead) {
      ref.read(notificationsProvider.notifier).markNotificationAsRead(notification.id);
    }

    // Handle navigation based on type
    switch (notification.type) {
      case NotificationType.newAppointment:
        context.push('/customer-appointments');
        break;
      case NotificationType.general:
        // Navigate to promotions or salon detail
        break;
      case NotificationType.appointmentReminder:
        // Navigate to relevant screen
        break;
      case NotificationType.newMessage:
        context.push('/customer-chat');
        break;
      case NotificationType.appointmentConfirmed:
        context.push('/customer-appointments');
        break;
      default:
        // Handle unknown notification types
        break;
    }
  }

  void _handleAppointmentAction(NotificationModel notification) {
    // Navigate to appointment details or booking
    context.push('/customer-appointments');
  }

  void _markAllAsRead() {
    ref.read(notificationsProvider.notifier).markAllNotificationsAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _refreshNotifications() {
    // Notifications are automatically refreshed by the provider
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications refreshed'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}