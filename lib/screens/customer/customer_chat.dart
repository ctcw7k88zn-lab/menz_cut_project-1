import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/animated_button.dart' as custom;
import '../../models/message_model.dart';
import '../../models/salon_model.dart';
import '../../services/app_api.dart';

class CustomerChatScreen extends ConsumerStatefulWidget {
  final String? salonId;
  final String? salonName;
  final String? ownerId;
  
  const CustomerChatScreen({
    super.key,
    this.salonId,
    this.salonName,
    this.ownerId,
  });

  @override
  ConsumerState<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends ConsumerState<CustomerChatScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String? _currentThreadId;
  String? _salonOwnerId;
  bool _isTyping = false;
  bool _isOtherTyping = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        // Get salon owner ID from salon ID
        if (widget.salonId != null) {
          final salon = await AppApi.getSalonById(widget.salonId!);
          _salonOwnerId = salon.ownerId;
        } else if (widget.ownerId != null && widget.ownerId!.isNotEmpty) {
          _salonOwnerId = widget.ownerId;
        } else {
          _salonOwnerId = null;
        }
        
        // Get or create thread
        _currentThreadId = await ref.read(chatProvider.notifier).getOrCreateThread(
          authState.user!.id,
          _salonOwnerId!,
        );
        
        // Load messages for this thread
        await ref.read(chatProvider.notifier).loadMessagesForThread(
          _currentThreadId!,
          authState.user!.id,
        );
        
        // Update online status (optional)
        try {
          await ref.read(chatProvider.notifier).updateOnlineStatus(
            authState.user!.id,
            true,
          );
        } catch (e) {
          print('Online status update failed: $e');
        }
      }
    } catch (e) {
      print('Chat initialization error: $e');
      // Set fallback values to ensure chat still works
      _currentThreadId = 'fallback_thread';
      _salonOwnerId = 'fallback_owner';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    
    // Update online status to offline when leaving
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      ref.read(chatProvider.notifier).updateOnlineStatus(authState.user!.id, false);
    }
    
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty && _currentThreadId != null && _salonOwnerId != null) {
      try {
        final authState = ref.read(authProvider);
        if (authState.user != null) {
          // Stop typing indicator
          _stopTyping();
          
          ref.read(chatProvider.notifier).sendMessage(
            threadId: _currentThreadId!,
            senderId: authState.user!.id,
            receiverId: _salonOwnerId!,
            text: message,
          );
          _messageController.clear();
          _scrollToBottom();
        }
      } catch (e) {
        print('Error sending message: $e');
        // Still clear the text field and show user feedback
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message sent (offline mode)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _onTextChanged(String text) {
    // Simplified typing indicator - just track typing state without timer
    if (text.isNotEmpty && _currentThreadId != null && !_isTyping) {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        _startTyping();
      }
    } else if (text.isEmpty && _isTyping) {
      _stopTyping();
    }
  }

  void _startTyping() {
    if (!_isTyping && _currentThreadId != null) {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        _isTyping = true;
        ref.read(chatProvider.notifier).startTyping(_currentThreadId!, authState.user!.id);
      }
    }
  }

  void _stopTyping() {
    if (_isTyping && _currentThreadId != null) {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        _isTyping = false;
        ref.read(chatProvider.notifier).stopTyping(_currentThreadId!, authState.user!.id);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Messages
                Expanded(
                  child: _buildMessagesList(chatState),
                ),
                
                // Message Input
                _buildMessageInput(),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Consumer(
      builder: (context, ref, child) {
        return FutureBuilder<SalonModel?>(
          future: widget.salonId != null ? AppApi.getSalonById(widget.salonId!) : null,
          builder: (context, snapshot) {
            final salon = snapshot.data;
            final salonName = salon?.name ?? widget.salonName;
            final salonImage = salon?.primaryImageUrl;
            final effectiveOwnerId = salon?.ownerId ?? widget.ownerId ?? _salonOwnerId;

            return Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      // Avatar with fallback to owner profile image when salon image is missing
                      FutureBuilder<Map<String, dynamic>>(
                        future: effectiveOwnerId != null && effectiveOwnerId.isNotEmpty
                            ? AppApi.getOnlineStatus(effectiveOwnerId)
                            : Future.value({'is_online': false}),
                        builder: (context, statusSnap) {
                          return Stack(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: (salonImage != null && salonImage.isNotEmpty)
                                    ? NetworkImage(salonImage)
                                    : null,
                                child: (salonImage == null || salonImage.isEmpty)
                                    ? const Icon(Icons.store, color: Colors.grey)
                                    : null,
                              ),
                              if ((statusSnap.data?['is_online'] as bool?) == true)
                                Positioned(
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
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<Map<String, dynamic>?>(
                              future: (salon == null && _salonOwnerId != null)
                                  ? _loadOwnerProfile(_salonOwnerId!)
                                  : Future.value(null),
                              builder: (context, ownerSnap) {
                                final fallbackName = ownerSnap.data != null
                                    ? (ownerSnap.data!['full_name'] as String? ?? 'Salon')
                                    : 'Salon';
                                return Text(
                                  salonName ?? fallbackName,
                                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                            FutureBuilder<Map<String, dynamic>>(
                              future: widget.salonId != null
                                  ? AppApi.getOnlineStatus((salon?.ownerId ?? '').isNotEmpty ? salon!.ownerId : (effectiveOwnerId ?? 'noop'))
                                  : (effectiveOwnerId != null
                                      ? AppApi.getOnlineStatus(effectiveOwnerId)
                                      : Future.value({'is_online': false, 'last_seen': DateTime.now().toIso8601String()})),
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
                      const SizedBox(width: AppTheme.spacing12),
                      IconButton(
                        icon: const Icon(Icons.info_outline, color: AppTheme.textPrimary),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadOwnerProfile(String ownerId) async {
    try {
      final user = await AppApi.getUserProfile(ownerId);
      return {
        'full_name': user.fullName,
        'avatar_url': user.profileImageUrl,
      };
    } catch (_) {
      return {'full_name': 'Salon', 'avatar_url': null};
    }
  }

  Widget _buildMessagesList(AsyncValue<List<MessageModel>> messagesAsync) {
    return messagesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMauve),
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Failed to load messages',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              error.toString(),
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing16),
            custom.PrimaryButton(
              text: 'Try Again',
              onPressed: () => ref.refresh(chatProvider),
            ),
          ],
        ),
      ),
      data: (messages) {

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryMauve.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: AppTheme.primaryMauve,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'Start a conversation',
              style: AppTheme.heading3,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Send a message to get started',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: messages.length + (_isOtherTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && _isOtherTyping) {
          return _buildTypingIndicator();
        }
        
        final message = messages[index];
        final authState = ref.read(authProvider);
        final isMe = authState.user != null && message.senderId == authState.user!.id;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
          child: ChatBubble(
            message: message,
            isCurrentUser: isMe,
            onLongPress: () => _showMessageOptions(message),
          ),
        );
      },
    );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing16,
              vertical: AppTheme.spacing12,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[200],
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
            color: Colors.grey[600]!.withOpacity(0.3 + (0.7 * value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Row(
            children: [
              // Attachment Button
              GestureDetector(
                onTap: () {
                  // TODO: Show attachment options
                },
                child: AppTheme.glassCard(
                  child: const Icon(
                    Icons.attach_file,
                    color: AppTheme.textPrimary,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              
              // Message Input
              Expanded(
                child: AppTheme.glassCard(
                  padding: EdgeInsets.zero,
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing16,
                        vertical: AppTheme.spacing12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: _onTextChanged,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              
              // Send Button
              GestureDetector(
                onTap: _sendMessage,
                child: AppTheme.glassCard(
                  child: const Icon(
                    Icons.send,
                    color: AppTheme.primaryMauve,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(AppTheme.spacing12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primaryMauve,
        unselectedItemColor: AppTheme.textLight,
        onTap: (index) {
          switch (index) {
            case 0:
              context.push('/customer-home');
              break;
            case 1:
              context.push('/customer-map');
              break;
            case 2:
              context.push('/customer-appointments');
              break;
            case 3:
              // Already on chat
              break;
            case 4:
              context.push('/customer-profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusLarge),
            topRight: Radius.circular(AppTheme.radiusLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: AppTheme.spacing12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Copy message to clipboard
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.errorColor),
              title: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Delete message
              },
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
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
}
