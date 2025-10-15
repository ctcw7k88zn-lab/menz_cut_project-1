import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../services/app_api.dart';
import '../services/realtime_service.dart';

/// Enhanced Chat provider using AsyncNotifier for better error handling
class ChatNotifier extends AsyncNotifier<List<MessageModel>> {
  final RealtimeService _realtimeService = RealtimeService();
  final Uuid _uuid = const Uuid();

  @override
  Future<List<MessageModel>> build() async {
    // Initialize messages from local storage
    final messages = await AppApi.getAllMessages();
    
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
  Future<void> loadMessagesForThread(String threadId) async {
    state = const AsyncValue.loading();
    try {
      final messages = await AppApi.getMessagesByThread(threadId);
      state = AsyncValue.data(messages);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
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
      // Remove failed message from UI
      state.whenData((messages) {
        state = AsyncValue.data(messages.where((m) => m.id != message.id).toList());
      });
      state = AsyncValue.error(error, stackTrace);
      return null;
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

  /// Simulate typing indicator
  void startTyping(String threadId, String senderId) {
    _realtimeService.simulateTyping(threadId, senderId);
  }

  /// Stop typing indicator
  void stopTyping() {
    // Implementation for stopping typing indicator
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
final messagesByThreadProvider = FutureProvider.family<List<MessageModel>, String>((ref, threadId) async {
  final chatNotifier = ref.read(chatProvider.notifier);
  await chatNotifier.loadMessagesForThread(threadId);
  final messagesAsync = ref.read(chatProvider);
  return messagesAsync.when(
    data: (messages) => messages.where((message) => message.threadId == threadId).toList(),
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