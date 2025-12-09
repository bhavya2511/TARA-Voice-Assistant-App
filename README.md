TARA – Voice Assistant App for Elderly (Android)

TARA is an Android voice assistant application built using Flutter to help elderly users perform everyday digital tasks through simple voice commands.
The app focuses on accessibility, accuracy, and ease of use, reducing dependency on complex touch-based interactions.

🎯 Problem Statement

Many elderly users struggle with:

Small touch targets and complex mobile UIs

Typing messages and navigating apps

Remembering multi-step digital workflows

TARA addresses this by enabling hands-free interaction using voice commands for common tasks.

✨ Features

📞 Voice-based Phone Calls
Make calls using natural voice commands.

💬 Voice-driven WhatsApp Messaging
Send messages without typing.

💳 Voice-guided Payments
Step-by-step confirmation to avoid accidental transactions.

👴 Elderly-Friendly UI
Large buttons, minimal screens, and clear voice feedback.

🛠️ Tech Stack

Frontend & App Framework

Flutter (Dart)

Voice Processing

Speech-to-Text (STT)

Text-to-Speech (TTS)

Android APIs

Android Contacts API

Permissions & Intent handling

Logic & Matching

Rule-based command parsing

Fuzzy string matching for contact name resolution

🧠 How It Works

User speaks a command (e.g., “Call Ramesh”)

Speech is converted to text using STT

The command is parsed using rule-based logic

Contact names are fetched from the device using Android Contacts API

Fuzzy matching is applied to match spoken names with stored contacts

The app executes the requested action with voice confirmation

🔍 Key Contributions

Designed and implemented custom voice interaction flows optimized for elderly speech patterns

Improved command reliability using fuzzy logic for approximate name matching

Handled edge cases such as partial names, mispronunciations, and unclear commands

Built and tested a fully functional Android application deployed on a physical device

📱 Platform Support

✅ Android (Tested on physical Android device)

❌ iOS (Not supported)

🚀 Installation & Setup
git clone https://github.com/your-username/tara-voice-assistant.git
cd tara-voice-assistant
flutter pub get
flutter run


Ensure microphone and contact permissions are enabled on the device.

🧪 Testing

Tested on real Android devices

Verified accuracy across different voice speeds and accents

Manually tested error handling and fallback voice prompts

📌 Future Improvements

Multi-language voice support

Offline speech recognition

Emergency contact quick-dial

Payment security enhancements
