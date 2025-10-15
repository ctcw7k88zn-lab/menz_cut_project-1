import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/app_env.dart';
import '../models/service_model.dart';
import '../models/appointment_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../models/salon_model.dart';
import '../models/user_model.dart';
import '../models/ai_suggestion_model.dart';

/// Local data service using Hive for persistence
/// Handles all CRUD operations and initial data seeding
class LocalDataService {
  static const String _servicesBox = 'services';
  static const String _appointmentsBox = 'appointments';
  static const String _messagesBox = 'messages';
  static const String _notificationsBox = 'notifications';
  static const String _salonsBox = 'salons';
  static const String _usersBox = 'users';
  static const String _settingsBox = 'settings';
  static const String _aiSuggestionsBox = 'ai_suggestions';

  static bool _isInitialized = false;
  static const Uuid _uuid = Uuid();

  /// Initialize Hive and seed data if first run
  static Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();
    
    // Register adapters
    _registerAdapters();
    
    // Open boxes
    await _openBoxes();
    
    // Seed data if first run
    await _seedDataIfNeeded();
    
    _isInitialized = true;
  }

  static void _registerAdapters() {
    // Register Hive adapters for all models
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ServiceModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppointmentModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MessageModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(NotificationModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SalonModelAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(UserRoleAdapter());
    }
    // Register enum adapters
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(MessageStatusAdapter());
    }
  }

  static Future<void> _openBoxes() async {
    await Hive.openBox<ServiceModel>(_servicesBox);
    await Hive.openBox<AppointmentModel>(_appointmentsBox);
    await Hive.openBox<MessageModel>(_messagesBox);
    await Hive.openBox<NotificationModel>(_notificationsBox);
    await Hive.openBox<SalonModel>(_salonsBox);
    await Hive.openBox<UserModel>(_usersBox);
    await Hive.openBox(_settingsBox);
  }

  static Future<void> _seedDataIfNeeded() async {
    // Skip seeding when using Supabase backend
    if (!AppEnv.enableMock) {
      return;
    }
    
    final settingsBox = Hive.box(_settingsBox);
    final isSeeded = settingsBox.get('isSeeded', defaultValue: false);
    
    if (!isSeeded) {
      await _seedInitialData();
      await settingsBox.put('isSeeded', true);
    }
  }

  static Future<void> _seedInitialData() async {
    try {
      // Always create default users first
      await _createDefaultUsers();
      
      // Load and seed salons
      try {
        final salonsJson = await rootBundle.loadString('assets/mock_data/salons.json');
        final salonsData = jsonDecode(salonsJson);

        if (salonsData is List) {
          final salonsBox = Hive.box<SalonModel>(_salonsBox);
          for (final salonData in salonsData) {
            if (salonData is Map<String, dynamic>) {
              final salon = SalonModel.fromJson(salonData);
              await salonsBox.put(salon.id, salon);
            }
          }
        }
      } catch (e) {
        print('Error seeding salons: $e');
      }

      // Load and seed services
      try {
        final servicesJson = await rootBundle.loadString('assets/mock_data/services.json');
        final servicesData = jsonDecode(servicesJson);

        if (servicesData is List) {
          final servicesBox = Hive.box<ServiceModel>(_servicesBox);
          for (final serviceData in servicesData) {
            if (serviceData is Map<String, dynamic>) {
              final service = ServiceModel.fromJson(serviceData);
              await servicesBox.put(service.id, service);
            }
          }
        }
      } catch (e) {
        print('Error seeding services: $e');
      }

      // Load and seed appointments
      try {
        final appointmentsJson = await rootBundle.loadString('assets/mock_data/appointments.json');
        final appointmentsData = jsonDecode(appointmentsJson);

        if (appointmentsData is List) {
          final appointmentsBox = Hive.box<AppointmentModel>(_appointmentsBox);
          for (final appointmentData in appointmentsData) {
            if (appointmentData is Map<String, dynamic>) {
              final appointment = AppointmentModel.fromJson(appointmentData);
              await appointmentsBox.put(appointment.id, appointment);
            }
          }
        }
      } catch (e) {
        print('Error seeding appointments: $e');
      }

      // Load and seed messages
      try {
        final messagesJson = await rootBundle.loadString('assets/mock_data/messages.json');
        final messagesData = jsonDecode(messagesJson);
        
        if (messagesData is List) {
          final messagesBox = Hive.box<MessageModel>(_messagesBox);
          for (final messageData in messagesData) {
            if (messageData is Map<String, dynamic>) {
              final message = MessageModel.fromJson(messageData);
              await messagesBox.put(message.id, message);
            }
          }
        }
      } catch (e) {
        print('Error seeding messages: $e');
      }

      // Load and seed notifications
      try {
        final notificationsJson = await rootBundle.loadString('assets/mock_data/notifications.json');
        final notificationsData = jsonDecode(notificationsJson);
        
        if (notificationsData is List) {
          final notificationsBox = Hive.box<NotificationModel>(_notificationsBox);
          for (final notificationData in notificationsData) {
            if (notificationData is Map<String, dynamic>) {
              final notification = NotificationModel.fromJson(notificationData);
              await notificationsBox.put(notification.id, notification);
            }
          }
        }
      } catch (e) {
        print('Error seeding notifications: $e');
      }
      
    } catch (e) {
      print('Error seeding data: $e');
    }
  }

  static Future<void> _createDefaultUsers() async {
    final usersBox = Hive.box<UserModel>(_usersBox);
    
    // Default customer
    final customer = UserModel(
      id: 'customer_1',
      fullName: 'John Doe',
      email: 'customer@example.com',
      role: UserRole.customer,
      profileImageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      phone: '+1234567890',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await usersBox.put(customer.id, customer);

    // Default salon owner
    final owner = UserModel(
      id: 'owner_1',
      fullName: 'Jane Smith',
      email: 'owner@example.com',
      role: UserRole.owner,
      profileImageUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
      phone: '+1234567891',
      salonId: 'salon_1', // Links to first salon
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await usersBox.put(owner.id, owner);
  }

  // Service operations
  static Future<List<ServiceModel>> getAllServices() async {
    final box = Hive.box<ServiceModel>(_servicesBox);
    return box.values.toList();
  }

  static Future<List<ServiceModel>> getServicesBySalon(String salonId) async {
    final box = Hive.box<ServiceModel>(_servicesBox);
    return box.values.where((service) => service.salonId == salonId).toList();
  }

  static Future<ServiceModel?> getService(String id) async {
    final box = Hive.box<ServiceModel>(_servicesBox);
    return box.get(id);
  }

  static Future<String> saveService(ServiceModel service) async {
    final box = Hive.box<ServiceModel>(_servicesBox);
    final serviceWithId = service.copyWith(
      id: service.id.isEmpty ? _uuid.v4() : service.id,
      updatedAt: DateTime.now(),
    );
    await box.put(serviceWithId.id, serviceWithId);
    return serviceWithId.id;
  }

  static Future<void> deleteService(String id) async {
    final box = Hive.box<ServiceModel>(_servicesBox);
    await box.delete(id);
  }

  // Appointment operations
  static Future<List<AppointmentModel>> getAllAppointments() async {
    final box = Hive.box<AppointmentModel>(_appointmentsBox);
    return box.values.toList();
  }

  static Future<List<AppointmentModel>> getAppointmentsBySalon(String salonId) async {
    final box = Hive.box<AppointmentModel>(_appointmentsBox);
    return box.values.where((appointment) => appointment.salonId == salonId).toList();
  }

  static Future<List<AppointmentModel>> getAppointmentsByCustomer(String customerId) async {
    final box = Hive.box<AppointmentModel>(_appointmentsBox);
    return box.values.where((appointment) => appointment.customerId == customerId).toList();
  }

  static Future<AppointmentModel?> getAppointment(String id) async {
    final box = Hive.box<AppointmentModel>(_appointmentsBox);
    return box.get(id);
  }

  static Future<String> saveAppointment(AppointmentModel appointment) async {
    final box = Hive.box<AppointmentModel>(_appointmentsBox);
    final appointmentWithId = appointment.copyWith(
      id: appointment.id.isEmpty ? _uuid.v4() : appointment.id,
      updatedAt: DateTime.now(),
    );
    await box.put(appointmentWithId.id, appointmentWithId);
    return appointmentWithId.id;
  }

  static Future<void> updateAppointmentStatus(String id, AppointmentStatus status) async {
    final box = Hive.box<AppointmentModel>(_appointmentsBox);
    final appointment = box.get(id);
    if (appointment != null) {
      final updatedAppointment = appointment.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      await box.put(id, updatedAppointment);
    }
  }

  static Future<void> deleteAppointment(String id) async {
    final box = Hive.box<AppointmentModel>(_appointmentsBox);
    await box.delete(id);
  }

  // Message operations
  static Future<List<MessageModel>> getAllMessages() async {
    final box = Hive.box<MessageModel>(_messagesBox);
    return box.values.toList();
  }

  static Future<List<MessageModel>> getMessagesByThread(String threadId) async {
    final box = Hive.box<MessageModel>(_messagesBox);
    return box.values.where((message) => message.threadId == threadId).toList();
  }

  static Future<List<MessageModel>> getMessagesByUser(String userId) async {
    final box = Hive.box<MessageModel>(_messagesBox);
    return box.values.where((message) => 
      message.senderId == userId || message.receiverId == userId).toList();
  }

  static Future<MessageModel?> getMessage(String id) async {
    final box = Hive.box<MessageModel>(_messagesBox);
    return box.get(id);
  }


  static Future<String> saveMessage(MessageModel message) async {
    final box = Hive.box<MessageModel>(_messagesBox);
    final messageWithId = message.copyWith(
      id: message.id.isEmpty ? _uuid.v4() : message.id,
      createdAt: DateTime.now(),
    );
    await box.put(messageWithId.id, messageWithId);
    return messageWithId.id;
  }

  static Future<void> updateMessageStatus(String id, MessageStatus status) async {
    final box = Hive.box<MessageModel>(_messagesBox);
    final message = box.get(id);
    if (message != null) {
      final updatedMessage = message.copyWith(status: status);
      await box.put(id, updatedMessage);
    }
  }

  // Notification operations
  static Future<List<NotificationModel>> getAllNotifications() async {
    final box = Hive.box<NotificationModel>(_notificationsBox);
    return box.values.toList();
  }

  static Future<List<NotificationModel>> getNotificationsByUser(String userId) async {
    final box = Hive.box<NotificationModel>(_notificationsBox);
    return box.values.where((notification) => notification.userId == userId).toList();
  }

  static Future<NotificationModel?> getNotification(String id) async {
    final box = Hive.box<NotificationModel>(_notificationsBox);
    return box.get(id);
  }

  static Future<String> saveNotification(NotificationModel notification) async {
    final box = Hive.box<NotificationModel>(_notificationsBox);
    final notificationWithId = notification.copyWith(
      id: notification.id.isEmpty ? _uuid.v4() : notification.id,
      createdAt: DateTime.now(),
    );
    await box.put(notificationWithId.id, notificationWithId);
    return notificationWithId.id;
  }

  static Future<void> markNotificationAsRead(String id) async {
    final box = Hive.box<NotificationModel>(_notificationsBox);
    final notification = box.get(id);
    if (notification != null) {
      final updatedNotification = notification.copyWith(isRead: true);
      await box.put(id, updatedNotification);
    }
  }

  static Future<void> deleteNotification(String id) async {
    final box = Hive.box<NotificationModel>(_notificationsBox);
    await box.delete(id);
  }

  // Salon operations
  static Future<List<SalonModel>> getAllSalons() async {
    final box = Hive.box<SalonModel>(_salonsBox);
    return box.values.toList();
  }

  static Future<SalonModel?> getSalon(String id) async {
    final box = Hive.box<SalonModel>(_salonsBox);
    return box.get(id);
  }

  // User operations
  static Future<List<UserModel>> getAllUsers() async {
    final box = Hive.box<UserModel>(_usersBox);
    return box.values.toList();
  }

  static Future<List<UserModel>> getUsers() async {
    return getAllUsers();
  }

  static Future<UserModel?> getUser(String id) async {
    final box = Hive.box<UserModel>(_usersBox);
    return box.get(id);
  }

  static Future<UserModel?> getUserByEmail(String email) async {
    final box = Hive.box<UserModel>(_usersBox);
    try {
      return box.values.firstWhere(
        (user) => user.email == email,
      );
    } catch (e) {
      return null; // Return null if user not found
    }
  }

  static Future<String> saveUser(UserModel user) async {
    final box = Hive.box<UserModel>(_usersBox);
    final userWithId = user.copyWith(
      id: user.id.isEmpty ? _uuid.v4() : user.id,
      updatedAt: DateTime.now(),
    );
    await box.put(userWithId.id, userWithId);
    return userWithId.id;
  }

  // Utility methods
  static Future<void> resetData() async {
    final settingsBox = Hive.box(_settingsBox);
    await settingsBox.put('isSeeded', false);
    
    // Clear all boxes
    await Hive.box<ServiceModel>(_servicesBox).clear();
    await Hive.box<AppointmentModel>(_appointmentsBox).clear();
    await Hive.box<MessageModel>(_messagesBox).clear();
    await Hive.box<NotificationModel>(_notificationsBox).clear();
    await Hive.box<SalonModel>(_salonsBox).clear();
    await Hive.box<UserModel>(_usersBox).clear();
    await Hive.box<AISuggestionModel>(_aiSuggestionsBox).clear();
    
    // Re-seed data
    await _seedDataIfNeeded();
  }

  // Force create default users (useful for testing)
  static Future<void> createDefaultUsers() async {
    await _createDefaultUsers();
  }

  // AI Suggestions
  static Future<void> saveAISuggestion(AISuggestionModel suggestion) async {
    final box = Hive.box<AISuggestionModel>(_aiSuggestionsBox);
    await box.put(suggestion.id, suggestion);
  }

  static Future<List<AISuggestionModel>> getAllAISuggestions() async {
    final box = Hive.box<AISuggestionModel>(_aiSuggestionsBox);
    final suggestions = box.values.toList();
    suggestions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return suggestions;
  }

  static Future<List<AISuggestionModel>> getAISuggestionsByUser(String userId) async {
    final box = Hive.box<AISuggestionModel>(_aiSuggestionsBox);
    final suggestions = box.values.where((suggestion) => suggestion.userId == userId).toList();
    suggestions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return suggestions;
  }

  static Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
  }
}
