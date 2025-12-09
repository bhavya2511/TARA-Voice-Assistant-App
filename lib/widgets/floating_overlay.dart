import 'package:flutter/material.dart';

class FloatingRingButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isListening;

  const FloatingRingButton({
    Key? key,
    required this.onPressed,
    required this.isListening,
  }) : super(key: key);

  @override
  State<FloatingRingButton> createState() => _FloatingRingButtonState();
}

class _FloatingRingButtonState extends State<FloatingRingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 20.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: widget.isListening
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: _pulseAnimation.value,
                      spreadRadius: _pulseAnimation.value / 2,
                    ),
                  ],
                )
              : null,
          child: Transform.scale(
            scale: widget.isListening ? _scaleAnimation.value : 1.0,
            child: FloatingActionButton(
              onPressed: widget.onPressed,
              backgroundColor: widget.isListening ? Colors.red : Colors.blue,
              child: Icon(
                widget.isListening ? Icons.mic : Icons.mic_none,
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Alternative: Overlay button that persists across screens
// Note: For true system-wide overlay, you'd need flutter_overlay_window package
// and additional native configuration
class PersistentOverlayButton extends StatefulWidget {
  final VoidCallback onTap;

  const PersistentOverlayButton({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  State<PersistentOverlayButton> createState() => _PersistentOverlayButtonState();
}

class _PersistentOverlayButtonState extends State<PersistentOverlayButton> {
  Offset _position = const Offset(300, 500);
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              _position.dx + details.delta.dx,
              _position.dy + details.delta.dy,
            );
          });
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.purple.shade400],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.mic,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}

// Voice Assistant Dialog for elderly-friendly interaction
class VoiceAssistantDialog extends StatelessWidget {
  final String message;
  final bool isListening;
  final VoidCallback? onClose;

  const VoiceAssistantDialog({
    Key? key,
    required this.message,
    this.isListening = false,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TARA Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                ),
              ),
              child: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            
            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            
            // Listening indicator
            if (isListening)
              Column(
                children: [
                  CircularProgressIndicator(
                    color: Colors.blue.shade400,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Listening...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            
            // Close button
            if (!isListening && onClose != null)
              TextButton(
                onPressed: onClose,
                child: const Text(
                  'Close',
                  style: TextStyle(fontSize: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
