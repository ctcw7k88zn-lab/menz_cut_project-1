import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/message_model.dart';
import '../services/image_cache_service.dart';
import 'glass_card.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;
  final VoidCallback? onLongPress;
  final VoidCallback? onImageTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onLongPress,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing16,
          vertical: AppTheme.spacing4,
        ),
        child: Row(
          mainAxisAlignment: isCurrentUser 
              ? MainAxisAlignment.end 
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isCurrentUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryMauve.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: AppTheme.primaryMauve,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
            ],
            
            Flexible(
              child: Column(
                crossAxisAlignment: isCurrentUser 
                    ? CrossAxisAlignment.end 
                    : CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(),
                  const SizedBox(height: AppTheme.spacing4),
                  _buildMessageStatus(),
                ],
              ),
            ),
            
            if (isCurrentUser) ...[
              const SizedBox(width: AppTheme.spacing8),
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryMauve.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: AppTheme.primaryMauve,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    if (message.isImage) {
      return _buildImageMessage();
    } else if (message.isFile) {
      return _buildFileMessage();
    } else {
      return _buildTextMessage();
    }
  }

  Widget _buildTextMessage() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      borderRadius: AppTheme.radiusLarge,
      color: isCurrentUser 
          ? AppTheme.primaryMauve.withOpacity(0.1)
          : AppTheme.surfaceLight,
      child: Text(
        message.content,
        style: AppTheme.bodyMedium.copyWith(
          color: isCurrentUser ? AppTheme.primaryMauve : AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildImageMessage() {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: AppTheme.radiusLarge,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: GestureDetector(
          onTap: onImageTap,
          child: ImageCacheService.cachedImage(
            imageUrl: message.imageUrl!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildFileMessage() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      borderRadius: AppTheme.radiusLarge,
      color: isCurrentUser 
          ? AppTheme.primaryMauve.withOpacity(0.1)
          : AppTheme.surfaceLight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_file,
            size: 20,
            color: isCurrentUser ? AppTheme.primaryMauve : AppTheme.textPrimary,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Text(
            message.fileName ?? 'File',
            style: AppTheme.bodyMedium.copyWith(
              color: isCurrentUser ? AppTheme.primaryMauve : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageStatus() {
    if (!isCurrentUser) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.formattedTime,
          style: AppTheme.caption.copyWith(
            color: AppTheme.textLight,
          ),
        ),
        const SizedBox(width: AppTheme.spacing4),
        _buildStatusIcon(),
      ],
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = AppTheme.textLight;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = AppTheme.textLight;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = AppTheme.textLight;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = AppTheme.primaryMauve;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = AppTheme.errorColor;
        break;
    }

    return Icon(
      icon,
      size: 12,
      color: color,
    );
  }
}

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onSend;
  final VoidCallback? onImagePick;
  final VoidCallback? onFilePick;
  final bool isLoading;
  final String? hint;

  const ChatInputField({
    super.key,
    required this.controller,
    this.onSend,
    this.onImagePick,
    this.onFilePick,
    this.isLoading = false,
    this.hint,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isComposing = widget.controller.text.isNotEmpty;
    });
  }

  void _handleSend() {
    if (widget.controller.text.trim().isNotEmpty) {
      widget.onSend?.call();
      widget.controller.clear();
      setState(() {
        _isComposing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.all(AppTheme.spacing16),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            onPressed: widget.onImagePick,
            icon: Icon(
              Icons.image,
              color: AppTheme.textSecondary,
            ),
          ),
          
          // Text input
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) => _handleSend(),
              style: AppTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: widget.hint ?? 'Type a message...',
                hintStyle: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textLight,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing8,
                ),
              ),
            ),
          ),
          
          // Send button
          IconButton(
            onPressed: _isComposing && !widget.isLoading ? _handleSend : null,
            icon: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMauve),
                    ),
                  )
                : Icon(
                    Icons.send,
                    color: _isComposing ? AppTheme.primaryMauve : AppTheme.textLight,
                  ),
          ),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  final List<String> typingUsers;

  const TypingIndicator({
    super.key,
    required this.typingUsers,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing4,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryMauve.withOpacity(0.1),
            child: Icon(
              Icons.person,
              size: 16,
              color: AppTheme.primaryMauve,
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          GlassCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing16,
              vertical: AppTheme.spacing12,
            ),
            borderRadius: AppTheme.radiusLarge,
            color: AppTheme.surfaceLight,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.typingUsers.join(', ')} ${widget.typingUsers.length == 1 ? 'is' : 'are'} typing',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing4),
                    Opacity(
                      opacity: _animation.value,
                      child: Text(
                        '...',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
