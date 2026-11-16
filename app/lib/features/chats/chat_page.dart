import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/ui.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../../l10n/generated/app_localizations.dart';
import 'chats_controller.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _message = TextEditingController();
  Timer? _timer;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) {
        return;
      }
      ref.invalidate(messagesProvider(widget.id));
      ref.invalidate(conversationProvider(widget.id));
      _markRead();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _message.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    try {
      await ref.read(apiProvider).markRead(widget.id);
      ref.invalidate(chatsProvider);
    } catch (_) {
      // Reading is best-effort; the next poll retries.
    }
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(apiProvider).sendMessage(widget.id, text);
      _message.clear();
      ref.invalidate(messagesProvider(widget.id));
      ref.invalidate(conversationProvider(widget.id));
      ref.invalidate(chatsProvider);
    } catch (error) {
      if (mounted) {
        showErrorSnack(context, error);
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final conversation = ref.watch(conversationProvider(widget.id)).value;
    final messages = ref.watch(messagesProvider(widget.id));

    final title = conversation == null
        ? localizations.navChats
        : localizedTitle(
            context,
            en: conversation.propertyTitleEn,
            ar: conversation.propertyTitleAr,
          );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (conversation != null)
              Text(
                conversation.otherPartyName,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessages(
              messages,
              localizations,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: localizations.messageHint,
                        counterText: '',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    tooltip: localizations.sendMessage,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(
    AsyncValue<List<Message>> messages,
    AppLocalizations localizations,
  ) {
    final items = messages.value;
    if (items == null && messages.hasError) {
      return ErrorView(
        error: messages.error,
        onRetry: () => ref.invalidate(messagesProvider(widget.id)),
      );
    }
    if (items == null) {
      return const LoadingView();
    }
    if (items.isEmpty) {
      return EmptyView(
        icon: Icons.chat_bubble_outline,
        title: localizations.chatEmpty,
        body: localizations.startingChatHint,
      );
    }
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final message = items[items.length - 1 - index];
        return _MessageBubble(message: message);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mine = message.mine;
    final foreground = mine ? colors.onPrimary : colors.onSurface;

    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        decoration: BoxDecoration(
          color: mine ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.body,
              style: TextStyle(color: foreground, height: 1.4),
            ),
            const SizedBox(height: 4),
            Text(
              formatTime(context, message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: foreground.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
