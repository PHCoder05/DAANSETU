import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../config/theme.dart';
import '../../../../core/api/api_client.dart';
import '../../../../shared/widgets/custom_snackbar.dart';

class VoiceFormModal extends ConsumerStatefulWidget {
  const VoiceFormModal({super.key});

  @override
  ConsumerState<VoiceFormModal> createState() => _VoiceFormModalState();
}

class _VoiceFormModalState extends ConsumerState<VoiceFormModal> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Describe your donation...';
  bool _isInitializing = true;
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
            if (_text != 'Describe your donation...' && _text.isNotEmpty) {
              _processQuery(_text);
            }
          }
        },
        onError: (val) => print('Error: $val'),
      );
      if (available) {
        setState(() => _isInitializing = false);
        _startListening();
      } else {
        if (mounted) {
          CustomSnackBar.error(context, 'Speech recognition not available');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(context, 'Error initializing voice assistant');
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
      final response = await ref.read(apiClientProvider).voiceForm(query);
      if (response.statusCode == 200 && mounted) {
        final data = response.data['data'];
        Navigator.pop(context, data);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(context, 'AI could not understand the description. Try again.');
        setState(() => _isParsing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Setu AI Voice Assistant',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell me what you are donating today',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 40),
          
          // Visualizer
          Stack(
            alignment: Alignment.center,
            children: [
              if (_isListening)
                ...List.generate(3, (index) => 
                  Container(
                    width: 100 + (index * 30),
                    height: 100 + (index * 30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryRed.withOpacity(0.2 - (index * 0.05))),
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                   .scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: (1000 + (index * 200)).ms)
                   .fadeOut(duration: (1000 + (index * 200)).ms)
                ),
              
              GestureDetector(
                onTap: _isListening ? _stopListening : _startListening,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFE23744), Color(0xFFFF4E50)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.redAccent, blurRadius: 20, spreadRadius: 2),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Recognized Text
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _isParsing 
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Text('Setu AI is processing...', style: TextStyle(color: Colors.white70)),
                  ],
                )
              : Text(
                  _text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
          ).animate(target: _isListening ? 1 : 0).fadeIn(),
          
          const SizedBox(height: 24),
          const Text(
            'e.g., "I want to donate 10 fresh bread packets and some fruit."',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
