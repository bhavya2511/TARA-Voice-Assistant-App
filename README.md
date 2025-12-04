TARA is a Flutter-based voice assistant that helps users perform everyday actions like making phone calls, sending WhatsApp messages, adding contacts, and initiating payments using natural voice commands.
It is designed as a modular, extensible project that showcases clean architecture, state management with Provider, and integration of speech-to-text (STT) and text-to-speech (TTS) in a production-style Flutter app.

Features
Hands-free voice control

Activate TARA and speak commands such as:

“Call Mom”

“Send WhatsApp to Alex”

“Make a payment to Riya”

“Add new contact”

Smart command routing

Parses the recognized text and routes it to the correct flow:

PhoneCommandScreen for calls

WhatsAppCommandScreen for WhatsApp messages

PaymentCommandScreen for payments

AddContactScreen for contact creation

Speech-to-Text & Text-to-Speech integration

Uses STT to capture user commands.

Uses TTS to greet the user and provide feedback (“Hello! I am TARA. How can I help you today?” and error/help messages).

Modular service layer

VoiceService for STT/TTS and command handling.

PhoneService for phone actions.

WhatsAppService for messaging.

PaytmService (or similar) for payment intents.

ContactService for contact handling.

Clean, modern UI

Central home screen with:

Animated mic icon and gradient avatar for TARA.

Status text (“Listening…” / “Tap to activate”).

Clear feature list.

Floating ring button for quick activation from anywhere in the app.

Architecture Overview
TARA is structured to be readable, testable, and easy to extend:

State management:

Uses the provider package to expose VoiceService and other services to the widget tree.

HomeScreen listens to state changes like _isListening to update UI reactively.

Layered design:

UI layer: screens (HomeScreen, PhoneCommandScreen, WhatsAppCommandScreen, PaymentCommandScreen, AddContactScreen) and widgets (FloatingRingButton, feature list items).

Service layer: encapsulates platform-specific logic (contacts, calls, messaging, payments, reminders, etc.).

Integration layer: VoiceService orchestrates STT/TTS and delegates actions to other services.

Command processing:

Raw recognized text is normalized to lowercase.

Simple keyword-based intent detection:

contains('call') → phone flow

contains('message') or contains('whatsapp') → WhatsApp flow

contains('pay') or contains('payment') → payment flow

contains('add contact') or contains('new contact') → contact creation

If no intent is matched, TARA responds with a helpful hint about supported commands.

This design makes it straightforward to plug in more advanced NLU (e.g., Dialogflow, Rasa, LLM APIs) later without rewriting the UI.

Tech Stack
Frontend: Flutter (Dart)

State Management: Provider

Voice:

Speech-to-Text package (e.g., speech_to_text)

Text-to-Speech package (e.g., flutter_tts)

Platform integrations:

Phone dialer

WhatsApp deep links/intents

Payment app integration (e.g., Paytm / Google Pay, depending on implementation)

Contacts API for reading/adding contacts (where supported)

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

