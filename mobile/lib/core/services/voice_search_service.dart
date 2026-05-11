import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final voiceSearchServiceProvider = Provider((ref) => VoiceSearchService());

class VoiceSearchService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return false;

    _isInitialized = await _speech.initialize(
      onError: (val) => debugPrint('Speech Error: $val'),
      onStatus: (val) => debugPrint('Speech Status: $val'),
    );
    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required Function() onEnd,
  }) async {
    if (!_isInitialized) await initialize();

    await _speech.listen(
      onResult: (val) {
        if (val.finalResult) {
          onResult(val.recognizedWords);
          onEnd();
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
