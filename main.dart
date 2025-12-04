import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'services/voice_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(TaraVoiceAssistantApp(cameras: cameras));
}

class TaraVoiceAssistantApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const TaraVoiceAssistantApp({required this.cameras, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VoiceHome(cameras: cameras),
      debugShowCheckedModeBanner: false,
    );
  }
}

class VoiceHome extends StatefulWidget {
  final List<CameraDescription> cameras;
  const VoiceHome({required this.cameras, super.key});

  @override
  State<VoiceHome> createState() => _VoiceHomeState();
}

class _VoiceHomeState extends State<VoiceHome> {
  final VoiceService _voiceService = VoiceService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  String _recognizedText = 'Tap the mic and speak';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speech.initialize();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  void _startListening() async {
    await _speech.listen(onResult: (result) async {
      setState(() {
        _recognizedText = result.recognizedWords;
      });
      if (result.finalResult && result.recognizedWords.isNotEmpty) {
        await _handleCommand(result.recognizedWords.toLowerCase());
      }
    });
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _handleCommand(String command) async {
  if (command.contains('open camera')) {
    await _speak('Opening camera');
    if (widget.cameras.isNotEmpty) {
      if (mounted) {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => TakePictureScreen(camera: widget.cameras.first)));
      }
    } else {
      await _speak('No camera found');
    }
  } else if (command.startsWith('call ') ||
      command.contains('make a call to') ||
      command.contains('call my')) {
    await _voiceService.handleCallCommand(context, command);
  } else if (command.contains('chat') ||
      command.contains('talk to') ||
      command.contains('message')) {
    await _voiceService.handleChatCommand(context, command);
  } else if (command.contains('paytm') ||
      command.contains('payment') ||
      command.contains('make payment')) {
    await _voiceService.handlePaytmCommand(context);
  } else {
    await _speak('Sorry, I did not understand that command.');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TARA Voice Assistant')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _recognizedText,
            style: const TextStyle(fontSize: 22),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isListening ? _stopListening : _startListening,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      ),
    );
  }
}

class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;
  const TakePictureScreen({required this.camera, super.key});

  @override
  State<TakePictureScreen> createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = join(directory.path, fileName);
      await image.saveTo(filePath);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DisplayPictureScreen(imagePath: filePath),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error taking picture: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  const DisplayPictureScreen({required this.imagePath, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Captured Picture')),
      body: Center(child: Image.file(File(imagePath))),
    );
  }
}
