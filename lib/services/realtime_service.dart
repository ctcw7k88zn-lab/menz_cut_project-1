import 'dart:async';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/app_env.dart';
import '../models/service_model.dart';
import '../models/appointment_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import 'supabase_service.dart';

/// Realtime service that provides real-time updates
/// Uses Supabase Realtime when not in mock mode, otherwise simulates updates
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  // Stream controllers for mock mode
  final StreamController<ServiceModel> _servicesController = 
      StreamController<ServiceModel>.broadcast();
  final StreamController<AppointmentModel> _appointmentsController = 
      StreamController<AppointmentModel>.broadcast();
  final StreamController<MessageModel> _messagesController = 
      StreamController<MessageModel>.broadcast();
  final StreamController<NotificationModel> _notificationsController = 
      StreamController<NotificationModel>.broadcast();

  // Stream getters - use Supabase streams when not in mock mode
  Stream<ServiceModel> get servicesStream {
    if (AppEnv.enableMock) {
      return _servicesController.stream;
    } else {
      return SupabaseService.servicesStream
          .where((services) => services.isNotEmpty)
          .map((services) => services.first);
    }
  }

  Stream<AppointmentModel> get appointmentsStream {
    if (AppEnv.enableMock) {
      return _appointmentsController.stream;
    } else {
      return SupabaseService.appointmentsStream
          .where((appointments) => appointments.isNotEmpty)
          .map((appointments) => appointments.first);
    }
  }

  Stream<MessageModel> get messagesStream {
    if (AppEnv.enableMock) {
      return _messagesController.stream;
    } else {
      return SupabaseService.messagesStream
          .where((messages) => messages.isNotEmpty)
          .map((messages) => messages.first);
    }
  }

  Stream<NotificationModel> get notificationsStream {
    if (AppEnv.enableMock) {
      return _notificationsController.stream;
    } else {
      return SupabaseService.notificationsStream.map((notifications) => notifications.first);
    }
  }

  // Configuration
  bool get _simulateRealtime => dotenv.env['APP_SIMULATE_REALTIME']?.toLowerCase() == 'true';
  final Random _random = Random();

  /// Simulate network delay
  Future<void> _simulateDelay() async {
    if (!_simulateRealtime) return;
    
    // Random delay between 300-800ms to simulate network latency
    final delay = 300 + _random.nextInt(500);
    await Future.delayed(Duration(milliseconds: delay));
  }

  /// Emit service update with simulated delay
  Future<void> emitServiceUpdated(ServiceModel service) async {
    await _simulateDelay();
    _servicesController.add(service);
    
    // Create notification for salon customers about new service
    if (_simulateRealtime) {
      await _createServiceNotification(service);
    }
  }

  /// Emit service deletion
  Future<void> emitServiceDeleted(String serviceId) async {
    await _simulateDelay();
    // Create a dummy service with deleted flag for deletion events
    final deletedService = ServiceModel(
      id: serviceId,
      salonId: '',
      name: '',
      description: '',
      price: 0,
      durationMinutes: 0,
      category: '',
      isActive: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _servicesController.add(deletedService);
  }

  /// Emit appointment update with simulated delay
  Future<void> emitAppointmentUpdated(AppointmentModel appointment) async {
    await _simulateDelay();
    _appointmentsController.add(appointment);
    
    // Create notification for the other party
    if (_simulateRealtime) {
      await _createAppointmentNotification(appointment);
    }
  }

  /// Emit appointment deletion
  Future<void> emitAppointmentDeleted(String appointmentId) async {
    await _simulateDelay();
    // Create a dummy appointment with deleted flag
    final deletedAppointment = AppointmentModel(
      id: appointmentId,
      customerId: '',
      salonId: '',
      serviceId: '',
      startAt: DateTime.now(),
      endAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: AppointmentStatus.cancelled,
      paymentStatus: PaymentStatus.pending,
      totalAmount: 0,
    );
    _appointmentsController.add(deletedAppointment);
  }

  /// Emit message update with simulated delay
  Future<void> emitMessageUpdated(MessageModel message) async {
    await _simulateDelay();
    _messagesController.add(message);
    
    // Create notification for the receiver
    if (_simulateRealtime) {
      await _createMessageNotification(message);
    }
  }

  /// Emit notification
  Future<void> emitNotification(NotificationModel notification) async {
    await _simulateDelay();
    _notificationsController.add(notification);
  }

  /// Create notification for service updates
  Future<void> _createServiceNotification(ServiceModel service) async {
    // This would typically query for salon customers
    // For demo purposes, we'll create a generic notification
    final notification = NotificationModel(
      id: '',
      userId: 'customer_1', // Would be dynamic in real app
      type: NotificationType.serviceUpdate,
      title: 'New Service Available',
      message: '${service.name} is now available at your favorite salon!',
      data: {'serviceId': service.id, 'salonId': service.salonId},
      isRead: false,
      createdAt: DateTime.now(),
    );
    
    _notificationsController.add(notification);
  }

  /// Create notification for appointment updates
  Future<void> _createAppointmentNotification(AppointmentModel appointment) async {
    // Determine notification recipient and content based on status
    String recipientId;
    String title;
    String message;
    NotificationType type;

    switch (appointment.status) {
      case AppointmentStatus.confirmed:
        recipientId = appointment.customerId;
        title = 'Appointment Confirmed';
        message = 'Your appointment has been confirmed by the salon.';
        type = NotificationType.appointmentConfirmed;
        break;
      case AppointmentStatus.cancelled:
        recipientId = appointment.customerId;
        title = 'Appointment Cancelled';
        message = 'Your appointment has been cancelled.';
        type = NotificationType.appointmentCancelled;
        break;
      case AppointmentStatus.completed:
        recipientId = appointment.customerId;
        title = 'Appointment Completed';
        message = 'Your appointment has been completed. How was your experience?';
        type = NotificationType.appointmentCompleted;
        break;
      case AppointmentStatus.pending:
        recipientId = appointment.salonId; // Assuming salonId maps to owner
        title = 'New Appointment Request';
        message = 'You have a new appointment request from a customer.';
        type = NotificationType.newAppointment;
        break;
      default:
        return; // No notification needed
    }

    final notification = NotificationModel(
      id: '',
      userId: recipientId,
      type: type,
      title: title,
      message: message,
      data: {
        'appointmentId': appointment.id,
        'customerId': appointment.customerId,
        'salonId': appointment.salonId,
        'status': appointment.status.name,
      },
      isRead: false,
      createdAt: DateTime.now(),
    );

    _notificationsController.add(notification);
  }

  /// Create notification for messages
  Future<void> _createMessageNotification(MessageModel message) async {
    final notification = NotificationModel(
      id: '',
      userId: message.receiverId,
      type: NotificationType.newMessage,
      title: 'New Message',
      message: message.text.length > 50 
          ? '${message.text.substring(0, 50)}...'
          : message.text,
      data: {
        'messageId': message.id,
        'threadId': message.threadId,
        'senderId': message.senderId,
      },
      isRead: false,
      createdAt: DateTime.now(),
    );

    _notificationsController.add(notification);
  }

  /// Simulate typing indicator
  Future<void> simulateTyping(String threadId, String senderId) async {
    await _simulateDelay();
    // Create a special message with typing indicator
    final typingMessage = MessageModel(
      id: 'typing_${DateTime.now().millisecondsSinceEpoch}',
      threadId: threadId,
      senderId: senderId,
      receiverId: '', // Will be set by the receiver
      text: 'typing...',
      attachments: [],
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    
    _messagesController.add(typingMessage);
  }

  /// Simulate message read status
  Future<void> simulateMessageRead(String messageId) async {
    await _simulateDelay();
    // Create a special message with read status
    final readMessage = MessageModel(
      id: messageId,
      threadId: '',
      senderId: '',
      receiverId: '',
      text: '',
      attachments: [],
      createdAt: DateTime.now(),
      status: MessageStatus.read,
    );
    
    _messagesController.add(readMessage);
  }

  /// Simulate online/offline status
  Future<void> simulateUserStatus(String userId, bool isOnline) async {
    await _simulateDelay();
    // This could be extended to include user status updates
    // For now, we'll just simulate the delay
  }

  /// Simulate appointment reminders
  Future<void> simulateAppointmentReminder(AppointmentModel appointment) async {
    await _simulateDelay();
    
    final reminder = NotificationModel(
      id: '',
      userId: appointment.customerId,
      type: NotificationType.appointmentReminder,
      title: 'Appointment Reminder',
      message: 'You have an appointment in 1 hour at ${appointment.startAt.toString()}',
      data: {
        'appointmentId': appointment.id,
        'reminderType': '1_hour',
      },
      isRead: false,
      createdAt: DateTime.now(),
    );

    _notificationsController.add(reminder);
  }

  /// Simulate salon status updates (open/closed)
  Future<void> simulateSalonStatusUpdate(String salonId, bool isOpen) async {
    await _simulateDelay();
    
    final statusNotification = NotificationModel(
      id: '',
      userId: 'customer_1', // Would be sent to all customers
      type: NotificationType.salonUpdate,
      title: isOpen ? 'Salon is Now Open' : 'Salon is Now Closed',
      message: isOpen 
          ? 'The salon is now accepting appointments.'
          : 'The salon is currently closed.',
      data: {
        'salonId': salonId,
        'isOpen': isOpen,
      },
      isRead: false,
      createdAt: DateTime.now(),
    );

    _notificationsController.add(statusNotification);
  }

  /// Dispose all stream controllers
  void dispose() {
    _servicesController.close();
    _appointmentsController.close();
    _messagesController.close();
    _notificationsController.close();
  }
}
