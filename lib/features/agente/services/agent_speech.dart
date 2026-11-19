import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

String dictationText(String prefix, String spoken) {
  final base = prefix.trim();
  final words = spoken.trim();
  final text = base.isEmpty
      ? words
      : words.isEmpty
      ? base
      : '$base $words';
  return text.length > 1500 ? text.substring(0, 1500) : text;
}

String speechErrorMessage(String code) {
  switch (code) {
    case 'error_permission':
    case 'error_speech_recognizer_disabled':
      return 'Activa el micrófono para dictar tu mensaje.';
    case 'error_network':
    case 'error_network_timeout':
      return 'No hay conexión para reconocer la voz. Puedes escribir el mensaje.';
    default:
      return 'No se pudo usar el micrófono. Puedes escribir el mensaje.';
  }
}

class AgentSpeech {
  AgentSpeech({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;

  Future<bool> start({
    required void Function(String words) onWords,
    required void Function(String message) onError,
    required VoidCallback onDone,
  }) async {
    final ready = await _speech.initialize(
      onError: (error) {
        final quiet =
            error.errorMsg == 'error_no_match' ||
            error.errorMsg == 'error_speech_timeout';
        if (!quiet) onError(speechErrorMessage(error.errorMsg));
        onDone();
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') onDone();
      },
    );
    if (!ready) return false;
    await _speech.listen(
      onResult: (result) => onWords(result.recognizedWords),
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        localeId: await _spanishLocale(),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
    );
    return true;
  }

  Future<void> stop() => _speech.stop();

  Future<String?> _spanishLocale() async {
    try {
      final locales = await _speech.locales();
      String? spanish;
      for (final locale in locales) {
        final id = locale.localeId.toLowerCase().replaceAll('-', '_');
        if (id.startsWith('es_bo')) return locale.localeId;
        spanish ??= id.startsWith('es') ? locale.localeId : null;
      }
      return spanish;
    } catch (_) {
      return null;
    }
  }
}
