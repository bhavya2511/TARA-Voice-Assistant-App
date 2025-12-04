import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'contact_service.dart';
import 'phone_service.dart';
import 'whatsapp_service.dart';
import 'paytm_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';

class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<void> speakAndSnack(BuildContext context, String message) async {
    debugPrint(message);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    await _tts.speak(message);
  }

  Future<void> handleCallCommand(BuildContext context, String command) async {
    String contactName = command
        .replaceAll(RegExp(r'call|make a call to|call my', caseSensitive: false), '')
        .trim();
    if (contactName.isEmpty) {
      await speakAndSnack(context, 'Please say the name of the contact to call.');
      return;
    }
    await speakAndSnack(context, 'Searching for $contactName in your contacts.');
    final phone = await getPhoneNumberFromContact(contactName);
    if (phone != null) {
      await speakAndSnack(context, 'Calling $contactName.');
      await makePhoneCall(phone);
    } else {
      await speakAndSnack(context, 'Sorry, I could not find $contactName in your contacts.');
    }
  }

  Future<void> handleChatCommand(BuildContext context, String command) async {
    String contactName = command
        .replaceAll(RegExp(r'chat|message|talk to|i want to talk to|i want to message|text', caseSensitive: false), '')
        .trim();
    if (contactName.isEmpty) {
      await speakAndSnack(context, 'Please say the name of the contact you want to message.');
      return;
    }

    await speakAndSnack(context, 'Searching for $contactName in your contacts.');
    final phone = await getPhoneNumberFromContact(contactName);
    if (phone == null) {
      await speakAndSnack(context, 'Sorry, I could not find $contactName in your contacts.');
      return;
    }

    await speakAndSnack(context, 'What message would you like to send to $contactName?');

    bool speechAvailable = await _speech.initialize();
    if (!speechAvailable) {
      await speakAndSnack(context, 'Speech recognition is not available.');
      return;
    }

    await _speech.listen(onResult: (result) async {
      if (result.finalResult && result.recognizedWords.isNotEmpty) {
        String userMessage = result.recognizedWords;
        await speakAndSnack(context, 'Opening WhatsApp and typing your message.');
        await openWhatsApp(phone: phone, message: userMessage);
        await _speech.stop();
      }
    });
  }

  Future<void> handlePaytmCommand(BuildContext context) async {
    await speakAndSnack(context, 'Opening Paytm for payment.');
    bool success = await openPaytm();
    if (!success) {
      await speakAndSnack(context, 'Paytm app not found. Opening Play Store.');
    }
  }
}
