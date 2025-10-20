import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/app_api.dart';

class CustomerChatsScreen extends ConsumerStatefulWidget {
  const CustomerChatsScreen({super.key});

  @override
  ConsumerState<CustomerChatsScreen> createState() => _CustomerChatsScreenState();
}

class _CustomerChatsScreenState extends ConsumerState<CustomerChatsScreen> {
  @override
  void initState() {
    super.initState();
    // Load threads once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatThreadsProvider.notifier).loadChatThreads();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final threadsState = ref.watch(chatThreadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.primaryMauve,
      ),
      body: threadsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load chats: $e')),
        data: (threads) {
          if (threads.isEmpty) {
            return const Center(child: Text('No conversations yet'));
          }

          // Sort newest first if not already
          threads.sort((a, b) {
            final ta = DateTime.tryParse((a['last_message_at'] ?? a['updated_at'] ?? '') as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
            final tb = DateTime.tryParse((b['last_message_at'] ?? b['updated_at'] ?? '') as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
            return tb.compareTo(ta);
          });

          return ListView.builder(
            itemCount: threads.length,
            itemBuilder: (context, index) {
              final thread = threads[index];
              final currentUserId = authState.user?.id;

              // Resolve other participant (salon owner id)
              final p1 = thread['participant_1'];
              final p2 = thread['participant_2'];
              String? p1Id;
              String? p2Id;
              if (p1 is Map) p1Id = p1['id'] as String?; else if (p1 is String) p1Id = p1;
              if (p2 is Map) p2Id = p2['id'] as String?; else if (p2 is String) p2Id = p2;
              final otherUserId = (p1Id == currentUserId) ? p2Id : p1Id;

              final last = thread['last_message'] as Map<String, dynamic>?;
              final lastText = last != null ? (last['text'] as String? ?? '') : '';
              final lastAt = DateTime.tryParse((thread['last_message_at'] ?? thread['updated_at'] ?? '') as String? ?? '')
                  ?? DateTime.fromMillisecondsSinceEpoch(0);
              final unread = (thread['unreadCount'] ?? 0) as int;

              return FutureBuilder<Map<String, dynamic>?>(
                future: _loadSalonForOwner(otherUserId),
                builder: (context, salonSnap) {
                  final salon = salonSnap.data;
                  // Fallbacks from participant profile if salon not found
                  String title = 'Salon';
                  String? imageUrl;
                  if (salon != null) {
                    title = salon['name'] as String;
                    imageUrl = salon['primaryImageUrl'] as String?;
                  } else {
                    // Try participant map for name/avatar
                    final other = (p1Id == currentUserId) ? p2 : p1;
                    if (other is Map) {
                      title = (other['full_name'] as String?)?.trim().isNotEmpty == true ? other['full_name'] as String : 'Salon';
                      final avatar = other['avatar_url'] as String?;
                      if (avatar != null && avatar.isNotEmpty) imageUrl = avatar;
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                                ? NetworkImage(imageUrl)
                                : null,
                            child: (imageUrl == null || imageUrl.isEmpty)
                                ? const Icon(Icons.store, color: Colors.grey)
                                : null,
                          ),
                          // Online dot
                          FutureBuilder<Map<String, dynamic>>(
                            future: (otherUserId != null && otherUserId.isNotEmpty)
                                ? AppApi.getOnlineStatus(otherUserId)
                                : Future.value({'is_online': false}),
                            builder: (context, snap) {
                              final isOnline = (snap.data?['is_online'] as bool?) ?? false;
                              if (!isOnline) return const SizedBox.shrink();
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
                            },
                          ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(lastAt),
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastText.isEmpty ? 'Say Hi 👋' : lastText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryMauve,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unread.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        if (salon != null) {
                          context.push('/customer-chat', extra: {
                            'salonId': salon['id'],
                            'salonName': salon['name'],
                            'ownerId': otherUserId,
                          });
                        } else {
                          // Open chat using ownerId only; header will resolve salon via owner
                          context.push('/customer-chat', extra: {
                            'ownerId': otherUserId,
                          });
                        }
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> _loadSalonForOwner(String? ownerId) async {
    if (ownerId == null || ownerId.isEmpty) return null;
    try {
      final salon = await AppApi.getSalonByOwnerId(ownerId);
      if (salon == null) return null;
      return {
        'id': salon.id,
        'name': salon.name,
        'primaryImageUrl': salon.primaryImageUrl,
      };
    } catch (_) {
      return null;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
