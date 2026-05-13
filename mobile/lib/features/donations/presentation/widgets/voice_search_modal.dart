import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

class VoiceSearchModal extends ConsumerStatefulWidget {
  const VoiceSearchModal({super.key});

  @override
  ConsumerState<VoiceSearchModal> createState() => _VoiceSearchModalState();
}

class _VoiceSearchModalState extends ConsumerState<VoiceSearchModal> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Listening...';
  bool _isParsing = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
            if (_text != 'Listening...' && _text.isNotEmpty) {
              _processQuery(_text);
            }
          }
        },
        onError: (val) => debugPrint('Error: $val'),
      );
      if (available) {
        _startListening();
      } else {
        if (mounted) {
          CustomSnackBar.error(context, 'Speech recognition not available');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(context, 'Error initializing voice search');
        Navigator.pop(context);
      }
    }
  }

  void _startListening() async {
    await _speech.listen(
      onResult: (val) => setState(() {
        _text = val.recognizedWords;
      }),
    );
    setState(() => _isListening = true);
    HapticFeedback.mediumImpact();
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _processQuery(String query) async {
    setState(() => _isParsing = true);
    try {
      final response = await ref.read(apiClientProvider).voiceSearch(query);
      if (response.statusCode == 200 && mounted) {
        final filters = response.data['data'];
        Navigator.pop(context, filters);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(context, 'AI could not understand the query. Try again.');
        setState(() => _isParsing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 32),
          Text(
            _isParsing ? 'Processing with AI...' : (_isListening ? 'Go ahead, I\'m listening' : 'Processing...'),
            style: const TextStyle(color: AppTheme.darkGray, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          Text(
            _text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.charcoal, fontSize: 24, fontWeight: FontWeight.bold, height: 1.4),
          ),
          const SizedBox(height: 48),
          _buildWaveform(),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _IconButton(
                icon: Icons.close,
                onTap: () => Navigator.pop(context),
                color: AppTheme.offWhite,
              ),
              const SizedBox(width: 32),
              GestureDetector(
                onTap: _isListening ? _stopListening : _startListening,
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppTheme.primaryRed.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 5),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white, size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 32),
              _IconButton(
                icon: Icons.keyboard_rounded,
                onTap: () => Navigator.pop(context, 'keyboard'),
                color: AppTheme.offWhite,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Try: "Find food donations in Mumbai" or "Search for blood banks"',
            style: TextStyle(color: AppTheme.gray, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform() {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          return Container(
            width: 6,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(3),
            ),
          )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleY(
            begin: 0.2, end: 1.0,
            duration: Duration(milliseconds: 300 + (index * 100)),
            curve: Curves.easeInOut,
          );
        }),
      ),
    ).animate(target: _isListening ? 1 : 0).fade();
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _IconButton({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: AppTheme.charcoal, size: 24),
      ),
    );
  }
}
