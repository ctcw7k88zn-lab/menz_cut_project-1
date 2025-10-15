import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../models/message_model.dart';

class OwnerChatScreen extends ConsumerStatefulWidget {
  const OwnerChatScreen({super.key});

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
      ref.read(chatProvider.notifier).loadAllMessages();
    });
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
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final chat = _chatList[index];
              return _buildChatListItem(chat);
            },
            childCount: _chatList.length,
          ),
        ),
      ],
    );
  }

  Widget _buildChatView() {
    final selectedChat = _chatList.firstWhere((chat) => chat['id'] == _selectedChatId);
    
    return Column(
          children: [
        _buildChatHeader(selectedChat),
        Expanded(child: _buildMessagesList()),
        _buildMessageInput(),
      ],
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
          onPressed: () => _showComingSoon('Back'),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _selectedChatId = null),
            child: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryMauve),
          ),
          const SizedBox(width: 12),
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    chat['customerImage'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.primaryMauve,
                        child: const Icon(Icons.person, color: Colors.white, size: 20),
                      );
                    },
                  ),
                ),
              ),
              if (chat['isOnline'])
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
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
                Text(
                  chat['customerName'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  chat['isOnline'] ? 'Online' : 'Last seen ${chat['lastMessageTime']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                        ),
                      ],
                    ),
                  ),
          IconButton(
            onPressed: () => _showChatOptions(chat),
            icon: const Icon(Icons.more_vert, color: AppTheme.primaryMauve),
          ),
        ],
      ),
    );
  }

  Widget _buildChatListItem(Map<String, dynamic> chat) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GestureDetector(
        onTap: () => setState(() => _selectedChatId = chat['id']),
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
                        chat['customerImage'],
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
                  if (chat['isOnline'])
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
                          chat['customerName'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          chat['lastMessageTime'],
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
                            chat['lastMessage'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat['unreadCount'] > 0)
                                            Container(
                            margin: const EdgeInsets.only(left: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                                color: AppTheme.primaryMauve,
                              borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                              chat['unreadCount'].toString(),
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
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isFromCustomer = message['isFromCustomer'] as bool;
    
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
                    message['content'],
                    style: TextStyle(
                      color: isFromCustomer ? Colors.black87 : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message['timestamp']),
                    style: TextStyle(
                      color: isFromCustomer ? Colors.grey.shade600 : Colors.white70,
                      fontSize: 10,
                    ),
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

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  void _startNewChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Start new chat feature coming soon!'),
        backgroundColor: AppTheme.primaryMauve,
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

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      ref.read(chatProvider.notifier).sendMessage(
        threadId: 'thread_1',
        senderId: 'owner_1',
        receiverId: 'customer_1',
        text: message,
      );
      _messageController.clear();
      setState(() {
        _isTyping = false;
      });
      
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: AppTheme.primaryMauve,
      ),
    );
  }
}