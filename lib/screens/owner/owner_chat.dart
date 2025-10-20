import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/app_api.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';

class OwnerChatScreen extends ConsumerStatefulWidget {
  final String? customerId;
  final String? customerName;
  final String? customerImage;
  
  const OwnerChatScreen({
    super.key,
    this.customerId,
    this.customerName,
    this.customerImage,
  });

  @override
  ConsumerState<OwnerChatScreen> createState() => _OwnerChatScreenState();
}

class _OwnerChatScreenState extends ConsumerState<OwnerChatScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String? _selectedChatId;
  bool _isTyping = false;
  bool _isOtherTyping = false;

  // Mock chat data
  final List<Map<String, dynamic>> _chatList = [
    {
      'id': 'chat_1',
      'customerName': 'Ahmed Ali',
      'customerImage': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      'lastMessage': 'Thank you for the great service!',
      'lastMessageTime': '2 min ago',
      'unreadCount': 2,
      'isOnline': true,
    },
    {
      'id': 'chat_2',
      'customerName': 'Hassan Khan',
      'customerImage': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100',
      'lastMessage': 'Can I book for tomorrow?',
      'lastMessageTime': '15 min ago',
      'unreadCount': 0,
      'isOnline': false,
    },
    {
      'id': 'chat_3',
      'customerName': 'Usman Sheikh',
      'customerImage': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
      'lastMessage': 'What time do you close?',
      'lastMessageTime': '1 hour ago',
      'unreadCount': 1,
      'isOnline': true,
    },
    {
      'id': 'chat_4',
      'customerName': 'Bilal Ahmed',
      'customerImage': 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100',
      'lastMessage': 'Perfect, see you then!',
      'lastMessageTime': '2 hours ago',
      'unreadCount': 0,
      'isOnline': false,
    },
  ];

  final List<Map<String, dynamic>> _messages = [
    {
      'id': 'msg_1',
      'senderId': 'customer_1',
      'receiverId': 'owner_1',
      'content': 'Hi, I would like to book an appointment for tomorrow',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'isFromCustomer': true,
    },
    {
      'id': 'msg_2',
      'senderId': 'owner_1',
      'receiverId': 'customer_1',
      'content': 'Hello! Sure, what time would work for you?',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2, minutes: -5)),
      'isFromCustomer': false,
    },
    {
      'id': 'msg_3',
      'senderId': 'customer_1',
      'receiverId': 'owner_1',
      'content': 'How about 2 PM?',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      'isFromCustomer': true,
    },
    {
      'id': 'msg_4',
      'senderId': 'owner_1',
      'receiverId': 'customer_1',
      'content': 'Perfect! 2 PM works great. What service would you like?',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 25)),
      'isFromCustomer': false,
    },
    {
      'id': 'msg_5',
      'senderId': 'customer_1',
      'receiverId': 'owner_1',
      'content': 'I need a haircut and beard trim',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
      'isFromCustomer': true,
    },
    {
      'id': 'msg_6',
      'senderId': 'owner_1',
      'receiverId': 'customer_1',
      'content': 'Excellent! I\'ve booked you for 2 PM tomorrow for haircut and beard trim. See you then!',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      'isFromCustomer': false,
    },
    {
      'id': 'msg_7',
      'senderId': 'customer_1',
      'receiverId': 'owner_1',
      'content': 'Thank you! Looking forward to it.',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
      'isFromCustomer': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
    
    // If customer information is provided, automatically start chat with that customer
    if (widget.customerId != null && widget.customerName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startChatWithSpecificCustomer();
      });
    }
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatThreadsProvider.notifier).loadChatThreads();
      // Also refresh messages if we're in a chat
      if (_selectedChatId != null) {
        _refreshMessages();
      }
    });
  }

  /// Refresh messages for the current chat
  Future<void> _refreshMessages() async {
    try {
      final authState = ref.read(authProvider);
      if (authState.user != null && _selectedChatId != null) {
        // Get the thread ID from the selected chat
        final threadsState = ref.read(chatThreadsProvider);
        threadsState.whenData((threads) {
          final selectedThread = threads.firstWhere(
            (t) => (t['id'] ?? t['thread_id']) == _selectedChatId,
            orElse: () => <String, dynamic>{},
          );
          
          if (selectedThread.isNotEmpty) {
            final threadId = selectedThread['thread_id'] ?? selectedThread['id'];
            if (threadId != null) {
              // Load fresh messages for this thread
              ref.read(chatProvider.notifier).loadMessagesForThread(threadId, authState.user!.id);
            }
          }
        });
      }
    } catch (e) {
      print('Error refreshing messages: $e');
    }
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.backgroundWhite, Color(0xFFF8F4FF)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _selectedChatId == null ? _buildChatList() : _buildChatView(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return Consumer(
      builder: (context, ref, child) {
        final chatThreadsState = ref.watch(chatThreadsProvider);
        
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(20),
            child: const Text(
              'Recent Conversations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
            chatThreadsState.when(
              data: (threads) => SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
                    final thread = threads[index];
                    return _buildChatListItem(thread);
                  },
                  childCount: threads.length,
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Error loading chats: $error'),
                  ),
                ),
          ),
        ),
      ],
        );
      },
    );
  }

  Widget _buildChatView() {
    return Consumer(
      builder: (context, ref, child) {
        final chatThreadsState = ref.watch(chatThreadsProvider);
        
        return chatThreadsState.when(
          data: (threads) {
            // Resolve selected thread safely using id or thread_id
            final selected = threads.firstWhere(
              (t) => (t['id'] ?? t['thread_id']) == _selectedChatId,
              orElse: () => {},
            );
            if (selected.isEmpty) {
              return const Center(child: Text('No conversation selected'));
            }

            // Normalize header data (customer target)
            final ownerId = ref.read(currentUserProvider)?.id;
            final p1 = selected['participant_1'] as Map<String, dynamic>?;
            final p2 = selected['participant_2'] as Map<String, dynamic>?;
            final other = (p1 != null && p1['id'] != ownerId) ? p1 : p2;
            final normalized = {
              'customerId': other?['id'],
              'customerName': other?['full_name'],
              'customerImage': other?['avatar_url'],
            };
    
    return Column(
          children: [
                _buildChatHeader(normalized),
        Expanded(child: _buildMessagesList()),
        _buildMessageInput(),
      ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () {
            print('Back button pressed - navigating to home tab');
            // Navigate to owner-home which will show the dashboard with Home tab (index 0)
            context.push('/owner-home');
          },
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryMauve),
        ),
      ),
      title: const Text(
                          'Messages',
                          style: TextStyle(
          color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: _startNewChat,
            icon: const Icon(Icons.add, color: AppTheme.primaryMauve),
          ),
        ),
      ],
    );
  }

  Widget _buildChatHeader(Map<String, dynamic> chat) {
    return FutureBuilder<UserModel?>(
      future: AppApi.getUserProfile(chat['customerId']),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error fetching customer profile: ${snapshot.error}');
        }
        
        final customer = snapshot.data;
        final customerName = customer?.fullName ?? chat['customerName'] ?? 'Customer';
        final customerImage = customer?.profileImageUrl ?? chat['customerImage'];
        final customerId = customer?.id ?? (chat['customerId'] as String? ?? '');

        return Row(
        children: [
          Stack(
            children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (customerImage != null && customerImage.toString().isNotEmpty)
                      ? NetworkImage(customerImage.toString())
                      : null,
                  child: (customerImage == null || customerImage.toString().isEmpty)
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                FutureBuilder<Map<String, dynamic>>(
                  future: customerId.isNotEmpty ? AppApi.getOnlineStatus(customerId) : Future.value({'is_online': false, 'last_seen': DateTime.now().toIso8601String()}),
                  builder: (context, statusSnapshot) {
                    final status = statusSnapshot.data ?? {'is_online': false, 'last_seen': DateTime.now().toIso8601String()};
                    final isOnline = status['is_online'] as bool? ?? false;
                    if (isOnline) {
                      return Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      border: Border.all(color: Colors.white, width: 2),
                            shape: BoxShape.circle,
                    ),
                  ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                      fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                  const SizedBox(height: 2),
                  FutureBuilder<Map<String, dynamic>>(
                    future: customerId.isNotEmpty ? AppApi.getOnlineStatus(customerId) : Future.value({'is_online': false, 'last_seen': DateTime.now().toIso8601String()}),
                    builder: (context, statusSnapshot) {
                      final status = statusSnapshot.data ?? {'is_online': false, 'last_seen': DateTime.now().toIso8601String()};
                      final isOnline = status['is_online'] as bool? ?? false;
                      final lastSeen = status['last_seen'] as String?;
                      return Text(
                        isOnline ? 'online' : 'last seen ${_formatLastSeen(lastSeen)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                          color: isOnline ? Colors.green : AppTheme.textSecondary,
                  ),
                      );
                    },
                        ),
                      ],
                    ),
            ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _refreshMessages,
            icon: const Icon(Icons.refresh, color: AppTheme.primaryMauve),
            tooltip: 'Refresh messages',
          ),
        ],
      );
    },
  );
}

  Widget _buildChatListItem(Map<String, dynamic> thread) {
    // Extract participant information (assuming the current user is the salon owner)
    final participant1 = thread['participant_1'] as Map<String, dynamic>?;
    final participant2 = thread['participant_2'] as Map<String, dynamic>?;
    final lastMessage = thread['last_message'] as Map<String, dynamic>?;
    
    // Determine which participant is the customer (not the current salon owner)
    final ownerId = ref.read(currentUserProvider)?.id;
    final customer = (participant1 != null && participant1['id'] != ownerId)
        ? participant1
        : participant2;
    final customerName = customer?['full_name'] ?? 'Customer';
    final customerImage = customer?['avatar_url'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100';
    final lastAtIso = thread['last_message_at'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedChatId = (thread['id'] ?? thread['thread_id']) as String?);
          // Refresh messages when selecting a chat
          _refreshMessages();
        },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.network(
                        customerImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppTheme.primaryMauve,
                            child: const Icon(Icons.person, color: Colors.white, size: 24),
                          );
                        },
                      ),
                    ),
                  ),
                                      Positioned(
                      bottom: 0,
                                        right: 0,
                                        child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                                            shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          _formatTime(DateTime.tryParse(lastAtIso ?? '') ?? DateTime.now()),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                            lastMessage?['text'] ?? 'No messages yet',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if ((thread['unreadCount'] ?? 0) > 0)
                                            Container(
                            margin: const EdgeInsets.only(left: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                                color: AppTheme.primaryMauve,
                              borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                              thread['unreadCount'].toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
          ),
                            ),
                          ),
                        );
  }

  Widget _buildMessagesList() {
    return Consumer(
      builder: (context, ref, child) {
        final chatState = ref.watch(chatProvider);
        
        return chatState.when(
          data: (messages) => RefreshIndicator(
            onRefresh: _refreshMessages,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (_isOtherTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && _isOtherTyping) {
                  return _buildTypingIndicator();
                }
                final message = messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error loading messages: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshMessages,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final authState = ref.read(authProvider);
    final isFromCustomer = message.senderId != authState.user?.id;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isFromCustomer ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isFromCustomer) const SizedBox(width: 50),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isFromCustomer 
                      ? [Colors.grey.shade200, Colors.grey.shade100]
                      : [AppTheme.primaryMauve, AppTheme.primaryMauve.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isFromCustomer ? const Radius.circular(4) : const Radius.circular(20),
                  bottomRight: isFromCustomer ? const Radius.circular(20) : const Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
            ),
          ],
        ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isFromCustomer ? Colors.black87 : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Text(
                        _formatTime(message.createdAt),
                    style: TextStyle(
                          color: isFromCustomer ? Colors.grey[600] : Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      if (!isFromCustomer) ...[
                        const SizedBox(width: 4),
                        _buildMessageStatusIcon(message),
                      ],
                    ],
                  ),
            ],
          ),
        ),
      ),
          if (isFromCustomer) const SizedBox(width: 50),
        ],
      ),
    );
  }

  Widget _buildMessageStatusIcon(MessageModel message) {
    switch (message.status) {
      case MessageStatus.sent:
        return const Icon(
          Icons.check,
          size: 14,
          color: Colors.white70,
        );
      case MessageStatus.delivered:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Colors.white70,
        );
      case MessageStatus.read:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Colors.blue,
        );
      case MessageStatus.failed:
        return const Icon(
          Icons.error_outline,
          size: 14,
          color: Colors.red,
        );
      default:
        return const Icon(
          Icons.check,
          size: 14,
          color: Colors.white70,
        );
    }
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
      children: [
          const SizedBox(width: 50),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomLeft: const Radius.circular(4),
            ),
          ),
          child: Row(
              mainAxisSize: MainAxisSize.min,
            children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.shade600.withOpacity(0.3 + (0.7 * value)),
            shape: BoxShape.circle,
                ),
              );
            },
    );
  }

  Widget _buildMessageInput() {
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
          ),
          child: Row(
            children: [
              IconButton(
            onPressed: _showEmojiPicker,
            icon: const Icon(Icons.emoji_emotions_outlined, color: AppTheme.primaryMauve),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    onChanged: (value) {
                  setState(() {
                    _isTyping = value.isNotEmpty;
                  });
                    },
                  ),
                ),
              ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _showAttachmentOptions,
            icon: const Icon(Icons.attach_file, color: AppTheme.primaryMauve),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryMauve, AppTheme.primaryMauve.withOpacity(0.8)],
                ),
                    shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryMauve.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                  ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
    );
  }

  

  String _formatLastSeen(String? lastSeen) {
    if (lastSeen == null) return 'recently';
    
    try {
      final lastSeenTime = DateTime.parse(lastSeen);
      final now = DateTime.now();
      final difference = now.difference(lastSeenTime);
      
      if (difference.inMinutes < 1) {
        return 'now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${lastSeenTime.day}/${lastSeenTime.month}/${lastSeenTime.year}';
      }
    } catch (e) {
      return 'recently';
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _startNewChat() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StartNewChatModal(
        onCustomerSelected: (customer) {
          Navigator.pop(context);
          _startChatWithCustomer(customer);
        },
      ),
    );
  }

  void _startChatWithSpecificCustomer() async {
    try {
      // Get real customer data from the database
      final customerProfile = await AppApi.getUserProfile(widget.customerId!);
      
      // Create a new chat entry for the specific customer with real data
      final newChat = {
        'id': 'chat_${widget.customerId}_${DateTime.now().millisecondsSinceEpoch}',
        'customerId': widget.customerId,
        'customerName': customerProfile.fullName,
        'customerEmail': customerProfile.email,
        'customerImage': customerProfile.profileImageUrl ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
        'lastMessage': 'Chat started',
        'lastMessageTime': 'now',
        'unreadCount': 0,
        'isOnline': true,
      };
      
      setState(() {
        _chatList.insert(0, newChat);
        _selectedChatId = newChat['id'] as String;
      });
      
      // Initialize real chat with the customer
      await _initializeRealChat(widget.customerId!);
    } catch (e) {
      print('Error starting chat with specific customer: $e');
      // Fallback to using provided data
      final newChat = {
        'id': 'chat_${widget.customerId}_${DateTime.now().millisecondsSinceEpoch}',
        'customerId': widget.customerId,
        'customerName': widget.customerName ?? 'Customer',
        'customerEmail': '',
        'customerImage': widget.customerImage ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
        'lastMessage': 'Chat started',
        'lastMessageTime': 'now',
        'unreadCount': 0,
        'isOnline': true,
      };
      
      setState(() {
        _chatList.insert(0, newChat);
        _selectedChatId = newChat['id'] as String;
      });
    }
  }
  
  Future<void> _initializeRealChat(String customerId) async {
    try {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        // Get or create thread with the customer
        final threadId = await AppApi.getOrCreateThread(authState.user!.id, customerId);
        
        // Load messages for this thread
        await ref.read(chatProvider.notifier).loadMessagesForThread(threadId, authState.user!.id);
        
        print('Real chat initialized with thread: $threadId');
      }
    } catch (e) {
      print('Error initializing real chat: $e');
    }
  }

  void _startChatWithCustomer(Map<String, dynamic> customer) {
    // Create a new chat entry
    final newChat = {
      'id': 'chat_${customer['id']}_${DateTime.now().millisecondsSinceEpoch}',
      'customerId': customer['id'],
      'customerName': customer['name'],
      'customerEmail': customer['email'],
      'customerImage': customer['avatar_url'] ?? 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      'lastMessage': 'Chat started',
      'lastMessageTime': 'now',
      'unreadCount': 0,
      'isOnline': true,
    };
    
    setState(() {
      _chatList.insert(0, newChat);
      _selectedChatId = newChat['id'] as String;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Started chat with ${customer['name']}'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _showChatOptions(Map<String, dynamic> chat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person, color: AppTheme.primaryMauve),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('View profile feature coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block Customer'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Block feature coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Chat'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delete chat feature coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emoji picker coming soon!'),
        backgroundColor: AppTheme.primaryMauve,
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Attach File',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                _buildAttachmentOption(Icons.camera_alt, 'Camera', Colors.blue),
                _buildAttachmentOption(Icons.photo_library, 'Gallery', Colors.green),
                _buildAttachmentOption(Icons.attach_file, 'Document', Colors.orange),
                _buildAttachmentOption(Icons.location_on, 'Location', Colors.red),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label attachment coming soon!')),
        );
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      try {
        final authState = ref.read(authProvider);
        if (authState.user != null && _selectedChatId != null) {
          // Resolve selected thread from provider (fallback to empty map)
          final threadsState = ref.read(chatThreadsProvider);
          Map<String, dynamic> selected = const {};
          threadsState.when(
            data: (threads) {
              selected = threads.firstWhere(
                (t) => (t['id'] ?? t['thread_id']) == _selectedChatId,
                orElse: () => <String, dynamic>{},
              );
            },
            loading: () {},
            error: (_, __) {},
          );

          if (selected.isEmpty) {
            // Fallback to any existing local selection structure
            try {
              final local = _chatList.firstWhere(
                (chat) => chat['id'] == _selectedChatId,
                orElse: () => <String, dynamic>{},
              );
              if (local.isNotEmpty) selected = local;
            } catch (_) {}
          }

          if (selected.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to resolve chat thread')),
            );
            return;
          }

          // Determine customerId (the other participant)
          String? customerId;
          if (selected['customerId'] is String) {
            customerId = selected['customerId'] as String;
          }
          final currentId = authState.user!.id;
          final p1 = selected['participant_1'];
          final p2 = selected['participant_2'];
          if (customerId == null) {
            if (p1 is Map && p2 is Map) {
              final p1Id = p1['id'] as String?;
              final p2Id = p2['id'] as String?;
              if (p1Id != null && p2Id != null) {
                customerId = p1Id == currentId ? p2Id : p1Id;
              }
            } else if (p1 is String && p2 is String) {
              customerId = p1 == currentId ? p2 : p1;
            }
          }

          if (customerId == null || customerId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to determine recipient')),
            );
            return;
          }

          // Get or create thread
          final threadId = await AppApi.getOrCreateThread(currentId, customerId);

          // Send real message
          await ref.read(chatProvider.notifier).sendMessage(
            threadId: threadId,
            senderId: currentId,
            receiverId: customerId,
        text: message,
      );

          // Clear input and update state
      _messageController.clear();
      setState(() {
        _isTyping = false;
      });
        }
      } catch (e) {
        print('Error sending message: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }

      // Scroll to bottom after a tick
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }
}

class StartNewChatModal extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>) onCustomerSelected;

  const StartNewChatModal({
    super.key,
    required this.onCustomerSelected,
  });

  @override
  ConsumerState<StartNewChatModal> createState() => _StartNewChatModalState();
}

class _StartNewChatModalState extends ConsumerState<StartNewChatModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _filteredCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      setState(() => _isLoading = true);
      
      // Get customers who have booked appointments with this salon
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        // Get salon ID for this owner
        final salon = await AppApi.getSalonByOwnerId(authState.user!.id);
        if (salon != null) {
          // Get appointments for this salon to find customers
          final appointments = await AppApi.getAppointmentsBySalon(salon.id);
          
          // Extract unique customers from appointments
          final customerIds = appointments.map((apt) => apt.customerId).toSet();
          
          // Get customer profiles
          final customers = <Map<String, dynamic>>[];
          for (final customerId in customerIds) {
            try {
              final profile = await AppApi.getUserProfile(customerId);
              if (profile.role == UserRole.customer) {
                customers.add({
                  'id': customerId,
                  'name': profile.fullName,
                  'email': profile.email,
                  'phone': profile.phone,
                  'avatar_url': profile.profileImageUrl,
                  'lastAppointment': _getLastAppointmentDate(appointments, customerId),
                });
              }
            } catch (e) {
              print('Error loading customer $customerId: $e');
            }
          }
          
          setState(() {
            _customers = customers;
            _filteredCustomers = customers;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading customers: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getLastAppointmentDate(List appointments, String customerId) {
    final customerAppointments = appointments
        .where((apt) => apt.customerId == customerId)
        .toList();
    
    if (customerAppointments.isEmpty) return 'No appointments';
    
    customerAppointments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
    final lastAppointment = customerAppointments.first.appointmentDate;
    
    final now = DateTime.now();
    final difference = now.difference(lastAppointment);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _customers;
      } else {
        _filteredCustomers = _customers.where((customer) {
          final name = customer['name'].toString().toLowerCase();
          final email = customer['email'].toString().toLowerCase();
          final searchQuery = query.toLowerCase();
          return name.contains(searchQuery) || email.contains(searchQuery);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Start New Chat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search customers by name or email...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryMauve),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryMauve),
              ),
            ),
            onChanged: _filterCustomers,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? const Center(
                        child: Text(
                          'No customers found',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryMauve.withOpacity(0.1),
                              backgroundImage: customer['avatar_url'] != null
                                  ? NetworkImage(customer['avatar_url'])
                                  : null,
                              child: customer['avatar_url'] == null
                                  ? Text(
                                      customer['name'][0].toUpperCase(),
                                      style: const TextStyle(
                                        color: AppTheme.primaryMauve,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(customer['name']),
                            subtitle: Text(
                              '${customer['email']} • Last visit: ${customer['lastAppointment']}',
                            ),
                            trailing: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryMauve),
                            onTap: () => widget.onCustomerSelected(customer),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

}