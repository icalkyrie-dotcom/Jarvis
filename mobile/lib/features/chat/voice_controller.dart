import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceController extends ChangeNotifier {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool isListening = false;
  bool isSpeaking = false;
  bool _sttAvailable = false;
  String lastWords = '';

  VoiceController() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('id-ID');
    await _tts.setSpeechRate(0.9);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      isSpeaking = true;
      notifyListeners();
    });

    _tts.setCompletionHandler(() {
      isSpeaking = false;
      notifyListeners();
    });
  }

  Future<bool> initStt() async {
    final status = await Permission.microphone.request();

    if (status != PermissionStatus.granted) {
      return false;
    }

    _sttAvailable = await _stt.initialize(
      onError: (error) {
        isListening = false;
        notifyListeners();
      },
    );

    return _sttAvailable;
  }

  Future<void> startListening({
    required Function(String) onResult,
  }) async {
    if (!_sttAvailable) {
      final ok = await initStt();
      if (!ok) return;
    }

    isListening = true;
    lastWords = '';
    notifyListeners();

    await _stt.listen(
      onResult: (result) {
        lastWords = result.recognizedWords;
        notifyListeners();

        if (result.finalResult && lastWords.isNotEmpty) {
          stopListening();
          onResult(lastWords);
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: 'id_ID',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
    isListening = false;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    isSpeaking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stt.stop();
    _tts.stop();
    super.dispose();
  }
}