import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/sub_page.dart';
import '../../core/widgets/swap_avatar.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/matches_provider.dart';
import '../../providers/messages_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.otherUserId});

  final int otherUserId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late ScrollController _scrollController;
  final _messageController = TextEditingController();
  bool _sending = false;
  int _lastCount = -1;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Mark messages as read by fetching conversation
    // (backend marks them as read as a side effect)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(unreadCountProvider);
    });
    _setupSocket();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    // Don't disconnect socket here as it may be used by other chat screens
    // The socket service will handle its own lifecycle
    super.dispose();
  }

  Future<void> _setupSocket() async {
    final socketService = ref.read(chatSocketServiceProvider);

    if (!socketService.isConnected) {
      await socketService.connect();
    }

    // Listen to incoming messages
    socketService.messages.listen(
      (message) {
        if (mounted) {
          ref.read(chatThreadProvider(widget.otherUserId).notifier).addMessage(message);
          _scrollToBottom();
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Socket error: $error')),
          );
        }
      },
    );

    // Listen to errors
    socketService.errors.listen(
      (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error stream error: $error')),
          );
        }
      },
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.microtask(() {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _sending = true);
    _messageController.clear();

    try {
      final message = await ref
          .read(messagesRepositoryProvider)
          .sendMessage(receiverId: widget.otherUserId, content: content);

      // Optimistically add message to the thread (socket may still be echoing)
      if (mounted) {
        ref.read(chatThreadProvider(widget.otherUserId).notifier).addMessage(message);
        _scrollToBottom();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatThreadProvider(widget.otherUserId));
    final myId = ref.watch(authProvider).userId;

    // Resolve the other person from the thread, falling back to their profile.
    User? other;
    if (messages.isNotEmpty) {
      final m = messages.first;
      other = m.sender.id == myId ? m.receiver : m.sender;
    }
    other ??= ref.watch(matchDetailProvider(widget.otherUserId)).valueOrNull?.user;

    if (messages.length != _lastCount) {
      final first = _lastCount == -1;
      _lastCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final max = _scrollController.position.maxScrollExtent;
        if (first) {
          _scrollController.jumpTo(max);
        } else {
          _scrollController.animateTo(
            max,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }

    final items = _withDaySeparators(messages);
    final lastMine = messages.lastWhere(
      (m) => m.sender.id == myId,
      orElse: () => messages.isEmpty ? _none : messages.last,
    );
    final showReceipt = messages.isNotEmpty && messages.last.sender.id == myId;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Column(
        children: [
          _ChatHeader(
            user: other,
            otherUserId: widget.otherUserId,
            onSchedule: () => context.go('/requests'),
          ),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'Start a conversation…',
                      style: AppText.body(15, color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length + (showReceipt ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              lastMine.read
                                  ? 'Seen ${hhmm(lastMine.createdAt)}'
                                  : 'Delivered',
                              style: AppText.body(12, color: AppColors.textSecondary),
                            ),
                          ),
                        );
                      }
                      final item = items[index];
                      if (item.separator != null) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.trackBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                item.separator!,
                                style: AppText.body(
                                  12,
                                  weight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      final message = item.message!;
                      return _MessageBubble(
                        message: message,
                        isMine: message.sender.id == myId,
                      );
                    },
                  ),
          ),
          _MessageComposer(
            messageController: _messageController,
            onSend: _sendMessage,
            sending: _sending,
            hint: other == null ? 'Message…' : 'Message ${firstName(other.name)}…',
          ),
        ],
      ),
    );
  }

  static final Message _none = Message(
    id: -1,
    sender: const User(id: -1, name: '', email: ''),
    receiver: const User(id: -1, name: '', email: ''),
    content: '',
    read: false,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  List<({Message? message, String? separator})> _withDaySeparators(List<Message> messages) {
    final out = <({Message? message, String? separator})>[];
    DateTime? currentDay;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    for (final m in messages) {
      final day = DateTime(m.createdAt.year, m.createdAt.month, m.createdAt.day);
      if (currentDay != day) {
        currentDay = day;
        final diff = today.difference(day).inDays;
        final label = diff == 0
            ? 'Today'
            : diff == 1
                ? 'Yesterday'
                : DateFormat('EEE, d MMM').format(day);
        out.add((message: null, separator: label));
      }
      out.add((message: m, separator: null));
    }
    return out;
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.user, required this.otherUserId, required this.onSchedule});

  final User? user;
  final int otherUserId;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'Chat';
    final city = user?.city;
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 4, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(bottom: BorderSide(color: AppColors.barBorder)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              tooltip: 'Back to messages',
              onPressed: () => popOrGo(context, '/messages'),
              icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.push('/matches/$otherUserId'),
              child: Row(
                children: [
                  SwapAvatar(name: name, seed: otherUserId, size: 44),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(17, weight: FontWeight.w700, color: AppColors.ink),
                        ),
                        if (city != null && city.isNotEmpty)
                          Text(city, style: AppText.body(13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: 'Schedule a session',
            child: Material(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: onSchedule,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.78;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isMine ? AppColors.ink : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMine ? 20 : 6),
                bottomRight: Radius.circular(isMine ? 6 : 20),
              ),
              border: isMine ? null : Border.all(color: AppColors.cardBorder),
            ),
            child: Text(
              message.content,
              style: AppText.body(
                15,
                height: 1.4,
                color: isMine ? AppColors.paper : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.messageController,
    required this.onSend,
    required this.sending,
    required this.hint,
  });

  final TextEditingController messageController;
  final VoidCallback onSend;
  final bool sending;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.barBorder)),
      ),
      padding: EdgeInsets.fromLTRB(14, 10, 14, 14 + bottom),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.inputBorder, width: 1.5),
              ),
              child: TextField(
                controller: messageController,
                enabled: !sending,
                textInputAction: TextInputAction.send,
                onSubmitted: sending ? null : (_) => onSend(),
                cursorColor: AppColors.ink,
                style: AppText.body(15, weight: FontWeight.w500, color: AppColors.ink),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: hint,
                  hintStyle: AppText.body(15, color: AppColors.textSecondary),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: 'Send',
            child: GestureDetector(
              onTap: sending ? null : onSend,
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sending ? AppColors.accent.withValues(alpha: 0.5) : AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.ink),
                      )
                    : const Icon(Icons.arrow_upward_rounded, size: 22, color: AppColors.ink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
