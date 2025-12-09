// lib/services/voice_service.dart
// Improved voice service that uses ContactService.findContactBySpokenName
// and supports automatic follow-up listening after prompts.

import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'contact_service.dart';
import 'phone_service.dart';
import 'whatsapp_service.dart';
import 'paytm_service.dart';
import 'reminder_service.dart';

typedef PartialCallback = void Function(String text);
typedef FinalCallback = void Function(String text);
typedef StatusCallback = void Function(String status);
typedef SpeakCallback = void Function(String message);

class CommandResult {
  final String message;
  CommandResult(this.message);
}

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  final PartialCallback onPartialResult;
  final FinalCallback onFinalResult;
  final StatusCallback onStatus;
  final SpeakCallback speakCallback;

  // Follow-up / context state:
  String? _pendingMessageRecipientName;
  String? _pendingMessageRecipientNumber;
  bool _awaitingMessageBody = false;

  // Silence / finalization timer
  Duration silenceTimeout;
  Timer? _finalizeTimer;
  String _lastPartial = '';

  // Whether we are in a follow-up listen started automatically after a prompt.
  bool _isFollowUpListen = false;

  VoiceService({
    required this.onPartialResult,
    required this.onFinalResult,
    required this.onStatus,
    required this.speakCallback,
    this.silenceTimeout = const Duration(milliseconds: 1800),
  }) {
    try {
      _tts.awaitSpeakCompletion(true);
    } catch (e) {
      // ignore if not available
    }
  }

  bool _isListening = false;

  /// Start listening. If [isFollowUp] is true we mark this as an automated follow-up listen.
  Future<void> startListening({Duration listenFor = const Duration(seconds: 20), bool isFollowUp = false}) async {
    onStatus('initializing');

    // ensure previous listener stopped
    await _stopRecognizer();

    bool available = await _speech.initialize(onStatus: (s) => onStatus('speech_status:$s'));
    if (!available) {
      await _speak('Microphone unavailable');
      onStatus('error');
      return;
    }

    _isListening = true;
    _isFollowUpListen = isFollowUp;
    _lastPartial = '';
    _startRecognizer(listenFor: listenFor);
    onStatus('listening');
  }

  Future<void> _stopRecognizer() async {
    _finalizeTimer?.cancel();
    if (_isListening) {
      try {
        await _speech.stop();
      } catch (e) {
        // ignore
      }
    }
    _isListening = false;
    _isFollowUpListen = false;
  }

  void _startRecognizer({required Duration listenFor}) {
    // Cancel any previous finalize timer
    _finalizeTimer?.cancel();

    _speech.listen(
      onResult: (result) {
        final recognized = result.recognizedWords ?? '';
        _lastPartial = recognized;
        onPartialResult(recognized);

        // If speech_to_text reports final, immediately handle it
        if (result.finalResult) {
          _finalizeTimer?.cancel();
          _handleFinal(recognized);
          return;
        }

        // Reset silence timer
        _finalizeTimer?.cancel();
        _finalizeTimer = Timer(silenceTimeout, () {
          // silence detected — treat last partial as final
          _handleFinal(_lastPartial);
        });
      },
      listenFor: listenFor,
      cancelOnError: true,
      partialResults: true,
    );
  }

  Future<void> stopListening() async {
    onStatus('stopping');
    await _stopRecognizer();
    onStatus('idle');
  }

  Future<void> _handleFinal(String finalText) async {
    // Emit final callback for UI
    onFinalResult(finalText);

    // If we were awaiting a follow-up message body, process it as message content
    if (_awaitingMessageBody && _pendingMessageRecipientNumber != null) {
      final messageBody = finalText.trim();
      _awaitingMessageBody = false;
      final recipientName = _pendingMessageRecipientName ?? 'contact';
      final recipientNumber = _pendingMessageRecipientNumber!;
      // clear pending state before performing async send
      _pendingMessageRecipientName = null;
      _pendingMessageRecipientNumber = null;

      // send message via WhatsApp
      final whatsapp = WhatsappService();
      final ok = await whatsapp.sendMessage(recipientNumber, messageBody);
      await _speak(ok ? 'Message opened in WhatsApp for $recipientName' : 'Could not open WhatsApp to send message');
      // stop recognizer finally
      await _stopRecognizer();
      return;
    }

    // If not a follow-up or nothing special to do, just stop listening
    await _stopRecognizer();
  }

  Future<void> _speak(String text, {bool startFollowUpListenAfter = false, Duration followUpListenDelay = const Duration(milliseconds: 600)}) async {
    speakCallback(text);

    // Use awaitSpeakCompletion where available so we don't start listening while TTS is speaking
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.speak(text);
    } catch (e) {
      try {
        final completer = Completer<void>();
        try {
          _tts.setCompletionHandler(() {
            if (!completer.isCompleted) completer.complete();
          });
        } catch (_) {}
        await _tts.speak(text);
        await Future.any([Future.delayed(const Duration(milliseconds: 600)), completer.future]);
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 700));
      }
    }

    // If caller requested to start automatic follow-up listening, do that now
    if (startFollowUpListenAfter) {
      // small extra safety delay to avoid TTS bleed
      await Future.delayed(followUpListenDelay);
      // Start a follow-up listening session (shorter timeout)
      await startListening(listenFor: const Duration(seconds: 12), isFollowUp: true);
    }
  }

  /// Process an already-captured command text.
  /// Uses ContactService.findContactBySpokenName for robust matching.
  Future<CommandResult> processCommand(
    String input, {
    required ContactService contactService,
    required PhoneService phoneService,
    required WhatsappService whatsappService,
    required PaytmService paytmService,
    ReminderService? reminderService,
  }) async {
    final trimmed = input.trim();
    final lower = trimmed.toLowerCase();

    // If we are awaiting a message body and the recognizer hasn't captured it (edge case),
    // we let the follow-up listen handle the actual send. So here we only manage states.
    if (_awaitingMessageBody) {
      return CommandResult('Awaiting message body');
    }

    // CALL flow
    if (lower.startsWith('call ')) {
      var target = trimmed.substring(5).trim();

      // Prefer smarter matching via ContactService.findContactBySpokenName
      ContactMatch? match;
      // If user said "doctor", strip title and try again (lower minScore)
      if (target.toLowerCase().contains('doctor') || target.toLowerCase().contains('dr')) {
        final stripped = target.replaceAll(RegExp(r'\bdr|doctor\b', caseSensitive: false), '').trim();
        if (stripped.isNotEmpty) {
          match = await contactService.findContactBySpokenName(stripped, minScore: 0.40);
        }
        match ??= await contactService.findContactBySpokenName(target, minScore: 0.6);
      } else {
        match = await contactService.findContactBySpokenName(target, minScore: 0.6);
      }

      if (match != null) {
        await _speak('Calling ${match.contact.displayName}');
        final ok = await phoneService.makeCall(match.phone);
        return CommandResult(ok ? 'Calling ${match.contact.displayName}' : 'Failed to start call');
      } else if (_looksLikeNumber(target)) {
        await _speak('Calling $target');
        final ok = await phoneService.makeCall(target);
        return CommandResult(ok ? 'Calling $target' : 'Failed to start call');
      }
      await _speak('Contact not found for $target');
      return CommandResult('Could not find contact for $target');
    }

    // MESSAGE flow (single utterance or multi-utterance follow up)
    if (lower.startsWith('message ') || lower.startsWith('send message ') || lower.startsWith('whatsapp message ')) {
      final dashIndex = trimmed.indexOf(RegExp(r' - |—|-'));
      String namePart;
      String messagePart = '';
      if (dashIndex >= 0) {
        namePart = trimmed.substring(trimmed.indexOf(' ') + 1, dashIndex).trim();
        messagePart = trimmed.substring(dashIndex + 1).trim();
      } else {
        final parts = trimmed.split(' ');
        if (parts.length >= 2) {
          namePart = parts[1];
          if (parts.length > 2) {
            messagePart = parts.sublist(2).join(' ');
          } else {
            messagePart = '';
          }
        } else {
          return CommandResult('Please say: message <name> - <your message>');
        }
      }

      final match = await contactService.findContactBySpokenName(namePart, minScore: 0.55);
      if (match == null) {
        await _speak('Contact $namePart not found');
        return CommandResult('Contact not found');
      }

      if (messagePart.isEmpty) {
        // set follow-up state and prompt speaker; automatically listen for the reply
        _pendingMessageRecipientName = match.contact.displayName;
        _pendingMessageRecipientNumber = match.phone;
        _awaitingMessageBody = true;
        // Speak the prompt and then start follow-up listening automatically
        await _speak(
          'What message would you like to send to ${match.contact.displayName}?',
          startFollowUpListenAfter: true,
        );
        return CommandResult('Awaiting message for ${match.contact.displayName}');
      } else {
        final ok = await whatsappService.sendMessage(match.phone, messagePart);
        await _speak(ok ? 'Message opened in WhatsApp' : 'Could not open WhatsApp to send message');
        return CommandResult(ok ? 'Message sent' : 'Could not open WhatsApp');
      }
    }

    // PAYMENT flow
    if (lower.startsWith('pay ') || (lower.startsWith('send ') && lower.contains(' to '))) {
      final tokens = lower.split(' ');
      String? amountToken;
      for (var t in tokens) {
        final m = RegExp(r'\d+(\.\d+)?').firstMatch(t);
        if (m != null) {
          amountToken = m.group(0);
          break;
        }
      }
      if (amountToken == null) {
        await _speak('Please say the amount to pay');
        return CommandResult('Could not find amount');
      }

      var toIndex = lower.indexOf(' to ');
      String target = '';
      if (toIndex >= 0) {
        target = trimmed.substring(toIndex + 4).trim();
        target = target.replaceAll(RegExp(r'\bon paytm\b|\bvia paytm\b|\bon upi\b|\bvia upi\b', caseSensitive: false), '').trim();
      }
      if (target.isEmpty) {
        await _speak('Please tell me whom to pay');
        return CommandResult('Please tell me whom to pay');
      }

      final match = await contactService.findContactBySpokenName(target, minScore: 0.55);
      if (match == null) {
        await _speak('Contact $target not found');
        return CommandResult('Recipient not found');
      }

      await _speak('Opening payment app for $amountToken rupees to ${match.contact.displayName}');
      final ok = await paytmService.payTo(match.phone, amountToken);
      return CommandResult(ok ? 'Payment flow started' : 'Could not launch payment app');
    }

    // REMINDERS unchanged
    if (lower.contains('medicine reminder') || lower.contains('remind me medicine') || lower.contains('medicine reminders')) {
      if (lower.contains('stop') || lower.contains('disable') || lower.contains('cancel')) {
        if (reminderService != null) {
          await reminderService.cancelAllReminders();
          await _speak('Medicine reminders cancelled');
          return CommandResult('Reminders cancelled');
        }
        return CommandResult('No reminder service available');
      } else {
        if (reminderService != null) {
          await reminderService.scheduleDailyMedicineReminders();
          await _speak('Medicine reminders scheduled three times a day after meals');
          return CommandResult('Reminders scheduled');
        } else {
          return CommandResult('Reminder service not available');
        }
      }
    }

    await _speak('Sorry, I did not understand. Try again.');
    return CommandResult('Unknown command');
  }

  bool _looksLikeNumber(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^0-9+]'), '');
    return cleaned.length >= 7;
  }
}
