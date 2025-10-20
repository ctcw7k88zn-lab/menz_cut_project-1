import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_env.dart';
import '../models/user_model.dart';
import '../models/salon_model.dart';
import '../models/service_model.dart';
import '../models/appointment_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../models/ai_suggestion_model.dart';
import '../models/review_model.dart';
import 'local_data_service.dart';
import 'realtime_service.dart';
import 'supabase_service.dart';

/// AppApi facade that routes calls to local services or real backend
/// Set useLocal = false to switch to Supabase backend
class AppApi {
  static bool useLocal = AppEnv.enableMock; // Use Supabase by default
  static final SupabaseClient _supabase = Supabase.instance.client;
  static bool get isMockMode => AppEnv.enableMock;
  static bool get _simulateRealtime => dotenv.env['APP_SIMULATE_REALTIME']?.toLowerCase() == 'true';
  
  // Services
  static final RealtimeService _realtimeService = RealtimeService();
  
  // Authentication
  static Future<UserModel> getCurrentUser() async {
    if (useLocal) {
      await _simulateNetworkDelay();
      // Return the first user from local storage
      final users = await LocalDataService.getUsers();
      if (users.isNotEmpty) {
        return users.first;
      }
      throw Exception('No user found');
    } else {
      return await SupabaseService.getCurrentUser();
    }
  }

  static Future<UserModel> login(String email, String password) async {
    if (useLocal) {
      return _localLogin(email, password);
    } else {
      return SupabaseService.login(email, password);
    }
  }

  static Future<UserModel> _localLogin(String email, String password) async {
      await _simulateNetworkDelay();
      
    try {
      final user = await LocalDataService.getUserByEmail(email);
      if (user != null) {
        return user;
      }
    } catch (e) {
      // User not found, continue with mock logic
    }
    
    // Fallback to mock credentials for demo
    if (email == 'customer@example.com' && password == 'password') {
        return UserModel(
        id: 'customer_1',
        fullName: 'John Doe',
        email: 'customer@example.com',
        role: UserRole.customer,
        profileImageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
          phone: '+1234567890',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      
    if (email == 'owner@example.com' && password == 'password') {
        return UserModel(
        id: 'owner_1',
        fullName: 'Jane Smith',
        email: 'owner@example.com',
        role: UserRole.owner,
        profileImageUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
        phone: '+1234567891',
        salonId: 'salon_1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      
    throw Exception('Invalid credentials');
  }

  static Future<void> logout() async {
    if (useLocal) {
      await _simulateNetworkDelay();
      // Local logout - just simulate delay
    } else {
      await SupabaseService.logout();
    }
  }

  static Future<UserModel> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
  }) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      
      // Create new user
      final user = UserModel(
        id: const Uuid().v4(),
        email: email,
        fullName: fullName,
        phone: phone,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEmailVerified: false,
        isPhoneVerified: false,
        salonId: role == UserRole.salonOwner ? 'salon_1' : null,
      );
      
      await LocalDataService.saveUser(user);
      return user;
    } else {
      return SupabaseService.signup(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );
    }
  }

  static Future<void> forgotPassword(String email) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      // Simulate password reset - in real app would send email
    } else {
      await SupabaseService.forgotPassword(email);
    }
  }

  static Future<UserModel> updateProfile(UserModel user) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      
      final updatedUser = user.copyWith(updatedAt: DateTime.now());
      await LocalDataService.saveUser(updatedUser);
      return updatedUser;
    } else {
      return SupabaseService.updateProfile(user);
    }
  }


  // Salon operations
  static Future<List<SalonModel>> getSalons() async {
    if (useLocal) {
      await _simulateNetworkDelay();
      return await LocalDataService.getAllSalons();
    } else {
      return SupabaseService.getSalons();
    }
  }

  static Future<SalonModel> getSalonById(String id) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      final salon = await LocalDataService.getSalon(id);
      if (salon == null) throw Exception('Salon not found');
      return salon;
    } else {
      final salon = await SupabaseService.getSalonById(id);
      
      // Calculate actual rating from reviews
      try {
        final reviews = await SupabaseService.getReviewsForSalon(id);
        if (reviews.isNotEmpty) {
          final totalRating = reviews.fold<int>(0, (sum, review) => sum + review.rating);
          final actualRating = totalRating / reviews.length;
          
          // Return salon with updated rating
          return salon.copyWith(
            rating: actualRating,
            reviewCount: reviews.length,
          );
        }
      } catch (e) {
        print('Error calculating salon rating: $e');
      }
      
      return salon;
    }
  }

  static Future<SalonModel?> getSalonByOwnerId(String ownerId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      // For local mode, return a mock salon
      return SalonModel(
        id: 'salon_1',
        ownerId: ownerId,
        name: 'Elite Hair Studio',
        description: 'Premium salon services',
        address: '123 Main St',
        phone: '+1234567890',
        email: 'info@elitehair.com',
        imageUrls: ['https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400'],
        rating: 4.8,
        reviewCount: 150,
        categories: ['Haircut', 'Styling'],
        openingHours: {'Monday': '9:00-18:00'},
        latitude: 0.0,
        longitude: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else {
      return SupabaseService.getSalonByOwnerId(ownerId);
    }
  }

  static Future<SalonModel> createSalonForOwner(String ownerId, {
    required String name,
    required String description,
    required String address,
    String? phone,
    String? email,
  }) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      // For local mode, return a mock salon
      return SalonModel(
        id: const Uuid().v4(),
        ownerId: ownerId,
        name: name,
        description: description,
        address: address,
        phone: phone ?? '',
        email: email ?? '',
        imageUrls: [],
        rating: 0.0,
        reviewCount: 0,
        categories: ['Haircut'],
        openingHours: {'Monday': '9:00-18:00'},
        latitude: 0.0,
        longitude: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else {
      return SupabaseService.createSalonForOwner(
        ownerId,
        name: name,
        description: description,
        address: address,
        phone: phone,
        email: email,
      );
    }
  }

  // Service operations
  static Future<List<ServiceModel>> getServices() async {
    if (useLocal) {
      await _simulateNetworkDelay();
      return await LocalDataService.getAllServices();
    } else {
      // Get all services from all salons
      final salons = await SupabaseService.getSalons();
      List<ServiceModel> allServices = [];
      for (final salon in salons) {
        final services = await SupabaseService.getServicesBySalon(salon.id);
        allServices.addAll(services);
      }
      return allServices;
    }
  }

  static Future<List<ServiceModel>> getServicesBySalon(String salonId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      return await LocalDataService.getServicesBySalon(salonId);
    } else {
      return SupabaseService.getServicesBySalon(salonId);
    }
  }

  static Future<List<ServiceModel>> getServicesBySalonOwner(String ownerId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      return await LocalDataService.getServicesBySalon('salon_1'); // Mock salon ID
    } else {
      return SupabaseService.getServicesBySalonOwner(ownerId);
    }
  }

  static Future<ServiceModel> addService(ServiceModel service) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      final serviceId = await LocalDataService.saveService(service);
      final savedService = await LocalDataService.getService(serviceId);
      if (savedService == null) throw Exception('Failed to save service');
      
      // Emit realtime update
      await _realtimeService.emitServiceUpdated(savedService);
      
      return savedService;
    } else {
      return SupabaseService.createService(service);
    }
  }

  static Future<ServiceModel> updateService(ServiceModel service) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      final serviceId = await LocalDataService.saveService(service);
      final updatedService = await LocalDataService.getService(serviceId);
      if (updatedService == null) throw Exception('Failed to update service');
      
      // Emit realtime update
      await _realtimeService.emitServiceUpdated(updatedService);
      
      return updatedService;
    } else {
      return SupabaseService.updateService(service);
    }
  }

  static Future<ServiceModel> getServiceById(String serviceId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      final service = await LocalDataService.getService(serviceId);
      if (service == null) throw Exception('Service not found');
      return service;
    } else {
      return SupabaseService.getServiceById(serviceId);
    }
  }

  static Future<void> deleteService(String serviceId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      await LocalDataService.deleteService(serviceId);
      
      // Emit realtime update
      await _realtimeService.emitServiceDeleted(serviceId);
    } else {
      await SupabaseService.deleteService(serviceId);
    }
  }

  // Image upload methods
  static Future<String> uploadServiceImage(String userId, Uint8List imageBytes, String fileName) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      // For local mode, return a mock URL
      return 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400';
    } else {
      return SupabaseService.uploadServiceImage(userId, imageBytes, fileName);
    }
  }

  static Future<String> uploadProfileImage(String userId, Uint8List imageBytes, String fileName) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      // For local mode, return a mock URL
      return 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400';
    } else {
      return SupabaseService.uploadProfileImage(userId, imageBytes, fileName);
    }
  }

  // Appointment operations
  static Future<List<AppointmentModel>> getAppointments() async {
    if (useLocal) {
      await _simulateNetworkDelay();
      return await LocalDataService.getAllAppointments();
    } else {
      // Get appointments for current user
      final user = _supabase.auth.currentUser;
      if (user == null) return [];
      
      // Get appointments where user is customer or salon owner
      final customerAppointments = await SupabaseService.getCustomerAppointments(user.id);
      final salons = await SupabaseService.getSalons();
      final userSalons = salons.where((s) => s.ownerId == user.id).toList();
      
      List<AppointmentModel> allAppointments = [...customerAppointments];
      for (final salon in userSalons) {
        final salonAppointments = await SupabaseService.getSalonAppointments(salon.id);
        allAppointments.addAll(salonAppointments);
      }
      
      // Remove duplicates
      final uniqueAppointments = <String, AppointmentModel>{};
      for (final appointment in allAppointments) {
        uniqueAppointments[appointment.id] = appointment;
      }
      
      return uniqueAppointments.values.toList();
    }
  }

  static Future<List<AppointmentModel>> getAppointmentsByCustomer(String customerId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      return await LocalDataService.getAppointmentsByCustomer(customerId);
    } else {
      return SupabaseService.getCustomerAppointments(customerId);
    }
  }

  static Future<List<AppointmentModel>> getAppointmentsBySalon(String salonId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      return await LocalDataService.getAppointmentsBySalon(salonId);
    } else {
      return SupabaseService.getSalonAppointments(salonId);
    }
  }

  static Future<AppointmentModel> createAppointment(AppointmentModel appointment) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      
      // Check for conflicts
      await _checkAppointmentConflicts(appointment);
      
      final appointmentId = await LocalDataService.saveAppointment(appointment);
      final savedAppointment = await LocalDataService.getAppointment(appointmentId);
      if (savedAppointment == null) throw Exception('Failed to create appointment');
      
      // Emit realtime update
      await _realtimeService.emitAppointmentUpdated(savedAppointment);
      
      return savedAppointment;
    } else {
      return SupabaseService.createAppointmentWithConflictCheck(
        customerId: appointment.customerId,
        salonId: appointment.salonId,
        serviceId: appointment.serviceId,
        startAt: appointment.startAt,
        staffId: appointment.staffId,
        notes: appointment.notes,
      );
    }
  }

  static Future<AppointmentModel> updateAppointmentStatus(
    String appointmentId, 
    AppointmentStatus status
  ) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      await LocalDataService.updateAppointmentStatus(appointmentId, status);
      final updatedAppointment = await LocalDataService.getAppointment(appointmentId);
      if (updatedAppointment == null) throw Exception('Appointment not found');
      
      // Emit realtime update
      await _realtimeService.emitAppointmentUpdated(updatedAppointment);
      
      return updatedAppointment;
    } else {
      return SupabaseService.updateAppointmentStatus(appointmentId, status);
    }
  }

  static Future<void> cancelAppointment(String appointmentId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      await LocalDataService.updateAppointmentStatus(appointmentId, AppointmentStatus.cancelled);
      final cancelledAppointment = await LocalDataService.getAppointment(appointmentId);
      if (cancelledAppointment != null) {
        await _realtimeService.emitAppointmentUpdated(cancelledAppointment);
      }
    } else {
      await SupabaseService.updateAppointmentStatus(appointmentId, AppointmentStatus.cancelled);
    }
  }

  static Future<void> deleteAppointment(String appointmentId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      await LocalDataService.deleteAppointment(appointmentId);
      
      // Emit realtime update
      await _realtimeService.emitAppointmentDeleted(appointmentId);
    } else {
      await SupabaseService.updateAppointmentStatus(appointmentId, AppointmentStatus.cancelled);
    }
  }

  // Message operations
  static Future<List<MessageModel>> getMessagesByThread(String threadId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      return await LocalDataService.getMessagesByThread(threadId);
    } else {
      return SupabaseService.getMessagesByThread(threadId);
    }
  }

  static Future<List<MessageModel>> getMessagesByUser(String userId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      return await LocalDataService.getMessagesByUser(userId);
    } else {
      // Get messages where user is sender or receiver
      final user = _supabase.auth.currentUser;
      if (user == null) return [];
      
      // Get all messages for the current user
      final messages = await SupabaseService.getMessagesByThread(user.id);
      return messages;
    }
  }

  static Future<List<MessageModel>> getAllMessages() async {
    if (useLocal) {
      await _simulateNetworkDelay();
      return await LocalDataService.getAllMessages();
    } else {
      // Get all messages for current user
      final user = _supabase.auth.currentUser;
      if (user == null) return [];
      
      return await SupabaseService.getMessagesByThread(user.id);
    }
  }

  static Future<MessageModel> sendMessage(MessageModel message) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      
      // Set sending status initially
      final sendingMessage = message.copyWith(status: MessageStatus.sending);
      final messageId = await LocalDataService.saveMessage(sendingMessage);
      final savedMessage = await LocalDataService.getMessage(messageId);
      if (savedMessage == null) throw Exception('Failed to send message');
      
      // Emit realtime update
      await _realtimeService.emitMessageUpdated(savedMessage);
      
      // Simulate message being sent
      await Future.delayed(const Duration(milliseconds: 500));
      final sentMessage = savedMessage.copyWith(status: MessageStatus.sent);
      await LocalDataService.saveMessage(sentMessage);
      await _realtimeService.emitMessageUpdated(sentMessage);
      
      return sentMessage;
    } else {
      return SupabaseService.sendMessage(
        threadId: message.threadId,
        senderId: message.senderId,
        receiverId: message.receiverId,
        text: message.text,
        attachments: message.attachments,
      );
    }
  }

  // Enhanced chat functionality
  static Future<String> getOrCreateThread(String user1Id, String user2Id) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      // Create a mock thread ID for local mode
      final sortedIds = [user1Id, user2Id]..sort();
      return 'thread_${sortedIds[0]}_${sortedIds[1]}';
    } else {
      return SupabaseService.getOrCreateThread(user1Id, user2Id);
    }
  }

  static Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      // Mock online status update
      print('📡 Mock: User $userId is ${isOnline ? 'online' : 'offline'}');
    } else {
      await SupabaseService.updateOnlineStatus(userId, isOnline);
    }
  }

  static Future<Map<String, dynamic>> getOnlineStatus(String userId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      return {
        'is_online': true,
        'last_seen': DateTime.now().toIso8601String(),
        'status_message': 'Online',
      };
    } else {
      return SupabaseService.getOnlineStatus(userId);
    }
  }

  static Future<void> startTyping(String threadId, String userId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      print('⌨️ Mock: User $userId started typing in thread $threadId');
    } else {
      await SupabaseService.startTyping(threadId, userId);
    }
  }

  static Future<void> stopTyping(String threadId, String userId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      print('⌨️ Mock: User $userId stopped typing in thread $threadId');
    } else {
      await SupabaseService.stopTyping(threadId, userId);
    }
  }

  static Stream<List<Map<String, dynamic>>> getTypingIndicators(String threadId) {
    if (useLocal) {
      // Return empty stream for local mode
      return Stream.value([]);
    } else {
      return SupabaseService.getTypingIndicators(threadId);
    }
  }

  static Future<void> markMessagesAsRead(String threadId, String userId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      // Mock marking messages as read
      print('✅ Mock: Marked messages as read for thread $threadId, user $userId');
    } else {
      await SupabaseService.markMessagesAsRead(threadId, userId);
    }
  }

  static Future<int> getUnreadMessageCount(String userId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      // Return mock unread count
      return 0;
    } else {
      return SupabaseService.getUnreadMessageCount(userId);
    }
  }

  static Future<List<Map<String, dynamic>>> getChatThreads(String userId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      // Return mock chat threads
      return [
        {
          'id': 'thread_1',
          'thread_id': 'thread_1',
          'participant_1': {'id': 'customer_1', 'full_name': 'John Doe', 'avatar_url': null},
          'participant_2': {'id': 'owner_1', 'full_name': 'Salon Owner', 'avatar_url': null},
          'last_message': {'text': 'Thank you for the great service!', 'created_at': DateTime.now().toIso8601String()},
          'last_message_at': DateTime.now().toIso8601String(),
        }
      ];
    } else {
      return SupabaseService.getChatThreads(userId);
    }
  }

  // Add missing methods for chat functionality
  static Future<SalonModel?> getSalonByOwner(String ownerId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      // Return mock salon for local mode
      return SalonModel(
        id: 'mock_salon_1',
        ownerId: ownerId,
        name: 'Mock Salon',
        description: 'A mock salon for testing',
        address: '123 Mock Street',
        phone: '123-456-7890',
        email: 'mock@salon.com',
        imageUrls: [],
        rating: 4.5,
        reviewCount: 10,
        categories: ['Haircut'],
        openingHours: {'Monday': '9:00-18:00'},
        latitude: 0.0,
        longitude: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else {
      return SupabaseService.getSalonByOwnerId(ownerId);
    }
  }

  static Future<UserModel> getUserProfile(String userId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      // Return mock user profile
      return UserModel(
        id: userId,
        email: 'mock@user.com',
        fullName: 'Mock User',
        phone: '123-456-7890',
        role: UserRole.customer,
        profileImageUrl: null,
        isEmailVerified: true,
        isPhoneVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } else {
      return SupabaseService.getUserProfile(userId);
    }
  }

  static Future<List<Map<String, dynamic>>> getCustomers() async {
    if (useLocal) {
      await _simulateNetworkDelay();
      // Return mock customers for local mode
      return [
        {
          'id': 'customer_1',
          'name': 'John Doe',
          'email': 'john@example.com',
          'avatar_url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
          'last_visit': '2024-01-15',
        },
        {
          'id': 'customer_2',
          'name': 'Jane Smith',
          'email': 'jane@example.com',
          'avatar_url': 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100',
          'last_visit': '2024-01-14',
        },
      ];
    } else {
      return SupabaseService.getCustomers();
    }
  }

  static Future<void> markMessageAsRead(String messageId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      await LocalDataService.updateMessageStatus(messageId, MessageStatus.read);
      final message = await LocalDataService.getMessage(messageId);
      if (message != null) {
        await _realtimeService.emitMessageUpdated(message);
      }
    } else {
      // Messages are automatically marked as read in Supabase
      // No need for explicit marking
    }
  }

  // Notification operations
  static Future<List<NotificationModel>> getNotificationsByUser(String userId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      return await LocalDataService.getNotificationsByUser(userId);
    } else {
      return SupabaseService.getNotificationsByUser(userId);
    }
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      await LocalDataService.markNotificationAsRead(notificationId);
    } else {
      await SupabaseService.markNotificationAsRead(notificationId);
    }
  }

  static Future<void> deleteNotification(String notificationId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      await LocalDataService.deleteNotification(notificationId);
    } else {
      await SupabaseService.markNotificationAsRead(notificationId);
    }
  }

  // AI Suggestions
  static Future<List<AISuggestionModel>> getAISuggestions(String userId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      return await LocalDataService.getAISuggestionsByUser(userId);
    } else {
      return SupabaseService.getAISuggestionsByUser(userId);
    }
  }

  static Future<List<AISuggestionModel>> generateAISuggestions(String userId, File imageFile) async {
    if (isMockMode) {
      await _simulateNetworkDelay();
      await Future.delayed(const Duration(seconds: 3));
      final suggestions = _mockAISuggestions.where((suggestion) => suggestion.userId == userId).toList();
      return suggestions;
    }
    
    if (useLocal) {
      try {
        final apiKey = dotenv.env['GEMINI_API_KEY'];
        if (apiKey == null || apiKey.isEmpty) {
          throw Exception('Gemini API key not found in environment variables');
        }
        final imageBytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        final requestBody = {
          "contents": [
            {
              "parts": [
                {
                  "text": "Analyze this face image and suggest 3-5 different hairstyles that would suit this person. Consider face shape, hair texture, and personal style. For each suggestion, provide: 1) Hairstyle name, 2) Description, 3) Why it suits them, 4) Confidence score (0-1), 5) Haircut type (short, medium, long), 6) Style category (classic, modern, trendy, casual). Return the response in JSON format with an array of suggestions."
                },
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.7,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 2048,
          }
        };
        final response = await http.post(
          Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        );
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final content = responseData['candidates'][0]['content']['parts'][0]['text'];
          final suggestions = _parseGeminiResponse(content, userId);
          return suggestions;
        } else {
          throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        print('Gemini API error: $e');
        await _simulateNetworkDelay();
        return _mockAISuggestions.where((suggestion) => suggestion.userId == userId).toList();
      }
    } else {
      // Upload image to Supabase storage first
      final imageUrl = await SupabaseService.uploadAIImage(userId, imageFile);
      
      // Generate AI suggestions using the uploaded image
      return await SupabaseService.generateAISuggestions(
        userId: userId,
        imageUrl: imageUrl,
      );
    }
  }

  // Realtime streams
  static Stream<List<ServiceModel>> get servicesStream {
    if (useLocal) {
      return _realtimeService.servicesStream.map((service) => [service]);
    } else {
      return SupabaseService.servicesStream;
    }
  }
  
  static Stream<List<AppointmentModel>> get appointmentsStream {
    if (useLocal) {
      return _realtimeService.appointmentsStream.map((appointment) => [appointment]);
    } else {
      return SupabaseService.appointmentsStream;
    }
  }
  
  static Stream<List<MessageModel>> get messagesStream {
    if (useLocal) {
      return _realtimeService.messagesStream.map((message) => [message]);
    } else {
      return SupabaseService.messagesStream;
    }
  }
  
  static Stream<List<NotificationModel>> get notificationsStream {
    if (useLocal) {
      return _realtimeService.notificationsStream.map((notification) => [notification]);
    } else {
      return SupabaseService.notificationsStream;
    }
  }

  // Utility methods
  static Future<void> _simulateNetworkDelay() async {
    if (_simulateRealtime) {
      final delay = 200 + (Random().nextInt(300));
      await Future.delayed(Duration(milliseconds: delay));
    }
  }

  static Future<void> _checkAppointmentConflicts(AppointmentModel appointment) async {
    final existingAppointments = await LocalDataService.getAppointmentsBySalon(appointment.salonId);
    final service = await LocalDataService.getService(appointment.serviceId);
    
    if (service == null) {
      throw Exception('Service not found');
    }
    
    for (final existing in existingAppointments) {
      if (existing.id == appointment.id) continue; // Skip self
      if (existing.status == AppointmentStatus.cancelled) continue;
      
      // Check for overlap using startAt and endAt
      if (appointment.startAt.isBefore(existing.endAt) && appointment.endAt.isAfter(existing.startAt)) {
        throw Exception('Time slot conflict. Please choose a different time.');
      }
    }
  }

  // Mock data and helper methods (keep existing)
  static final List<AISuggestionModel> _mockAISuggestions = [
    AISuggestionModel(
      id: 'suggestion_1',
      userId: 'customer_1',
      name: 'Classic Side Part',
      description: 'A timeless, professional look that works for any occasion.',
      imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400',
      confidenceScore: 0.92,
      type: SuggestionType.hairstyle,
      isBooked: false,
      createdAt: DateTime.now(),
      tags: ['professional', 'classic', 'versatile'],
      styleDetails: {
        'reasoning': 'Your face shape and hair texture are perfect for this classic style',
        'haircutType': 'short',
      },
    ),
    AISuggestionModel(
      id: 'suggestion_2',
      userId: 'customer_1',
      name: 'Modern Fade',
      description: 'A contemporary fade that adds edge to your look.',
      imageUrl: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=400',
      confidenceScore: 0.88,
      type: SuggestionType.hairstyle,
      isBooked: false,
      createdAt: DateTime.now(),
      tags: ['modern', 'edgy', 'trendy'],
      styleDetails: {
        'reasoning': 'Your facial structure would look great with this modern fade',
        'haircutType': 'short',
      },
    ),
  ];

  static List<AISuggestionModel> _parseGeminiResponse(String content, String userId) {
    try {
      final jsonStart = content.indexOf('[');
      final jsonEnd = content.lastIndexOf(']') + 1;
      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonString = content.substring(jsonStart, jsonEnd);
        final List<dynamic> suggestionsData = jsonDecode(jsonString);
        return suggestionsData.map((data) {
          return AISuggestionModel(
            id: const Uuid().v4(),
            userId: userId,
            name: data['name'] ?? 'AI Suggested Hairstyle',
            description: data['description'] ?? 'AI generated hairstyle suggestion',
            imageUrl: data['imageUrl'] ?? 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400',
            confidenceScore: (data['confidence'] ?? 0.8).toDouble(),
            type: _parseSuggestionType(data['category'] ?? 'hairstyle'),
            isBooked: false,
            createdAt: DateTime.now(),
            tags: _parseTags(data),
            styleDetails: {
              'reasoning': data['why'] ?? 'AI analysis suggests this style suits your features',
              'haircutType': data['haircutType'] ?? 'medium',
            },
          );
        }).toList();
      }
    } catch (e) {
      print('Error parsing Gemini response: $e');
    }
    return _mockAISuggestions.where((suggestion) => suggestion.userId == userId).toList();
  }

  static SuggestionType _parseSuggestionType(String category) {
    switch (category.toLowerCase()) {
      case 'hairstyle':
        return SuggestionType.hairstyle;
      case 'color':
        return SuggestionType.color;
      case 'treatment':
        return SuggestionType.treatment;
      case 'accessory':
        return SuggestionType.accessory;
      default:
        return SuggestionType.hairstyle;
    }
  }

  static List<String> _parseTags(Map<String, dynamic> data) {
    final tags = <String>[];
    if (data['tags'] != null) {
      tags.addAll((data['tags'] as List).cast<String>());
    }
    if (data['category'] != null) {
      tags.add(data['category']);
    }
    return tags;
  }

  // ==================== REVIEW METHODS ====================
  
  static Future<List<ReviewModel>> getReviewsForSalon(String salonId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      return _mockReviews.where((review) => review.salonId == salonId).toList();
    } else {
      return await SupabaseService.getReviewsForSalon(salonId);
    }
  }

  static Future<List<ReviewModel>> getReviewsForCustomer(String customerId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      return _mockReviews.where((review) => review.customerId == customerId).toList();
    } else {
      return await SupabaseService.getReviewsForCustomer(customerId);
    }
  }

  static Future<String?> createReview({
    required String customerId,
    required String salonId,
    String? appointmentId,
    required int rating,
    required String comment,
    List<String> images = const [],
  }) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      
      // Check if customer has already reviewed this salon
      final existingReview = _mockReviews.any((review) => 
          review.customerId == customerId && review.salonId == salonId);
      
      if (existingReview) {
        throw Exception('You have already reviewed this salon');
      }
      
      final newReview = ReviewModel(
        id: const Uuid().v4(),
        customerId: customerId,
        salonId: salonId,
        appointmentId: appointmentId,
        rating: rating,
        comment: comment,
        images: images,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        customerName: 'Customer ${customerId.substring(0, 8)}',
        customerAvatar: null,
      );
      
      _mockReviews.add(newReview);
      return newReview.id;
    } else {
      return await SupabaseService.createReview(
        customerId: customerId,
        salonId: salonId,
        appointmentId: appointmentId,
        rating: rating,
        comment: comment,
        images: images,
      );
    }
  }

  static Future<void> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
    List<String> images = const [],
  }) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      
      final index = _mockReviews.indexWhere((review) => review.id == reviewId);
      if (index != -1) {
        _mockReviews[index] = _mockReviews[index].copyWith(
          rating: rating,
          comment: comment,
          images: images,
          updatedAt: DateTime.now(),
        );
      }
    } else {
      await SupabaseService.updateReview(
        reviewId: reviewId,
        rating: rating,
        comment: comment,
        images: images,
      );
    }
  }

  static Future<void> deleteReview(String reviewId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      _mockReviews.removeWhere((review) => review.id == reviewId);
    } else {
      await SupabaseService.deleteReview(reviewId);
    }
  }

  static Future<ReviewStats> getReviewStats(String salonId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      
      final salonReviews = _mockReviews.where((review) => review.salonId == salonId).toList();
      
      if (salonReviews.isEmpty) {
        return const ReviewStats(
          averageRating: 0.0,
          totalReviews: 0,
          ratingDistribution: {},
        );
      }
      
      final ratings = salonReviews.map((review) => review.rating).toList();
      final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
      
      final ratingDistribution = <int, int>{};
      for (final rating in ratings) {
        ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
      }
      
      return ReviewStats(
        averageRating: averageRating,
        totalReviews: ratings.length,
        ratingDistribution: ratingDistribution,
      );
    } else {
      return await SupabaseService.getReviewStats(salonId);
    }
  }

  static Future<bool> canCustomerReviewSalon(String customerId, String salonId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      
      // Check if customer has already reviewed this salon
      final existingReview = _mockReviews.any((review) => 
          review.customerId == customerId && review.salonId == salonId);
      
      if (existingReview) {
        return false;
      }
      
      // Check if customer has completed appointments with this salon
      final completedAppointments = _mockAppointments.where((appointment) => 
          appointment.customerId == customerId && 
          appointment.salonId == salonId && 
          appointment.status == AppointmentStatus.completed).toList();
      
      return completedAppointments.isNotEmpty;
    } else {
      return await SupabaseService.canCustomerReviewSalon(customerId, salonId);
    }
  }

  static Future<void> fixSalonRating(String salonId) async {
    if (useLocal) {
      await _simulateNetworkDelay();
      // For local mode, no need to fix since mock data is consistent
    } else {
      return await SupabaseService.fixSalonRating(salonId);
    }
  }

  // Mock data for appointments
  static final List<AppointmentModel> _mockAppointments = [
    AppointmentModel(
      id: 'appointment_1',
      customerId: 'customer_1',
      salonId: 'salon_1',
      serviceId: 'service_1',
      startAt: DateTime.now().subtract(const Duration(days: 2)),
      endAt: DateTime.now().subtract(const Duration(days: 2)).add(const Duration(hours: 1)),
      status: AppointmentStatus.completed,
      paymentStatus: PaymentStatus.paid,
      totalAmount: 50.0,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    AppointmentModel(
      id: 'appointment_2',
      customerId: 'customer_2',
      salonId: 'salon_1',
      serviceId: 'service_2',
      startAt: DateTime.now().subtract(const Duration(days: 5)),
      endAt: DateTime.now().subtract(const Duration(days: 5)).add(const Duration(hours: 1)),
      status: AppointmentStatus.completed,
      paymentStatus: PaymentStatus.paid,
      totalAmount: 75.0,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  // Mock data for reviews
  static final List<ReviewModel> _mockReviews = [
    ReviewModel(
      id: 'review_1',
      customerId: 'customer_1',
      salonId: 'salon_1',
      appointmentId: 'appointment_1',
      rating: 5,
      comment: 'Amazing service! The staff was very professional and the haircut exceeded my expectations.',
      images: [],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      customerName: 'John Doe',
      customerAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
    ),
    ReviewModel(
      id: 'review_2',
      customerId: 'customer_2',
      salonId: 'salon_1',
      appointmentId: 'appointment_2',
      rating: 4,
      comment: 'Good experience overall. The salon is clean and the stylist was friendly.',
      images: [],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      customerName: 'Jane Smith',
      customerAvatar: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=400',
    ),
    ReviewModel(
      id: 'review_3',
      customerId: 'customer_3',
      salonId: 'salon_1',
      appointmentId: 'appointment_3',
      rating: 5,
      comment: 'Perfect haircut! I will definitely come back again. Highly recommended!',
      images: [],
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      customerName: 'Mike Johnson',
      customerAvatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400',
    ),
  ];

}