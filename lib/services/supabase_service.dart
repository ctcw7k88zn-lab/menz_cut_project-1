import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/salon_model.dart';
import '../models/service_model.dart';
import '../models/appointment_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../models/ai_suggestion_model.dart';
import '../models/review_model.dart';

/// Supabase service that handles all backend operations
class SupabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Authentication methods
  static Future<UserModel> login(String email, String password) async {
    try {
      print('🔐 SupabaseService: Starting login for: $email');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      print('🔐 SupabaseService: Login response: ${response.user?.id}');
      
      if (response.user == null) {
        throw Exception('Login failed - no user returned from Supabase');
      }
      
      // Get user profile
      final userProfile = await _getUserProfile(response.user!.id);
      
      // Create login notification
      try {
        await createNotification(
          userId: response.user!.id,
          type: NotificationType.general,
          title: 'Welcome Back!',
          message: 'You have successfully logged into your account.',
          data: {'login_time': DateTime.now().toIso8601String()},
        );
        print('🔔 SupabaseService: Login notification created');
      } catch (notificationError) {
        print('⚠️ SupabaseService: Failed to create login notification: $notificationError');
        // Don't fail login if notification fails
      }
      
      return userProfile;
    } catch (e) {
      print('❌ SupabaseService: Login error: $e');
      throw Exception('Login failed: ${e.toString()}');
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
      
      // Create welcome notification
      try {
        await createNotification(
          userId: response.user!.id,
          type: NotificationType.general,
          title: 'Welcome to Menz Cut!',
          message: role == UserRole.customer 
              ? 'Welcome! Start exploring salons and book your first appointment.'
              : 'Welcome! Set up your salon profile and start accepting appointments.',
          data: {'role': role.name, 'signup_time': DateTime.now().toIso8601String()},
        );
        print('🔔 SupabaseService: Welcome notification created');
      } catch (notificationError) {
        print('⚠️ SupabaseService: Failed to create welcome notification: $notificationError');
        // Don't fail signup if notification fails
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

  static Future<SalonModel> getSalonById(String id) async {
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

  // Get salon by owner ID
  static Future<SalonModel?> getSalonByOwnerId(String ownerId) async {
    try {
      print('SupabaseService: Getting salon for owner: $ownerId');
      final response = await _supabase
          .from('salons')
          .select('*')
          .eq('owner_id', ownerId)
          .eq('is_active', true)
          .maybeSingle();
      
      print('SupabaseService: Response: $response');
      if (response == null) {
        print('SupabaseService: No salon found for owner');
        return null;
      }
      
      final salon = _salonFromMap(response);
      print('SupabaseService: Mapped salon: ${salon.id}');
      return salon;
    } catch (e) {
      print('SupabaseService: Error fetching salon: $e');
      throw Exception('Failed to fetch salon by owner: ${e.toString()}');
    }
  }

  // Create salon for owner if it doesn't exist
  static Future<SalonModel> createSalonForOwner(String ownerId, {
    required String name,
    required String description,
    required String address,
    String? phone,
    String? email,
  }) async {
    try {
      final response = await _supabase
          .from('salons')
          .insert({
            'owner_id': ownerId,
            'name': name,
            'description': description,
            'address': address,
            'city': address, // Using address as city for now
            'phone': phone ?? '',
            'email': email ?? '',
            'is_active': true,
          })
          .select()
          .single();
      
      return _salonFromMap(response);
    } catch (e) {
      throw Exception('Failed to create salon: ${e.toString()}');
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

  static Future<List<ServiceModel>> getServicesBySalonOwner(String ownerId) async {
    try {
      // First get the salon for this owner
      final salon = await getSalonByOwnerId(ownerId);
      if (salon == null) {
        return []; // No salon found for this owner
      }
      
      // Then get services for this salon
      return await getServicesBySalon(salon.id);
    } catch (e) {
      throw Exception('Failed to fetch services by owner: ${e.toString()}');
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

  static Future<ServiceModel> getServiceById(String serviceId) async {
    try {
      final response = await _supabase
          .from('services')
          .select('*')
          .eq('id', serviceId)
          .eq('is_active', true)
          .single();
      
      return _serviceFromMap(response);
    } catch (e) {
      throw Exception('Failed to get service: ${e.toString()}');
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

  // Image upload methods
  static Future<String> uploadServiceImage(String userId, Uint8List imageBytes, String fileName) async {
    try {
      print('SupabaseService: Starting image upload for user: $userId');
      print('SupabaseService: File name: $fileName, Size: ${imageBytes.length} bytes');
      
      final fileExt = fileName.split('.').last;
      final newFileName = '${const Uuid().v4()}.$fileExt';
      final path = 'services/$userId/$newFileName';
      
      print('SupabaseService: Uploading to path: $path');
      
      await _supabase.storage
          .from('service-images')
          .uploadBinary(path, imageBytes);
      
      print('SupabaseService: Upload completed successfully');
      
      final imageUrl = _supabase.storage
          .from('service-images')
          .getPublicUrl(path);
      
      print('SupabaseService: Generated public URL: $imageUrl');
      
      return imageUrl;
    } catch (e) {
      print('SupabaseService: Image upload failed: $e');
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  static Future<String> uploadProfileImage(String userId, Uint8List imageBytes, String fileName) async {
    try {
      final fileExt = fileName.split('.').last;
      final newFileName = '${const Uuid().v4()}.$fileExt';
      final path = 'profiles/$userId/$newFileName';
      
      await _supabase.storage
          .from('profile-pics')
          .uploadBinary(path, imageBytes);
      
      final imageUrl = _supabase.storage
          .from('profile-pics')
          .getPublicUrl(path);
      
      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: ${e.toString()}');
    }
  }

  static Future<void> deleteImage(String bucket, String path) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception('Failed to delete image: ${e.toString()}');
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
      print('🔍 SupabaseService: Getting messages for thread: $threadId');
      final response = await _supabase
          .from('messages')
          .select('*')
          .eq('thread_id', threadId)
          .order('created_at', ascending: true);
      
      final messages = response.map((data) => _messageFromMap(data)).toList();
      print('🔍 SupabaseService: Found ${messages.length} messages for thread');
      return messages;
    } catch (e) {
      print('❌ SupabaseService: Error getting messages: $e');
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
        .map((data) => data.map((item) => _messageFromMap(item)).toList());
  }

  // Enhanced chat functionality
  static Future<String> getOrCreateThread(String user1Id, String user2Id) async {
    try {
      print('🔗 SupabaseService: Getting or creating thread between $user1Id and $user2Id');
      
      // Check if thread exists
      final existingThread = await _supabase
          .from('chat_threads')
          .select('thread_id')
          .or('and(participant_1.eq.$user1Id,participant_2.eq.$user2Id),and(participant_1.eq.$user2Id,participant_2.eq.$user1Id)')
          .maybeSingle();
      
      if (existingThread != null) {
        print('🔗 SupabaseService: Found existing thread: ${existingThread['thread_id']}');
        return existingThread['thread_id'];
      }
      
      // Create new thread with explicit UUID generation
      final threadId = const Uuid().v4();
      final response = await _supabase
          .from('chat_threads')
          .insert({
            'thread_id': threadId,
            'participant_1': user1Id,
            'participant_2': user2Id,
          })
          .select('thread_id')
          .single();
      
      print('🔗 SupabaseService: Created new thread: ${response['thread_id']}');
      return response['thread_id'];
    } catch (e) {
      print('❌ SupabaseService: Error getting/creating thread: $e');
      // Return a fallback thread ID for demo purposes
      return 'demo_thread_${user1Id.substring(0, 8)}_${user2Id.substring(0, 8)}';
    }
  }

  static Future<List<Map<String, dynamic>>> getCustomers() async {
    try {
      print('👥 SupabaseService: Fetching customers');
      
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, email, avatar_url, created_at')
          .eq('role', 'customer')
          .order('created_at', ascending: false);
      
      print('👥 SupabaseService: Found ${response.length} customers');
      
      return response.map((customer) => {
        'id': customer['id'],
        'name': customer['full_name'],
        'email': customer['email'],
        'avatar_url': customer['avatar_url'],
        'last_visit': customer['created_at'],
      }).toList();
    } catch (e) {
      print('❌ SupabaseService: Error fetching customers: $e');
      throw Exception('Failed to fetch customers: ${e.toString()}');
    }
  }

  static Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      print('📡 SupabaseService: Updating online status for $userId: $isOnline');
      await _supabase.rpc('update_user_online_status', params: {
        'user_id_param': userId,
        'is_online_param': isOnline,
      });
    } catch (e) {
      print('❌ SupabaseService: Error updating online status: $e');
    }
  }

  static Future<Map<String, dynamic>> getOnlineStatus(String userId) async {
    try {
      final response = await _supabase
          .from('online_status')
          .select('is_online, last_seen, status_message')
          .eq('user_id', userId)
          .maybeSingle();
      
      return response ?? {
        'is_online': false,
        'last_seen': DateTime.now().toIso8601String(),
        'status_message': 'Offline',
      };
    } catch (e) {
      print('❌ SupabaseService: Error getting online status: $e');
      return {
        'is_online': false,
        'last_seen': DateTime.now().toIso8601String(),
        'status_message': 'Offline',
      };
    }
  }

  static Future<void> startTyping(String threadId, String userId) async {
    try {
      await _supabase
          .from('typing_indicators')
          .upsert({
            'thread_id': threadId,
            'user_id': userId,
            'is_typing': true,
            'expires_at': DateTime.now().add(const Duration(seconds: 30)).toIso8601String(),
          });
    } catch (e) {
      print('❌ SupabaseService: Error starting typing: $e');
    }
  }

  static Future<void> stopTyping(String threadId, String userId) async {
    try {
      await _supabase
          .from('typing_indicators')
          .update({'is_typing': false})
          .eq('thread_id', threadId)
          .eq('user_id', userId);
    } catch (e) {
      print('❌ SupabaseService: Error stopping typing: $e');
    }
  }

  static Stream<List<Map<String, dynamic>>> getTypingIndicators(String threadId) {
    return _supabase
        .from('typing_indicators')
        .stream(primaryKey: ['id'])
        .map((data) => data.where((item) => item['thread_id'] == threadId && item['is_typing'] == true).toList());
  }

  static Future<void> markMessagesAsRead(String threadId, String userId) async {
    try {
      print('✅ SupabaseService: Marking messages as read for thread $threadId, user $userId');
      await _supabase.rpc('mark_messages_as_read', params: {
        'thread_id_param': threadId,
        'user_id_param': userId,
      });
    } catch (e) {
      print('❌ SupabaseService: Error marking messages as read: $e');
    }
  }

  static Future<int> getUnreadMessageCount(String userId) async {
    try {
      final response = await _supabase.rpc('get_unread_message_count', params: {
        'user_id_param': userId,
      });
      return response as int;
    } catch (e) {
      print('❌ SupabaseService: Error getting unread count: $e');
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> getChatThreads(String userId) async {
    try {
      final response = await _supabase
          .from('chat_threads')
          .select('''
            *,
            participant_1:profiles!chat_threads_participant_1_fkey(id, full_name, avatar_url),
            participant_2:profiles!chat_threads_participant_2_fkey(id, full_name, avatar_url),
            last_message:messages(id, text, created_at, sender_id)
          ''')
          .or('participant_1.eq.$userId,participant_2.eq.$userId')
          .order('last_message_at', ascending: false);
      
      return response;
    } catch (e) {
      print('❌ SupabaseService: Error getting chat threads: $e');
      return [];
    }
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
  static Future<UserModel> getUserProfile(String userId) async {
    return await _getUserProfile(userId);
  }

  static Future<UserModel> _getUserProfile(String userId) async {
    try {
      print('Fetching profile for user: $userId');
      
      // First, try to get the current user from auth
      final authUser = _supabase.auth.currentUser;
      print('Current auth user: ${authUser?.id}, email: ${authUser?.email}');
      
      if (authUser == null) {
        throw Exception('No authenticated user found');
      }
      
      // Try to fetch profile with explicit auth context
      final response = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();
      
      print('Profile query result: $response');
      
      if (response == null) {
        // Profile doesn't exist, create it from auth user data
        print('Profile not found for user $userId, creating from auth data...');
        
        // Create profile from auth user metadata
        final profileData = {
          'id': userId,
          'email': authUser.email ?? '',
          'full_name': authUser.userMetadata?['full_name'] ?? authUser.email?.split('@')[0] ?? 'User',
          'phone': authUser.userMetadata?['phone'] ?? '',
          'role': authUser.userMetadata?['role'] ?? 'salon_owner', // Default to salon_owner for existing users
          'is_email_verified': authUser.emailConfirmedAt != null,
          'is_phone_verified': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        print('Creating profile with data: $profileData');
        
        try {
          await _supabase.from('profiles').insert(profileData);
          print('Profile created successfully for user $userId');
        } catch (insertError) {
          print('Error creating profile: $insertError');
          // If insert fails, try to query again in case it was created by another process
          final retryResponse = await _supabase
              .from('profiles')
              .select('*')
              .eq('id', userId)
              .maybeSingle();
          
          if (retryResponse != null) {
            print('Profile found on retry: ${retryResponse['email']}, role: ${retryResponse['role']}');
            return _userFromMap(retryResponse);
          }
          
          rethrow;
        }
        
        return _userFromMap(profileData);
      }
      
      print('Found existing profile: ${response['email']}, role: ${response['role']}');
      return _userFromMap(response);
    } catch (e) {
      print('Error in _getUserProfile: $e');
      
      // If all else fails, create a basic profile from auth data
      try {
        final authUser = _supabase.auth.currentUser;
        if (authUser != null) {
          print('Creating fallback profile for user: ${authUser.id}');
          final fallbackProfile = UserModel(
            id: authUser.id,
            email: authUser.email ?? '',
            fullName: authUser.userMetadata?['full_name'] ?? authUser.email?.split('@')[0] ?? 'User',
            phone: authUser.userMetadata?['phone'] ?? '',
            role: UserRole.salonOwner, // Default to salon owner
            profileImageUrl: null,
            isEmailVerified: authUser.emailConfirmedAt != null,
            isPhoneVerified: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          return fallbackProfile;
        }
      } catch (fallbackError) {
        print('Fallback profile creation failed: $fallbackError');
      }
      
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
    // Safely handle imageUrls
    List<String> imageUrls = [];
    if (data['logo_url'] != null && data['logo_url'].toString().isNotEmpty) {
      imageUrls.add(data['logo_url'].toString());
    }
    if (data['banner_url'] != null && data['banner_url'].toString().isNotEmpty) {
      imageUrls.add(data['banner_url'].toString());
    }

    // Safely handle openingHours
    Map<String, String> openingHours = {'Monday': '9:00-18:00'};
    if (data['opening_hours'] != null) {
      try {
        if (data['opening_hours'] is Map) {
          openingHours = Map<String, String>.from(data['opening_hours'] as Map);
        }
      } catch (e) {
        print('Error parsing opening_hours: $e');
      }
    }

    return SalonModel(
      id: data['id'].toString(),
      ownerId: data['owner_id'].toString(),
      name: data['name'].toString(),
      description: data['description']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      imageUrls: imageUrls,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['review_count'] ?? 0,
      categories: ['Haircut'], // Default category since salons table doesn't have categories field
      openingHours: openingHours,
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(data['created_at'].toString()),
      updatedAt: DateTime.parse(data['updated_at'].toString()),
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
      stylistId: data['staff_id'], // Use staff_id as stylist_id
      startAt: DateTime.parse(data['start_at']),
      endAt: DateTime.parse(data['end_at']),
      status: AppointmentStatus.values.firstWhere((e) => e.name == data['status']),
      paymentStatus: PaymentStatus.values.firstWhere((e) => e.name == data['payment_status']),
      notes: data['notes'],
      totalAmount: (data['total_price'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      duration: data['service']?['duration_minutes'] ?? 60,
      price: (data['service']?['price'] ?? data['total_price'] ?? 0.0).toDouble(),
      serviceDetails: data['service'] != null ? {
        'name': data['service']['name'],
        'price': data['service']['price'],
        'duration_minutes': data['service']['duration_minutes'],
      } : null,
      customerDetails: data['customer'] != null ? {
        'full_name': data['customer']['full_name'],
        'phone': data['customer']['phone'],
        'email': data['customer']['email'],
      } : null,
      salonDetails: data['salon'] != null ? {
        'name': data['salon']['name'],
        'address': data['salon']['address'],
        'phone': data['salon']['phone'],
      } : null,
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
      print('🔧 SupabaseService: Creating appointment with conflict check...');
      print('🔧 SupabaseService: customerId: $customerId');
      print('🔧 SupabaseService: salonId: $salonId');
      print('🔧 SupabaseService: serviceId: $serviceId');
      print('🔧 SupabaseService: staffId: $staffId');
      print('🔧 SupabaseService: notes: $notes');
      
      // Get service details to calculate end time
      final service = await _supabase
          .from('services')
          .select('duration_minutes, price')
          .eq('id', serviceId)
          .single();
      
      final duration = service['duration_minutes'] as int;
      final endAt = startAt.add(Duration(minutes: duration));
      
      print('🔧 SupabaseService: Service duration: $duration minutes');
      print('🔧 SupabaseService: Start time: ${startAt.toIso8601String()}');
      print('🔧 SupabaseService: End time: ${endAt.toIso8601String()}');
      
      // Check for conflicts
      var conflictQuery = _supabase
          .from('appointments')
          .select('id, start_at, end_at')
          .eq('salon_id', salonId)
          .eq('status', 'confirmed')
          .gte('start_at', startAt.toIso8601String())
          .lt('start_at', endAt.toIso8601String());
      
      // Add staff-specific conflict check
      if (staffId != null) {
        conflictQuery = conflictQuery.or('staff_id.eq.$staffId,staff_id.is.null');
      } else {
        conflictQuery = conflictQuery.isFilter('staff_id', null);
      }
      
      final conflicts = await conflictQuery;
      
      if (conflicts.isNotEmpty) {
        throw Exception('Time slot conflict detected. Please choose a different time.');
      }
      
      // Create appointment
      final appointmentData = {
        'customer_id': customerId,
        'salon_id': salonId,
        'service_id': serviceId,
        'start_at': startAt.toIso8601String(),
        'end_at': endAt.toIso8601String(),
        'status': 'pending',
        'total_price': service['price'] ?? 0.0,
        'payment_status': 'pending',
      };
      
      // Only add staff_id if it's not null
      if (staffId != null) {
        appointmentData['staff_id'] = staffId;
        print('🔧 SupabaseService: Added staff_id: $staffId');
      } else {
        print('🔧 SupabaseService: staff_id is null, not adding to appointment data');
      }
      
      // Only add notes if it's not null
      if (notes != null) {
        appointmentData['notes'] = notes;
        print('🔧 SupabaseService: Added notes: $notes');
      } else {
        print('🔧 SupabaseService: notes is null, not adding to appointment data');
      }
      
      print('🔧 SupabaseService: Final appointment data: $appointmentData');
      
      final response = await _supabase
          .from('appointments')
          .insert(appointmentData)
          .select()
          .single();
      
      // Create notification for salon owner (optional - don't fail if this fails)
      try {
        await createNotification(
          userId: (await _supabase.from('salons').select('owner_id').eq('id', salonId).single())['owner_id'],
          type: NotificationType.newAppointment,
          title: 'New Appointment Request',
          message: 'You have a new appointment request',
          data: {'appointment_id': response['id']},
        );
        print('🔧 SupabaseService: Notification created successfully');
      } catch (notificationError) {
        print('⚠️ SupabaseService: Failed to create notification: $notificationError');
        // Don't fail the appointment creation if notification fails
      }
      
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
      print('🔧 SupabaseService: Getting appointments for customer: $customerId');
      final response = await _supabase
          .from('appointments')
          .select('''
            *,
            salon:salons(name, address, phone),
            service:services(name, price, duration_minutes)
          ''')
          .eq('customer_id', customerId)
          .order('start_at', ascending: false);
      
      print('🔧 SupabaseService: Found ${response.length} appointments for customer');
      final appointments = response.map((data) => _appointmentFromMap(data)).toList();
      print('🔧 SupabaseService: Mapped ${appointments.length} appointments');
      return appointments;
    } catch (e) {
      print('❌ SupabaseService: Error fetching customer appointments: $e');
      throw Exception('Failed to fetch customer appointments: ${e.toString()}');
    }
  }
  
  /// Get appointments for salon
  static Future<List<AppointmentModel>> getSalonAppointments(String salonId) async {
    try {
      print('🔧 SupabaseService: Getting appointments for salon: $salonId');
      final response = await _supabase
          .from('appointments')
          .select('''
            *,
            customer:profiles(full_name, phone, email),
            service:services(name, price, duration_minutes)
          ''')
          .eq('salon_id', salonId)
          .order('start_at', ascending: false);
      
      print('🔧 SupabaseService: Found ${response.length} appointments for salon');
      final appointments = response.map((data) => _appointmentFromMap(data)).toList();
      print('🔧 SupabaseService: Mapped ${appointments.length} appointments');
      return appointments;
    } catch (e) {
      print('❌ SupabaseService: Error fetching salon appointments: $e');
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
      // Map Flutter enum values to database enum values
      String dbType;
      switch (type) {
        case NotificationType.newAppointment:
        case NotificationType.appointmentConfirmed:
        case NotificationType.appointmentCancelled:
        case NotificationType.appointmentCompleted:
        case NotificationType.appointmentReminder:
          dbType = 'appointment';
          break;
        case NotificationType.newMessage:
          dbType = 'message';
          break;
        case NotificationType.serviceUpdate:
        case NotificationType.salonUpdate:
        case NotificationType.reviewRequest:
        case NotificationType.general:
          dbType = 'system';
          break;
      }
      
      final response = await _supabase
          .from('notifications')
          .insert({
            'user_id': userId,
            'type': dbType,
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

  // ==================== REVIEW METHODS ====================
  
  // Get reviews for a specific salon
  static Future<List<ReviewModel>> getReviewsForSalon(String salonId) async {
    try {
      print('🔍 SupabaseService: Getting reviews for salon: $salonId');
      
      final response = await _supabase
          .from('reviews')
          .select('''
            *,
            profiles!reviews_customer_id_fkey(
              full_name,
              avatar_url
            )
          ''')
          .eq('salon_id', salonId)
          .order('created_at', ascending: false);
      
      print('🔍 SupabaseService: Found ${response.length} reviews for salon');
      
      return response.map<ReviewModel>((data) => _reviewFromMap(data)).toList();
    } catch (e) {
      print('❌ SupabaseService: Error getting reviews for salon: $e');
      throw Exception('Failed to get reviews: ${e.toString()}');
    }
  }

  // Get reviews for a specific customer
  static Future<List<ReviewModel>> getReviewsForCustomer(String customerId) async {
    try {
      print('🔍 SupabaseService: Getting reviews for customer: $customerId');
      
      final response = await _supabase
          .from('reviews')
          .select('''
            *,
            profiles!reviews_customer_id_fkey(
              full_name,
              avatar_url
            )
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      
      print('🔍 SupabaseService: Found ${response.length} reviews for customer');
      
      return response.map<ReviewModel>((data) => _reviewFromMap(data)).toList();
    } catch (e) {
      print('❌ SupabaseService: Error getting reviews for customer: $e');
      throw Exception('Failed to get reviews: ${e.toString()}');
    }
  }

  // Create a new review
  static Future<String> createReview({
    required String customerId,
    required String salonId,
    String? appointmentId,
    required int rating,
    required String comment,
    List<String> images = const [],
  }) async {
    try {
      print('📝 SupabaseService: Creating review for salon: $salonId');
      
      // Check if customer has already reviewed this salon
      final existingReview = await _supabase
          .from('reviews')
          .select('id')
          .eq('customer_id', customerId)
          .eq('salon_id', salonId)
          .maybeSingle();
      
      if (existingReview != null) {
        throw Exception('You have already reviewed this salon');
      }
      
      final response = await _supabase
          .from('reviews')
          .insert({
            'customer_id': customerId,
            'salon_id': salonId,
            'appointment_id': appointmentId,
            'rating': rating,
            'comment': comment,
            'images': images,
          })
          .select('id')
          .single();
      
      print('✅ SupabaseService: Review created successfully: ${response['id']}');
      
      // Update salon rating and review count
      await _updateSalonRating(salonId);
      
      return response['id'];
    } catch (e) {
      print('❌ SupabaseService: Error creating review: $e');
      throw Exception('Failed to create review: ${e.toString()}');
    }
  }

  // Update an existing review
  static Future<void> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
    List<String> images = const [],
  }) async {
    try {
      print('✏️ SupabaseService: Updating review: $reviewId');
      
      final response = await _supabase
          .from('reviews')
          .update({
            'rating': rating,
            'comment': comment,
            'images': images,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reviewId)
          .select('salon_id')
          .single();
      
      print('✅ SupabaseService: Review updated successfully');
      
      // Update salon rating and review count
      await _updateSalonRating(response['salon_id']);
    } catch (e) {
      print('❌ SupabaseService: Error updating review: $e');
      throw Exception('Failed to update review: ${e.toString()}');
    }
  }

  // Delete a review
  static Future<void> deleteReview(String reviewId) async {
    try {
      print('🗑️ SupabaseService: Deleting review: $reviewId');
      
      final response = await _supabase
          .from('reviews')
          .delete()
          .eq('id', reviewId)
          .select('salon_id')
          .single();
      
      print('✅ SupabaseService: Review deleted successfully');
      
      // Update salon rating and review count
      await _updateSalonRating(response['salon_id']);
    } catch (e) {
      print('❌ SupabaseService: Error deleting review: $e');
      throw Exception('Failed to delete review: ${e.toString()}');
    }
  }

  // Get review statistics for a salon
  static Future<ReviewStats> getReviewStats(String salonId) async {
    try {
      print('📊 SupabaseService: Getting review stats for salon: $salonId');
      
      final response = await _supabase
          .from('reviews')
          .select('rating')
          .eq('salon_id', salonId);
      
      if (response.isEmpty) {
        return const ReviewStats(
          averageRating: 0.0,
          totalReviews: 0,
          ratingDistribution: {},
        );
      }
      
      final ratings = response.map<int>((r) => r['rating'] as int).toList();
      final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
      
      final ratingDistribution = <int, int>{};
      for (final rating in ratings) {
        ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
      }
      
      print('📊 SupabaseService: Review stats - Average: $averageRating, Total: ${ratings.length}');
      
      return ReviewStats(
        averageRating: averageRating,
        totalReviews: ratings.length,
        ratingDistribution: ratingDistribution,
      );
    } catch (e) {
      print('❌ SupabaseService: Error getting review stats: $e');
      throw Exception('Failed to get review stats: ${e.toString()}');
    }
  }

  // Check if customer can review a salon
  static Future<bool> canCustomerReviewSalon(String customerId, String salonId) async {
    try {
      print('🔍 SupabaseService: Checking if customer can review salon');
      
      // Check if customer has already reviewed this salon
      final existingReview = await _supabase
          .from('reviews')
          .select('id')
          .eq('customer_id', customerId)
          .eq('salon_id', salonId)
          .maybeSingle();
      
      if (existingReview != null) {
        return false; // Already reviewed
      }
      
      // Check if customer has any completed appointments with this salon
      final completedAppointments = await _supabase
          .from('appointments')
          .select('id')
          .eq('customer_id', customerId)
          .eq('salon_id', salonId)
          .eq('status', 'completed')
          .limit(1);
      
      return completedAppointments.isNotEmpty;
    } catch (e) {
      print('❌ SupabaseService: Error checking review eligibility: $e');
      return false;
    }
  }

  // Helper method to update salon rating and review count
  static Future<void> _updateSalonRating(String salonId) async {
    try {
      final stats = await getReviewStats(salonId);
      
      await _supabase
          .from('salons')
          .update({
            'rating': stats.averageRating,
            'review_count': stats.totalReviews,
          })
          .eq('id', salonId);
      
      print('📊 SupabaseService: Updated salon rating: ${stats.averageRating}, reviews: ${stats.totalReviews}');
    } catch (e) {
      print('❌ SupabaseService: Error updating salon rating: $e');
    }
  }

  // Manual method to fix salon rating (for immediate fix)
  static Future<void> fixSalonRating(String salonId) async {
    try {
      print('🔧 SupabaseService: Manually fixing salon rating for: $salonId');
      
      // Get all reviews for this salon
      final reviews = await getReviewsForSalon(salonId);
      
      if (reviews.isEmpty) {
        print('🔧 SupabaseService: No reviews found, setting rating to 0');
        final updateResponse = await _supabase
            .from('salons')
            .update({
              'rating': 0.0,
              'review_count': 0,
            })
            .eq('id', salonId)
            .select('id, rating, review_count')
            .single();
        print('🔧 SupabaseService: Update response: $updateResponse');
        return;
      }
      
      // Calculate average rating
      final totalRating = reviews.fold<int>(0, (sum, review) => sum + review.rating);
      final averageRating = totalRating / reviews.length;
      
      print('🔧 SupabaseService: Calculated rating: $averageRating from ${reviews.length} reviews');
      
      // Update salon with explicit return
      final updateResponse = await _supabase
          .from('salons')
          .update({
            'rating': averageRating,
            'review_count': reviews.length,
          })
          .eq('id', salonId)
          .select('id, rating, review_count')
          .single();
      
      print('✅ SupabaseService: Salon rating fixed - Rating: $averageRating, Reviews: ${reviews.length}');
      print('✅ SupabaseService: Update response: $updateResponse');
    } catch (e) {
      print('❌ SupabaseService: Error fixing salon rating: $e');
    }
  }

  // Helper method to convert database response to ReviewModel
  static ReviewModel _reviewFromMap(Map<String, dynamic> data) {
    final profile = data['profiles'] as Map<String, dynamic>?;
    
    return ReviewModel(
      id: data['id'],
      customerId: data['customer_id'],
      salonId: data['salon_id'],
      appointmentId: data['appointment_id'],
      rating: data['rating'],
      comment: data['comment'],
      images: List<String>.from(data['images'] ?? []),
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      customerName: profile?['full_name'],
      customerAvatar: profile?['avatar_url'],
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}