// lib/main.dart
import 'package:flutter/material.dart';
import 'services/contact_service.dart';
import 'services/phone_service.dart';
import 'services/whatsapp_service.dart';
import 'services/paytm_service.dart';
import 'services/voice_service.dart';
import 'services/reminder_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ContactService contactService;
  late PhoneService phoneService;
  late WhatsappService whatsappService;
  late PaytmService paytmService;
  late VoiceService voiceService;
  late ReminderService reminderService;

  String _transcript = '';
  String _status = 'idle';
  String _speakMessage = '';

  @override
  void initState() {
    super.initState();
    contactService = ContactService();
    phoneService = PhoneService();
    whatsappService = WhatsappService();
    paytmService = PaytmService();
    reminderService = ReminderService();

    voiceService = VoiceService(
      onPartialResult: (text) {
        setState(() => _transcript = text);
      },
      onFinalResult: (text) async {
        setState(() => _transcript = text);
        // process the final command
        final res = await voiceService.processCommand(
          text,
          contactService: contactService,
          phoneService: phoneService,
          whatsappService: whatsappService,
          paytmService: paytmService,
          reminderService: reminderService,
        );
        setState(() => _status = res.message);
      },
      onStatus: (s) => setState(() => _status = s),
      speakCallback: (s) => setState(() => _speakMessage = s),
    );

    _initAll();
  }

  Future<void> _initAll() async {
    await _requestPermissions();
    await contactService.loadContacts();
    await reminderService.init();
    // schedule default medicine reminders once at startup
    await reminderService.scheduleDailyMedicineReminders();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.contacts.request();
    await Permission.phone.request();
  }

  bool _listening = false;

  Future<void> _toggleListen() async {
    if (_listening) {
      await voiceService.stopListening();
      setState(() => _listening = false);
    } else {
      await voiceService.startListening(listenFor: const Duration(seconds: 12));
      setState(() => _listening = true);
    }
  }

  @override
  void dispose() {
    // any cleanup if necessary
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Elderly Voice Assistant',
      home: Scaffold(
        appBar: AppBar(title: const Text('Voice Assistant')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Status: $_status'),
              const SizedBox(height: 8),
              Text('Speech output: $_speakMessage'),
              const SizedBox(height: 8),
              Text('Transcript: $_transcript'),
              const Spacer(),
              ElevatedButton.icon(
                icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                label: Text(_listening ? 'Stop listening' : 'Tap to speak'),
                onPressed: _toggleListen,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
