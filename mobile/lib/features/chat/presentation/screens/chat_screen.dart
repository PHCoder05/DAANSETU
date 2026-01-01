import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../config/theme.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../core/api/api_client.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String recipientId;
  final String recipientName;
  final String? donationId;

  const ChatScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.donationId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isRecipientTyping = false;
  Timer? _typingDebounce;

  late final SocketService _socketService;

  @override
  void initState() {
    super.initState();
    _socketService = ref.read(socketServiceProvider);
    _initSocketListeners();
    _loadHistory();
  }

  void _initSocketListeners() {
    _socketService.onMessageReceived((data) {
      if (mounted) {
        setState(() {
          _messages.add({
            'senderId': data['sender']['_id'] ?? data['sender'], 
            'content': data['content'],
            'time': DateTime.parse(data['createdAt']),
            'isMe': false,
          });
          _isRecipientTyping = false; // Stop typing when message received
        });
        _scrollToBottom();
      }
    });

    _socketService.onTypingStatus((data) {
      if (mounted && data['sender'] == widget.recipientId) {
        setState(() => _isRecipientTyping = data['isTyping']);
        if (_isRecipientTyping) _scrollToBottom();
      }
    });

    _socketService.onMessageSent((data) {
      // Message sent confirmation
    });
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final response = await ref.read(apiClientProvider).getChatHistory(widget.recipientId);
      if (mounted) {
        setState(() {
          _messages.clear();
          final user = ref.read(authStateProvider).user;
          final List<dynamic> data = response.data is List ? response.data : response.data['messages'] ?? [];
          
          for (var msg in data) {
             _messages.add({
               'senderId': msg['sender'] is Map ? msg['sender']['_id'] : msg['sender'],
               'content': msg['content'],
               'time': DateTime.parse(msg['createdAt']),
               'isMe': (msg['sender'] is Map ? msg['sender']['_id'] : msg['sender']) == user?.id,
             });
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) CustomSnackBar.error(context, 'Failed to load chat history');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onTextChanged(String text) {
    if (_typingDebounce?.isActive ?? false) _typingDebounce!.cancel();
    
    _socketService.sendTyping(recipientId: widget.recipientId, isTyping: true);
    
    _typingDebounce = Timer(const Duration(milliseconds: 1000), () {
       _socketService.sendTyping(recipientId: widget.recipientId, isTyping: false);
    });
  }

  @override
  void dispose() {
    _socketService.off('receive_message');
    _socketService.off('message_sent');
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final user = ref.read(authStateProvider).user;
    if (user == null) return;

    // Optimistic UI update
    setState(() {
      _messages.add({
        'senderId': user.id,
        'content': content,
        'time': DateTime.now(),
        'isMe': true,
      });
    });
    _scrollToBottom();
    _messageController.clear();

    _socketService.sendMessage(
      senderId: user.id,
      recipientId: widget.recipientId,
      content: content,
      donationId: widget.donationId,
    );
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
    return Scaffold(
      backgroundColor: AppTheme.scaffoldLight,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 1,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
              child: Text(
                widget.recipientName.isNotEmpty ? widget.recipientName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 14, color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipientName,
                    style: const TextStyle(fontSize: 16, color: AppTheme.black, fontWeight: FontWeight.bold),
                  ),
                  if (widget.donationId != null)
                    Text(
                      'Re: Donation #${widget.donationId!.substring(widget.donationId!.length - 6)}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.gray),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
            IconButton(
                icon: const Icon(Icons.phone, color: AppTheme.primaryRed),
                onPressed: () {
                    CustomSnackBar.info(context, 'Calling ${widget.recipientName}...');
                },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryRed.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.mark_chat_unread_outlined, size: 64, color: AppTheme.primaryRed.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Say hello!', 
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: AppTheme.charcoal
                          )
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation with ${widget.recipientName}',
                          style: const TextStyle(color: AppTheme.gray),
                        ),
                      ],
                    ).animate().fade().scale(),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _messages.length + (_isRecipientTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                        if (index == _messages.length) {
                          return _isRecipientTyping
                              ? const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: 12, left: 4),
                                    child: _TypingIndicator(),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }
                        
                        final msg = _messages[index];
                        final isMe = msg['isMe'];
                        final bool isFirstInSequence = index == 0 || _messages[index - 1]['isMe'] != isMe;
                        final bool isLastInSequence = index == _messages.length - 1 || _messages[index + 1]['isMe'] != isMe;
                        
                        // Date Header Logic
                        final DateTime date = msg['time'];
                        final DateTime? prevDate = index > 0 ? _messages[index - 1]['time'] : null;
                        final bool showDateHeader = prevDate == null || !_isSameDay(date, prevDate);
                        
                        return Column(
                          children: [
                            if (showDateHeader) _DateHeader(date: date),
                            _ChatBubble(
                              content: msg['content'],
                              isMe: isMe,
                              time: msg['time'],
                              showTail: isLastInSequence,
                              isFirstInSequence: isFirstInSequence,
                            ),
                          ],
                        );
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick Replies
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _QuickReplyChip(label: '👋 Hello', onTap: () => _addQuickReply('Hello 👋')),
                _QuickReplyChip(label: '📦 Is it available?', onTap: () => _addQuickReply('Is it available? 📦')),
                _QuickReplyChip(label: '🙏 Thank you', onTap: () => _addQuickReply('Thank you 🙏')),
                _QuickReplyChip(label: '🚗 On my way', onTap: () => _addQuickReply('On my way 🚗')),
                _QuickReplyChip(label: '📍 Location?', onTap: () => _addQuickReply('Could you share the exact location? 📍')),
              ],
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.offWhite,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: _onTextChanged,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _addQuickReply(String text) {
     _messageController.text = text;
     // Optional: Automatically send? No, let user confirm.
     _messageController.selection = TextSelection.fromPosition(TextPosition(offset: _messageController.text.length));
  }
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}

class _ChatBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final DateTime time;
  final bool showTail;
  final bool isFirstInSequence;

  const _ChatBubble({
    required this.content, 
    required this.isMe, 
    required this.time,
    this.showTail = true,
    this.isFirstInSequence = true,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: showTail ? 12 : 2,
          top: isFirstInSequence ? 4 : 0,
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryRed : AppTheme.white,
          // Re-doing border radius for cleaner logic:
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : (showTail ? 4 : 18)),
            bottomRight: Radius.circular(isMe ? (showTail ? 4 : 18) : 18),
          ),
          boxShadow: [
             if (!isMe)
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                )
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content,
              style: TextStyle(
                color: isMe ? Colors.white : AppTheme.charcoal,
                fontSize: 15,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(time),
              style: TextStyle(
                color: isMe ? Colors.white.withOpacity(0.7) : AppTheme.gray,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.offWhite,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDate(date),
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.gray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }
}

class _QuickReplyChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickReplyChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: AppTheme.offWhite,
        labelStyle: const TextStyle(color: AppTheme.charcoal, fontSize: 12),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(delay: 0),
          const SizedBox(width: 4),
          _Dot(delay: 200),
          const SizedBox(width: 4),
          _Dot(delay: 400),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final int delay;

  const _Dot({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppTheme.gray,
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (controller) => controller.repeat())
    .scale(
      duration: 600.ms,
      delay: delay.ms,
      begin: const Offset(0.5, 0.5),
      end: const Offset(1.2, 1.2),
      curve: Curves.easeInOut,
    )
    .then()
    .scale(
      duration: 600.ms,
      begin: const Offset(1.2, 1.2),
      end: const Offset(0.5, 0.5),
      curve: Curves.easeInOut,
    );
  }
}
