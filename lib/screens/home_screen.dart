import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_service.dart';
import '../widgets/floating_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeVoiceService();
  }

  Future<void> _initializeVoiceService() async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    await voiceService.initialize();
  }

  void _activateVoiceAssistant() async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    
    setState(() {
      _isListening = true;
    });

    // Speak greeting
    await voiceService.speak("Hello! I am TARA. How can I help you today?");
    
    // Start listening for commands
    await voiceService.startListening((recognizedText) {
      _processVoiceCommand(recognizedText);
    });
  }

  void _processVoiceCommand(String command) async {
    final voiceService = Provider.of<VoiceService>(context, listen: false);
    
    // Stop listening while processing
    setState(() {
      _isListening = false;
    });

    // Process command based on keywords
    String lowerCommand = command.toLowerCase();
    
    if (lowerCommand.contains('call')) {
      _handlePhoneCommand(lowerCommand);
    } else if (lowerCommand.contains('message') || lowerCommand.contains('whatsapp')) {
      _handleWhatsAppCommand(lowerCommand);
    } else if (lowerCommand.contains('pay') || lowerCommand.contains('payment')) {
      _handlePaymentCommand(lowerCommand);
    } else if (lowerCommand.contains('add contact') || lowerCommand.contains('new contact')) {
      _handleAddContact();
    } else {
      await voiceService.speak("I'm sorry, I didn't understand that. You can ask me to make a call, send a WhatsApp message, or make a payment.");
    }
  }

  void _handlePhoneCommand(String command) {
    // Navigate to phone call screen with command
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhoneCommandScreen(command: command),
      ),
    );
  }

  void _handleWhatsAppCommand(String command) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WhatsAppCommandScreen(command: command),
      ),
    );
  }

  void _handlePaymentCommand(String command) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentCommandScreen(command: command),
      ),
    );
  }

  void _handleAddContact() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddContactScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TARA Logo/Icon
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              
              // App Title
              const Text(
                'TARA',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your Voice Assistant',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 60),
              
              // Status Text
              Text(
                _isListening ? 'Listening...' : 'Tap to activate',
                style: TextStyle(
                  fontSize: 18,
                  color: _isListening ? Colors.blue : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
              
              // Activate Button
              ElevatedButton(
                onPressed: _isListening ? null : _activateVoiceAssistant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Say "Hello TARA"',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Features List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: const [
                    FeatureItem(
                      icon: Icons.phone,
                      text: 'Make calls & add contacts',
                    ),
                    SizedBox(height: 15),
                    FeatureItem(
                      icon: Icons.chat,
                      text: 'Send WhatsApp messages',
                    ),
                    SizedBox(height: 15),
                    FeatureItem(
                      icon: Icons.payment,
                      text: 'Make Google Pay payments',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      
      // Floating Action Button (Alternative to overlay)
      floatingActionButton: FloatingRingButton(
        onPressed: _activateVoiceAssistant,
        isListening: _isListening,
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const FeatureItem({
    Key? key,
    required this.icon,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 28),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }
}

// Placeholder screens - these will be implemented in separate files
class PhoneCommandScreen extends StatelessWidget {
  final String command;
  const PhoneCommandScreen({Key? key, required this.command}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Call')),
      body: Center(child: Text('Processing: $command')),
    );
  }
}

class WhatsAppCommandScreen extends StatelessWidget {
  final String command;
  const WhatsAppCommandScreen({Key? key, required this.command}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WhatsApp')),
      body: Center(child: Text('Processing: $command')),
    );
  }
}

class PaymentCommandScreen extends StatelessWidget {
  final String command;
  const PaymentCommandScreen({Key? key, required this.command}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Center(child: Text('Processing: $command')),
    );
  }
}

class AddContactScreen extends StatelessWidget {
  const AddContactScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Contact')),
      body: const Center(child: Text('Add Contact Screen')),
    );
  }
}
