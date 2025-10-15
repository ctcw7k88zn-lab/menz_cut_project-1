import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/salon_model.dart';
import '../models/service_model.dart';
import '../models/appointment_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../models/ai_suggestion_model.dart';

/// Supabase service that handles all backend operations
class SupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Authentication methods
  static Future<UserModel> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
  }) async {
    try {
      print('Starting signup for: $email');
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': _convertRoleToDbString(role),
        },
        emailRedirectTo: null, // Disable email confirmation for local dev
      );
      
      print('Supabase signup response: ${response.user?.id}');
      print('Supabase signup session: ${response.session?.accessToken}');
      
      if (response.user == null) {
        throw Exception('Signup failed - no user returned from Supabase');
      }
      
      // Try to create profile immediately
      try {
        print('Creating profile for user: ${response.user!.id}');
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'phone': phone,
          'role': _convertRoleToDbString(role),
          'is_email_verified': false,
          'is_phone_verified': false,
        });
        print('Profile created successfully');
      } catch (profileError) {
        print('Profile creation failed: $profileError');
        // Continue anyway - the user is created in auth.users
      }
      
      // Return a basic user model
      return UserModel(
        id: response.user!.id,
        email: email,
        fullName: fullName,
        phone: phone,
        role: role,
        profileImageUrl: null,
        isEmailVerified: false,
        isPhoneVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Signup error: $e');
      throw Exception('Signup failed: ${e.toString()}');
    }
  }

  static Future<UserModel> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }
      return await _getUserProfile(user.id);
    } catch (e) {
      throw Exception('Failed to get current user: ${e.toString()}');
    }
  }

  static Future<UserModel> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Login failed');
      }
      
      return await _getUserProfile(response.user!.id);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  static Future<void> forgotPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  static Future<UserModel> updateProfile(UserModel user) async {
    await _supabase.from('profiles').update({
      'full_name': user.fullName,
      'phone': user.phone,
      'avatar_url': user.profileImageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);
    
    return await _getUserProfile(user.id);
  }

  // Salon operations
  static Future<List<SalonModel>> getSalons({
    String? city,
    String? category,
    double? minRating,
    double? maxPrice,
  }) async {
    try {
      var query = _supabase.from('salons').select('*').eq('is_active', true);
      
      if (city != null) {
        query = query.eq('city', city);
      }
      
      final response = await query;
      return response.map((data) => _salonFromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch salons: ${e.toString()}');
    }
  }

  static Future<SalonModel> getSalon(String id) async {
    try {
      final response = await _supabase
          .from('salons')
          .select('*')
          .eq('id', id)
          .single();
      
      return _salonFromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch salon: ${e.toString()}');
    }
  }

  static Future<SalonModel> createSalon(SalonModel salon) async {
    try {
      final response = await _supabase
          .from('salons')
          .insert({
            'owner_id': salon.ownerId,
            'name': salon.name,
            'description': salon.description,
            'address': salon.address,
            'city': salon.address, // Using address as city for now
            'phone': salon.phone,
            'email': salon.email,
            'logo_url': salon.imageUrls.isNotEmpty ? salon.imageUrls.first : null,
            'banner_url': salon.imageUrls.length > 1 ? salon.imageUrls[1] : null,
            'is_active': true,
            'latitude': salon.latitude,
            'longitude': salon.longitude,
          })
          .select()
          .single();
      
      return _salonFromMap(response);
    } catch (e) {
      throw Exception('Failed to create salon: ${e.toString()}');
    }
  }

  static Future<SalonModel> updateSalon(SalonModel salon) async {
    try {
      final response = await _supabase
          .from('salons')
          .update({
            'name': salon.name,
            'description': salon.description,
            'address': salon.address,
            'phone': salon.phone,
            'email': salon.email,
            'logo_url': salon.imageUrls.isNotEmpty ? salon.imageUrls.first : null,
            'banner_url': salon.imageUrls.length > 1 ? salon.imageUrls[1] : null,
            'latitude': salon.latitude,
            'longitude': salon.longitude,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', salon.id)
          .select()
          .single();
      
      return _salonFromMap(response);
    } catch (e) {
      throw Exception('Failed to update salon: ${e.toString()}');
    }
  }

  // Service operations
  static Future<List<ServiceModel>> getServicesBySalon(String salonId) async {
    try {
      final response = await _supabase
          .from('services')
          .select('*')
          .eq('salon_id', salonId)
          .eq('is_active', true);
      
      return response.map((data) => _serviceFromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch services: ${e.toString()}');
    }
  }

  static Future<ServiceModel> createService(ServiceModel service) async {
    try {
      final response = await _supabase
          .from('services')
          .insert({
            'salon_id': service.salonId,
            'name': service.name,
            'description': service.description,
            'price': service.price,
            'duration_minutes': service.durationMinutes,
            'category': service.category,
            'image_url': service.imageUrl,
            'is_active': true,
          })
          .select()
          .single();
      
      return _serviceFromMap(response);
    } catch (e) {
      throw Exception('Failed to create service: ${e.toString()}');
    }
  }

  static Future<ServiceModel> updateService(ServiceModel service) async {
    try {
      final response = await _supabase
          .from('services')
          .update({
            'name': service.name,
            'description': service.description,
            'price': service.price,
            'duration_minutes': service.durationMinutes,
            'category': service.category,
            'image_url': service.imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', service.id)
          .select()
          .single();
      
      return _serviceFromMap(response);
    } catch (e) {
      throw Exception('Failed to update service: ${e.toString()}');
    }
  }

  static Future<void> deleteService(String serviceId) async {
    try {
      await _supabase
          .from('services')
          .update({'is_active': false})
          .eq('id', serviceId);
    } catch (e) {
      throw Exception('Failed to delete service: ${e.toString()}');
    }
  }

  // Appointment operations
  static Future<List<AppointmentModel>> getAppointmentsByCustomer(String customerId) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('*')
          .eq('customer_id', customerId)
          .order('start_at', ascending: false);
      
      return response.map((data) => _appointmentFromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch customer appointments: ${e.toString()}');
    }
  }

  static Future<List<AppointmentModel>> getAppointmentsBySalon(String salonId) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('*')
          .eq('salon_id', salonId)
          .order('start_at', ascending: false);
      
      return response.map((data) => _appointmentFromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch salon appointments: ${e.toString()}');
    }
  }

  static Future<AppointmentModel> createAppointment(AppointmentModel appointment) async {
    try {
      final response = await _supabase
          .from('appointments')
          .insert({
            'customer_id': appointment.customerId,
            'salon_id': appointment.salonId,
            'service_id': appointment.serviceId,
            'staff_id': appointment.staffId,
            'start_at': appointment.startAt.toIso8601String(),
            'end_at': appointment.endAt.toIso8601String(),
            'status': appointment.status.name,
            'notes': appointment.notes,
            'total_price': appointment.totalAmount,
            'payment_status': appointment.paymentStatus.name,
          })
          .select()
          .single();
      
      return _appointmentFromMap(response);
    } catch (e) {
      throw Exception('Failed to create appointment: ${e.toString()}');
    }
  }

  static Future<AppointmentModel> updateAppointmentStatus(String appointmentId, AppointmentStatus status) async {
    try {
      final response = await _supabase
          .from('appointments')
          .update({
            'status': status.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', appointmentId)
          .select()
          .single();
      
      return _appointmentFromMap(response);
    } catch (e) {
      throw Exception('Failed to update appointment: ${e.toString()}');
    }
  }

  // Message operations
  static Future<List<MessageModel>> getMessagesByThread(String threadId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('thread_id', threadId)
          .order('created_at', ascending: true);
      
      return response.map((data) => _messageFromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch messages: ${e.toString()}');
    }
  }

  static Future<MessageModel> sendMessage({
    required String threadId,
    required String senderId,
    required String receiverId,
    required String text,
    List<String>? attachments,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .insert({
            'thread_id': threadId,
            'sender_id': senderId,
            'receiver_id': receiverId,
            'text': text,
            'attachments': attachments ?? [],
            'status': 'sent',
            'is_read': false,
          })
          .select()
          .single();
      
      return _messageFromMap(response);
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  // Notification operations
  static Future<List<NotificationModel>> getNotificationsByUser(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return response.map((data) => _notificationFromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: ${e.toString()}');
    }
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: ${e.toString()}');
    }
  }

  // AI Suggestions operations
  static Future<List<AISuggestionModel>> getAISuggestionsByUser(String userId) async {
    try {
      final response = await _supabase
          .from('ai_suggestions')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return response.map((data) => _aiSuggestionFromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch AI suggestions: ${e.toString()}');
    }
  }

  static Future<List<AISuggestionModel>> generateAISuggestions({
    required String userId,
    required String imageUrl,
    SuggestionType? suggestionType,
  }) async {
    try {
      // Call the Edge Function
      final response = await _supabase.functions.invoke(
        'ai_style_suggestion',
        body: {
          'user_id': userId,
          'image_url': imageUrl,
          'suggestion_type': suggestionType?.name ?? 'haircut',
        },
      );

      if (response.data != null && response.data['success'] == true) {
        // Return the suggestions that were saved to the database
        return await getAISuggestionsByUser(userId);
      } else {
        throw Exception('AI suggestion generation failed');
      }
    } catch (e) {
      throw Exception('Failed to generate AI suggestions: ${e.toString()}');
    }
  }

  // Storage operations
  static Future<String> uploadFile(String bucket, String path, File file) async {
    try {
      final bytes = await file.readAsBytes();
      await _supabase.storage.from(bucket).uploadBinary(path, bytes);
      
      return _supabase.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  static Future<String> uploadProfilePicture(String userId, File file) async {
    final path = '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await uploadFile('profile-pics', path, file);
  }

  static Future<String> uploadSalonImage(String salonId, File file) async {
    final path = '$salonId/image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await uploadFile('salon-images', path, file);
  }

  static Future<String> uploadServiceImage(String serviceId, File file) async {
    final path = '$serviceId/image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await uploadFile('service-images', path, file);
  }

  static Future<String> uploadAIImage(String userId, File file) async {
    final path = '$userId/ai_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return await uploadFile('ai-uploads', path, file);
  }

  // Real-time streams
  static Stream<List<ServiceModel>> get servicesStream {
    return _supabase
        .from('services')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .map((data) => data.map((item) => _serviceFromMap(item)).toList());
  }

  static Stream<List<AppointmentModel>> get appointmentsStream {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('appointments')
        .stream(primaryKey: ['id'])
        .eq('customer_id', user.id)
        .map((data) => data.map((item) => _appointmentFromMap(item)).toList());
  }

  static Stream<List<MessageModel>> get messagesStream {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('sender_id', user.id)
        .map((data) => data.map((item) => _messageFromMap(item)).toList());
  }

  static Stream<List<NotificationModel>> get notificationsStream {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .map((data) => data.map((item) => _notificationFromMap(item)).toList());
  }

  // Helper methods
  static Future<UserModel> _getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();
      
      return _userFromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch user profile: ${e.toString()}');
    }
  }

  static UserModel _userFromMap(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'],
      email: data['email'],
      fullName: data['full_name'] ?? '',
      phone: data['phone'] ?? '',
      role: UserRole.values.firstWhere((e) => e.name == data['role']),
      profileImageUrl: data['avatar_url'],
      isEmailVerified: data['is_email_verified'] ?? false,
      isPhoneVerified: data['is_phone_verified'] ?? false,
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  static SalonModel _salonFromMap(Map<String, dynamic> data) {
    return SalonModel(
      id: data['id'],
      ownerId: data['owner_id'],
      name: data['name'],
      description: data['description'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'],
      email: data['email'],
      imageUrls: ([data['logo_url'] ?? '', data['banner_url'] ?? ''] as List<String>).where((url) => url.isNotEmpty).toList(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['review_count'] ?? 0,
      categories: (data['categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['Haircut'],
      openingHours: Map<String, String>.from(data['opening_hours'] ?? {'Monday': '9:00-18:00'}),
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  static ServiceModel _serviceFromMap(Map<String, dynamic> data) {
    return ServiceModel(
      id: data['id'],
      salonId: data['salon_id'],
      name: data['name'],
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      durationMinutes: data['duration_minutes'] ?? 30,
      category: data['category'] ?? 'General',
      imageUrl: data['image_url'],
      isActive: data['is_active'] ?? true,
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  static AppointmentModel _appointmentFromMap(Map<String, dynamic> data) {
    return AppointmentModel(
      id: data['id'],
      customerId: data['customer_id'],
      salonId: data['salon_id'],
      serviceId: data['service_id'],
      staffId: data['staff_id'],
      startAt: DateTime.parse(data['start_at']),
      endAt: DateTime.parse(data['end_at']),
      status: AppointmentStatus.values.firstWhere((e) => e.name == data['status']),
      paymentStatus: PaymentStatus.values.firstWhere((e) => e.name == data['payment_status']),
      notes: data['notes'],
      totalAmount: (data['total_price'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  static MessageModel _messageFromMap(Map<String, dynamic> data) {
    return MessageModel(
      id: data['id'],
      threadId: data['thread_id'],
      senderId: data['sender_id'],
      receiverId: data['receiver_id'],
      text: data['text'],
      attachments: List<String>.from(data['attachments'] ?? []),
      status: MessageStatus.values.firstWhere((e) => e.name == data['status']),
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  static NotificationModel _notificationFromMap(Map<String, dynamic> data) {
    return NotificationModel(
      id: data['id'],
      userId: data['user_id'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.general,
      ),
      title: data['title'],
      message: data['message'],
      data: data['data'] ?? {},
      isRead: data['is_read'] ?? false,
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  static AISuggestionModel _aiSuggestionFromMap(Map<String, dynamic> data) {
    return AISuggestionModel(
      id: data['id'],
      userId: data['user_id'],
      type: SuggestionType.values.firstWhere((e) => e.name == data['suggestion_type']),
      name: data['title'] ?? 'AI Suggestion',
      description: data['description'] ?? '',
      imageUrl: data['image_url'] ?? '',
      confidenceScore: (data['confidence_score'] ?? 0.0).toDouble(),
      tags: List<String>.from(data['tags'] ?? []),
      isBooked: data['is_booked'] ?? false,
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  /// Convert UserRole enum to database string format
  static String _convertRoleToDbString(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'customer';
      case UserRole.salonOwner:
        return 'salon_owner';
      case UserRole.owner:
        return 'salon_owner'; // owner is alias for salon_owner
    }
  }

  // ===== APPOINTMENT MANAGEMENT =====
  
  /// Create a new appointment with conflict checking
  static Future<AppointmentModel> createAppointmentWithConflictCheck({
    required String customerId,
    required String salonId,
    required String serviceId,
    required DateTime startAt,
    String? staffId,
    String? notes,
  }) async {
    try {
      // Get service details to calculate end time
      final service = await _supabase
          .from('services')
          .select('duration_minutes, price')
          .eq('id', serviceId)
          .single();
      
      final duration = service['duration_minutes'] as int;
      final endAt = startAt.add(Duration(minutes: duration));
      
      // Check for conflicts
      final conflicts = await _supabase
          .from('appointments')
          .select('id, start_at, end_at')
          .eq('salon_id', salonId)
          .eq('status', 'confirmed')
          .or('staff_id.eq.$staffId,staff_id.is.null')
          .gte('start_at', startAt.toIso8601String())
          .lt('start_at', endAt.toIso8601String());
      
      if (conflicts.isNotEmpty) {
        throw Exception('Time slot conflict detected. Please choose a different time.');
      }
      
      // Create appointment
      final response = await _supabase
          .from('appointments')
          .insert({
            'customer_id': customerId,
            'salon_id': salonId,
            'service_id': serviceId,
            'staff_id': staffId,
            'start_at': startAt.toIso8601String(),
            'end_at': endAt.toIso8601String(),
            'status': 'pending',
            'notes': notes,
            'total_price': service['price'] ?? 0.0,
            'payment_status': 'pending',
          })
          .select()
          .single();
      
      // Create notification for salon owner
      await createNotification(
        userId: (await _supabase.from('salons').select('owner_id').eq('id', salonId).single())['owner_id'],
        type: NotificationType.newAppointment,
        title: 'New Appointment Request',
        message: 'You have a new appointment request',
        data: {'appointment_id': response['id']},
      );
      
      return _appointmentFromMap(response);
    } catch (e) {
      throw Exception('Failed to create appointment: ${e.toString()}');
    }
  }
  
  /// Update appointment status (confirm, cancel, complete)
  static Future<AppointmentModel> updateAppointmentStatusWithNotification({
    required String appointmentId,
    required AppointmentStatus status,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('appointments')
          .update({
            'status': status.name,
            'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', appointmentId)
          .select()
          .single();
      
      // Create notification for customer
      await createNotification(
        userId: response['customer_id'],
        type: NotificationType.appointmentConfirmed,
        title: 'Appointment ${status.name.capitalize()}',
        message: 'Your appointment has been ${status.name}',
        data: {'appointment_id': appointmentId},
      );
      
      return _appointmentFromMap(response);
    } catch (e) {
      throw Exception('Failed to update appointment: ${e.toString()}');
    }
  }
  
  /// Get appointments for customer
  static Future<List<AppointmentModel>> getCustomerAppointments(String customerId) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('''
            *,
            salon:salons(name, address, phone),
            service:services(name, price, duration_minutes)
          ''')
          .eq('customer_id', customerId)
          .order('start_at', ascending: false);
      
      return response.map((data) => _appointmentFromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch customer appointments: ${e.toString()}');
    }
  }
  
  /// Get appointments for salon
  static Future<List<AppointmentModel>> getSalonAppointments(String salonId) async {
    try {
      final response = await _supabase
          .from('appointments')
          .select('''
            *,
            customer:profiles(full_name, phone, email),
            service:services(name, price, duration_minutes)
          ''')
          .eq('salon_id', salonId)
          .order('start_at', ascending: false);
      
      return response.map((data) => _appointmentFromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch salon appointments: ${e.toString()}');
    }
  }
  
  // ===== MESSAGING SYSTEM =====
  
  /// Create a message thread between two users
  static Future<String> createThreadIfNotExists(String userId1, String userId2) async {
    try {
      // Check if thread already exists
      final existingThread = await _supabase
          .from('messages')
          .select('thread_id')
          .or('sender_id.eq.$userId1,receiver_id.eq.$userId1')
          .or('sender_id.eq.$userId2,receiver_id.eq.$userId2')
          .limit(1);
      
      if (existingThread.isNotEmpty) {
        return existingThread.first['thread_id'];
      }
      
      // Create new thread
      final threadId = const Uuid().v4();
      
      // Create initial message to establish thread
      await _supabase
          .from('messages')
          .insert({
            'thread_id': threadId,
            'sender_id': userId1,
            'receiver_id': userId2,
            'text': 'Conversation started',
            'status': 'sent',
            'is_read': true,
          });
      
      return threadId;
    } catch (e) {
      throw Exception('Failed to create thread: ${e.toString()}');
    }
  }
  
  /// Send a message
  static Future<MessageModel> createMessage({
    required String threadId,
    required String senderId,
    required String receiverId,
    required String text,
    List<Map<String, dynamic>>? attachments,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .insert({
            'thread_id': threadId,
            'sender_id': senderId,
            'receiver_id': receiverId,
            'text': text,
            'attachments': attachments ?? [],
            'status': 'sent',
            'is_read': false,
          })
          .select()
          .single();
      
      // Create notification for receiver
      await createNotification(
        userId: receiverId,
        type: NotificationType.newMessage,
        title: 'New Message',
        message: text.length > 50 ? '${text.substring(0, 50)}...' : text,
        data: {'message_id': response['id'], 'thread_id': threadId},
      );
      
      return _messageFromMap(response);
    } catch (e) {
      throw Exception('Failed to create message: ${e.toString()}');
    }
  }
  
  /// Get messages for a thread
  static Future<List<MessageModel>> getMessages(String threadId) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('thread_id', threadId)
          .order('created_at', ascending: true);
      
      return response.map((data) => _messageFromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch messages: ${e.toString()}');
    }
  }
  
  /// Mark messages as read
  static Future<void> markMessagesAsRead(String threadId, String userId) async {
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('thread_id', threadId)
          .eq('receiver_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark messages as read: ${e.toString()}');
    }
  }
  
  // ===== NOTIFICATIONS =====
  
  /// Create a notification
  static Future<NotificationModel> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _supabase
          .from('notifications')
          .insert({
            'user_id': userId,
            'type': type.name,
            'title': title,
            'message': message,
            'data': data ?? {},
            'is_read': false,
          })
          .select()
          .single();
      
      return _notificationFromMap(response);
    } catch (e) {
      throw Exception('Failed to create notification: ${e.toString()}');
    }
  }
  
  /// Get notifications for user
  static Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return response.map((data) => _notificationFromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: ${e.toString()}');
    }
  }
  
  /// Mark notification as read
  static Future<void> markNotificationAsReadById(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: ${e.toString()}');
    }
  }
  
  // ===== AI SUGGESTIONS =====
  
  /// Request AI style suggestions
  static Future<List<AISuggestionModel>> requestAISuggestions({
    required String userId,
    required String imageUrl,
    String? salonId,
    String? serviceId,
  }) async {
    try {
      // Call AI edge function
      final response = await _supabase.functions.invoke(
        'ai_style_suggestion',
        body: {
          'image_url': imageUrl,
          'user_id': userId,
          'salon_id': salonId,
          'service_id': serviceId,
        },
      );
      
      final suggestions = response.data as List;
      final List<AISuggestionModel> aiSuggestions = [];
      
      for (final suggestion in suggestions) {
        // Save suggestion to database
        final dbResponse = await _supabase
            .from('ai_suggestions')
            .insert({
              'user_id': userId,
              'suggestion_type': suggestion['type'],
              'title': suggestion['title'],
              'description': suggestion['description'],
              'content': suggestion,
              'salon_id': salonId,
              'service_id': serviceId,
              'image_url': imageUrl,
              'confidence_score': suggestion['confidence'] ?? 0.0,
              'tags': suggestion['tags'] ?? [],
              'is_booked': false,
            })
            .select()
            .single();
        
        aiSuggestions.add(_aiSuggestionFromMap(dbResponse));
      }
      
      // Create notification for user
      await createNotification(
        userId: userId,
        type: NotificationType.general,
        title: 'AI Suggestions Ready',
        message: 'Your hairstyle suggestions are ready!',
        data: {'suggestions_count': suggestions.length},
      );
      
      return aiSuggestions;
    } catch (e) {
      throw Exception('Failed to get AI suggestions: ${e.toString()}');
    }
  }
  
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}