import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class GeminiAssistantModal extends ConsumerStatefulWidget {
  const GeminiAssistantModal({super.key});

  @override
  ConsumerState<GeminiAssistantModal> createState() => _GeminiAssistantModalState();
}

class _GeminiAssistantModalState extends ConsumerState<GeminiAssistantModal> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'model',
      'content': 'Hello! I am Setu AI, your Daansetu impact assistant. How can I help you make a difference today?',
    }
  ];
  bool _isTyping = false;
  bool _isListening = false;
  final stt.SpeechToText _speech = stt.SpeechToText();

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (val) => debugPrint('Error: $val'),
    );

    if (available) {
      setState(() => _isListening = true);
      HapticFeedback.mediumImpact();
      _speech.listen(
        onResult: (val) {
          setState(() {
            _messageController.text = val.recognizedWords;
          });
        },
      );
    } else {
      if (mounted) CustomSnackBar.error(context, 'Speech recognition not available');
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _messageController.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final response = await ref.read(apiClientProvider).aiChat(
        text,
        history: _messages.sublist(0, _messages.length - 1),
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _messages.add({
            'role': 'model',
            'content': response.data['data'],
          });
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(context, 'Failed to get AI response');
        setState(() => _isTyping = false);
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.lightGray)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryRed, AppTheme.accentOrange],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setu AI Assistant',
                      style: TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(
                      'Powering impact with intelligence',
                      style: TextStyle(color: AppTheme.darkGray, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.offWhite,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppTheme.gray, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return _buildMessageBubble(msg['content'], isUser);
              },
            ),
          ),

          // Typing Indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.offWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const SizedBox(
                      width: 24,
                      height: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CircleAvatar(radius: 2, backgroundColor: AppTheme.gray),
                          CircleAvatar(radius: 2, backgroundColor: AppTheme.gray),
                          CircleAvatar(radius: 2, backgroundColor: AppTheme.gray),
                        ],
                      ),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.seconds),
                  ),
                ],
              ),
            ),

          // Input
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            decoration: const BoxDecoration(
              color: AppTheme.white,
              border: Border(top: BorderSide(color: AppTheme.lightGray)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: AppTheme.charcoal),
                    decoration: InputDecoration(
                      hintText: 'Ask Setu AI anything...',
                      hintStyle: const TextStyle(color: AppTheme.gray),
                      prefixIcon: _isListening 
                        ? Container(
                            padding: const EdgeInsets.all(12),
                            child: const CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRed),
                          ).animate(onPlay: (c) => c.repeat()).fade()
                        : IconButton(
                            icon: const Icon(Icons.mic_rounded, color: AppTheme.primaryRed),
                            onPressed: _startListening,
                          ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.offWhite,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryRed, AppTheme.accentOrange],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryRed : AppTheme.offWhite,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          border: isUser ? null : Border.all(color: AppTheme.lightGray),
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isUser ? Colors.white : AppTheme.charcoal,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: isUser ? 0.1 : -0.1),
    );
  }
}
