import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../services/app_api.dart';
import '../services/realtime_service.dart';

/// Enhanced Chat provider using AsyncNotifier for better error handling
class ChatNotifier extends AsyncNotifier<List<MessageModel>> {
  final RealtimeService _realtimeService = RealtimeService();
  final Uuid _uuid = const Uuid();
  String? _currentThreadId;
  String? _currentUserId;

  @override
  Future<List<MessageModel>> build() async {
    // Initialize with empty list
    final messages = <MessageModel>[];
    
    // Subscribe to realtime updates
    _subscribeToRealtimeUpdates();
    
    return messages;
  }

  /// Subscribe to realtime message updates
  void _subscribeToRealtimeUpdates() {
    _realtimeService.messagesStream.listen((updatedMessage) {
      state.whenData((messages) {
        final existingIndex = messages.indexWhere(
          (message) => message.id == updatedMessage.id,
        );
        
        if (existingIndex != -1) {
          // Update existing message
          final updatedMessages = List<MessageModel>.from(messages);
          updatedMessages[existingIndex] = updatedMessage;
          state = AsyncValue.data(updatedMessages);
        } else {
          // Add new message
          state = AsyncValue.data([...messages, updatedMessage]);
        }
      });
    });
  }

  /// Load messages for a specific thread
  Future<void> loadMessagesForThread(String threadId, String userId) async {
    state = const AsyncValue.loading();
    _currentThreadId = threadId;
    _currentUserId = userId;
    
    try {
      final messages = await AppApi.getMessagesByThread(threadId);
      state = AsyncValue.data(messages);
      
      // Mark messages as read when loading the thread
      try {
        await markThreadAsRead(threadId);
      } catch (e) {
        print('Failed to mark messages as read: $e');
      }
    } catch (error, stackTrace) {
      print('Error loading messages for thread $threadId: $error');
      // Return empty list instead of error to prevent UI crashes
      state = AsyncValue.data([]);
    }
  }

  /// Load messages for a specific user
  Future<void> loadMessagesForUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      final messages = await AppApi.getMessagesByUser(userId);
      state = AsyncValue.data(messages);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Load all messages (for admin/owner view)
  Future<void> loadAllMessages() async {
    state = const AsyncValue.loading();
    try {
      final messages = await AppApi.getAllMessages();
      state = AsyncValue.data(messages);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Send a message
  Future<MessageModel?> sendMessage({
    required String threadId,
    required String senderId,
    required String receiverId,
    required String text,
    List<String> attachments = const [],
  }) async {
    final message = MessageModel(
      id: _uuid.v4(),
      threadId: threadId,
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      attachments: attachments,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );
    
    try {
      // Add message optimistically to UI
      state.whenData((messages) {
        state = AsyncValue.data([...messages, message]);
      });
      
      // Send message via API
      final sentMessage = await AppApi.sendMessage(message);
      
      // Update the message in the list
      state.whenData((messages) {
        final updatedMessages = messages.map((m) {
          return m.id == message.id ? sentMessage : m;
        }).toList();
        state = AsyncValue.data(updatedMessages);
      });
      
      return sentMessage;
    } catch (error, stackTrace) {
      print('Error sending message: $error');
      // Update message status to failed instead of removing it
      state.whenData((messages) {
        final updatedMessages = messages.map((m) {
          return m.id == message.id ? message.copyWith(status: MessageStatus.failed) : m;
        }).toList();
        state = AsyncValue.data(updatedMessages);
      });
      
      // Return the message with failed status instead of throwing
      return message.copyWith(status: MessageStatus.failed);
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await AppApi.markMessageAsRead(messageId);
      
      state.whenData((messages) {
        final updatedMessages = messages.map((message) {
          if (message.id == messageId) {
            return message.copyWith(status: MessageStatus.read);
          }
          return message;
        }).toList();
        state = AsyncValue.data(updatedMessages);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Mark all messages in thread as read
  Future<void> markThreadAsRead(String threadId) async {
    try {
      final currentState = state;
      if (currentState.hasValue) {
        final unreadMessages = currentState.value!.where(
          (message) => message.threadId == threadId && message.status != MessageStatus.read,
        );
        
        for (final message in unreadMessages) {
          await markMessageAsRead(message.id);
        }
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Start typing indicator
  void startTyping(String threadId, String senderId) {
    if (_currentThreadId == threadId && _currentUserId != null) {
      AppApi.startTyping(threadId, senderId);
    }
  }

  /// Stop typing indicator
  void stopTyping(String threadId, String senderId) {
    AppApi.stopTyping(threadId, senderId);
  }

  /// Get typing indicators stream
  Stream<List<Map<String, dynamic>>> getTypingIndicators(String threadId) {
    return AppApi.getTypingIndicators(threadId);
  }

  /// Update online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    await AppApi.updateOnlineStatus(userId, isOnline);
  }

  /// Get online status
  Future<Map<String, dynamic>> getOnlineStatus(String userId) async {
    return await AppApi.getOnlineStatus(userId);
  }

  /// Get unread message count
  Future<int> getUnreadMessageCount(String userId) async {
    return await AppApi.getUnreadMessageCount(userId);
  }

  /// Get chat threads for user
  Future<List<Map<String, dynamic>>> getChatThreads(String userId) async {
    return await AppApi.getChatThreads(userId);
  }

  /// Get or create thread between two users
  Future<String> getOrCreateThread(String user1Id, String user2Id) async {
    return await AppApi.getOrCreateThread(user1Id, user2Id);
  }

  /// Create a thread ID between two users
  String createThreadId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return 'thread_${sortedIds.join('_')}';
  }

  /// Refresh messages
  Future<void> refreshMessages() async {
    await loadAllMessages();
  }
}

/// Enhanced Chat provider using AsyncNotifier
final chatProvider = AsyncNotifierProvider<ChatNotifier, List<MessageModel>>(() {
  return ChatNotifier();
});

/// Messages by thread provider
final messagesByThreadProvider = FutureProvider.family<List<MessageModel>, ({String threadId, String userId})>((ref, params) async {
  final chatNotifier = ref.read(chatProvider.notifier);
  await chatNotifier.loadMessagesForThread(params.threadId, params.userId);
  final messagesAsync = ref.read(chatProvider);
  return messagesAsync.when(
    data: (messages) => messages.where((message) => message.threadId == params.threadId).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Messages by user provider
final messagesByUserProvider = FutureProvider.family<List<MessageModel>, String>((ref, userId) async {
  final chatNotifier = ref.read(chatProvider.notifier);
  await chatNotifier.loadMessagesForUser(userId);
  final messagesAsync = ref.read(chatProvider);
  return messagesAsync.when(
    data: (messages) => messages.where((message) => message.senderId == userId || message.receiverId == userId).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Unread message count provider
final unreadMessageCountProvider = Provider.family<int, String>((ref, userId) {
  final messagesAsync = ref.watch(chatProvider);
  return messagesAsync.when(
    data: (messages) => messages.where(
      (message) => message.receiverId == userId && message.status != MessageStatus.read,
    ).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Unread message count for thread provider
final unreadMessageCountForThreadProvider = Provider.family<int, ({String threadId, String userId})>((ref, params) {
  final messagesAsync = ref.watch(chatProvider);
  return messagesAsync.when(
    data: (messages) => messages.where(
      (message) => message.threadId == params.threadId &&
          message.receiverId == params.userId &&
          message.status != MessageStatus.read,
    ).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Latest message for thread provider
final latestMessageForThreadProvider = Provider.family<MessageModel?, String>((ref, threadId) {
  final messagesAsync = ref.watch(chatProvider);
  return messagesAsync.when(
    data: (messages) {
      final threadMessages = messages.where(
        (message) => message.threadId == threadId,
      ).toList();
      
      if (threadMessages.isEmpty) return null;
      
      threadMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return threadMessages.first;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});