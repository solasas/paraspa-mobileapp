import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/swap_avatar.dart';
import '../../models/conversation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messages_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final myId = ref.watch(authProvider).userId;
    final top = MediaQuery.of(context).padding.top + 8;
    final conversations = conversationsAsync.valueOrNull ?? const <Conversation>[];
    final unread = conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

    Future<void> refresh() async => ref.invalidate(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenX,
            top,
            AppSpacing.screenX,
            AppSpacing.scrollBottom,
          ),
          children: [
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Messages', style: AppText.h1()),
                if (unread > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$unread unread',
                      style: AppText.body(13, weight: FontWeight.w700, color: AppColors.accent),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (conversationsAsync.isLoading && conversations.isEmpty)
              const SizedBox(
                height: 240,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.6)),
              )
            else if (conversationsAsync.hasError && conversations.isEmpty)
              SizedBox(
                height: 280,
                child: AsyncValueWidget<List<Conversation>>(
                  value: conversationsAsync,
                  onRetry: refresh,
                  data: (_) => const SizedBox.shrink(),
                ),
              )
            else if (conversations.isEmpty)
              const SizedBox(
                height: 320,
                child: EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  message: 'No conversations yet.\nStart a chat to connect with others.',
                ),
              )
            else ...[
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  itemCount: conversations.length.clamp(0, 8),
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final c = conversations[i];
                    return GestureDetector(
                      onTap: () => context.push('/messages/${c.otherUser.id}'),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SwapAvatar(
                            name: c.otherUser.name,
                            seed: c.otherUser.id,
                            size: 60,
                            ringColor: c.unreadCount > 0 ? AppColors.accent : AppColors.ink,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            firstName(c.otherUser.name),
                            style: AppText.body(12, weight: FontWeight.w600, color: AppColors.ink),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < conversations.length; i++)
                      _ConversationRow(
                        conversation: conversations[i],
                        myId: myId,
                        last: i == conversations.length - 1,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime t) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final days = today.difference(day).inDays;
  if (days <= 0) return DateFormat('HH:mm').format(t);
  if (days == 1) return 'Yesterday';
  if (days < 7) return DateFormat('EEE').format(t);
  return DateFormat('MMM d').format(t);
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation, required this.myId, required this.last});

  final Conversation conversation;
  final int? myId;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final other = conversation.otherUser;
    final msg = conversation.lastMessage;
    final unread = conversation.unreadCount;
    final isUnread = unread > 0;
    final preview = msg.sender.id == myId ? 'You: ${msg.content}' : msg.content;

    return InkWell(
      onTap: () => context.push('/messages/${other.id}'),
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFFBFAF6) : Colors.white,
          border: last ? null : const Border(bottom: BorderSide(color: AppColors.sunken)),
        ),
        child: Row(
          children: [
            SwapAvatar(name: other.name, seed: other.id, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          other.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.personName(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(msg.createdAt),
                        style: AppText.body(
                          12,
                          weight: isUnread ? FontWeight.w700 : FontWeight.w400,
                          color: isUnread ? AppColors.ink : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                            14,
                            weight: isUnread ? FontWeight.w600 : FontWeight.w400,
                            color: isUnread ? AppColors.ink : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            '$unread',
                            style: AppText.body(12, weight: FontWeight.w700, color: AppColors.accent),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
