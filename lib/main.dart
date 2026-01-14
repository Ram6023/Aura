import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const AuraApp());
}

class AuraApp extends StatelessWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AURA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
        primaryColor: Colors.cyan,
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyan,
          secondary: Colors.cyanAccent,
          surface: Color(0xFF0A0A0A),
        ),
        fontFamily: 'Courier', // Monospaced for sci-fi feel
      ),
      home: const AuraMainScreen(),
    );
  }
}

enum AssistantState {
  IDLE,
  STANDBY,
  LISTENING,
  PROCESSING,
  SPEAKING,
  ERROR
}

class AuraMainScreen extends StatefulWidget {
  const AuraMainScreen({super.key});

  @override
  State<AuraMainScreen> createState() => _AuraMainScreenState();
}

class _AuraMainScreenState extends State<AuraMainScreen> {
  bool _initialized = false;
  AssistantState _state = AssistantState.IDLE;
  String _transcript = '';
  final List<String> _logs = [
    'SYSTEM_BOOT_SEQUENCE_INITIATED...',
    'CORE_MODULES_LOADED: [OK]',
    'NEURAL_ENGINE_STATUS: STANDBY',
  ];

  void _initializeSystem() {
    setState(() {
      _initialized = true;
      _state = AssistantState.STANDBY;
      _addLog('SYSTEM_INITIALIZED_SUCCESSFULLY');
      _addLog('AURA_V4.0.0_ONLINE');
    });
  }

  void _toggleListening() {
    setState(() {
      if (_state == AssistantState.LISTENING) {
        _state = AssistantState.IDLE;
        _addLog('AUDIO_INPUT_TERMINATED');
      } else {
        _state = AssistantState.LISTENING;
        _addLog('AUDIO_INPUT_ACTIVE');
        _simulateProcessing();
      }
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toIso8601String().substring(11, 19)}] $message');
    });
  }

  void _simulateProcessing() {
    Future.delayed(const Duration(seconds: 2), () {
      if (_state == AssistantState.LISTENING) {
        setState(() {
          _transcript = "Hello Aura, what is the system status?";
          _state = AssistantState.PROCESSING;
          _addLog('PROCESSING_USER_QUERY');
        });
        
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            _state = AssistantState.SPEAKING;
            _addLog('RESPONSE_GENERATED');
          });
          
          Future.delayed(const Duration(seconds: 2), () {
            setState(() {
              _state = AssistantState.STANDBY;
              _transcript = "";
            });
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        body: Stack(
          children: [
            // Background Image Placeholder
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: Image.network(
                  'https://picsum.photos/1920/1080?grayscale&blur=2',
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) => Container(color: Colors.grey[900]),
                ),
              ),
            ),
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'AURA',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyan,
                        shadows: [Shadow(color: Colors.cyan, blurRadius: 20)],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ADVANCED USER RESPONSIVE AUTOMATION',
                      style: TextStyle(
                        color: Colors.cyan.withOpacity(0.7),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.1),
                        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.security, color: Colors.cyan, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'SECURITY CHECK',
                                style: TextStyle(
                                  color: Colors.cyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Microphone access and API Key validation required.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _initializeSystem,
                            icon: const Icon(Icons.power_settings_new),
                            label: const Text('INITIALIZE SYSTEM'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan.withOpacity(0.2),
                              foregroundColor: Colors.cyan,
                              side: BorderSide(color: Colors.cyan.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('v4.0.0 // STANDBY', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Grid Background Effect (Simplified)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.cyan.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'AURA',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan,
                            shadows: [Shadow(color: Colors.cyan, blurRadius: 10)],
                          ),
                        ),
                        Text(
                          'ADVANCED VIRTUAL ASSISTANT',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.cyanAccent,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ONLINE',
                          style: TextStyle(
                            color: Colors.cyan.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      // Left Panel: Visualizer
                      Expanded(
                        flex: 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.cyan.withOpacity(0.05),
                            border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Text(
                                  'VISUAL_FEED_01',
                                  style: TextStyle(
                                    color: Colors.cyan.withOpacity(0.7),
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Arc Reactor / Visualizer Placeholder
                                    Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _state == AssistantState.LISTENING 
                                              ? Colors.red 
                                              : Colors.cyan,
                                          width: 4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _state == AssistantState.LISTENING 
                                                ? Colors.red.withOpacity(0.5)
                                                : Colors.cyan.withOpacity(0.5),
                                            blurRadius: 30,
                                            spreadRadius: 5,
                                          )
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.mic,
                                        size: 64,
                                        color: _state == AssistantState.LISTENING 
                                            ? Colors.red 
                                            : Colors.cyan,
                                      ),
                                    ),
                                    const SizedBox(height: 48),
                                    if (_state == AssistantState.STANDBY)
                                      Text(
                                        'SAY "HEY AURA" TO ACTIVATE',
                                        style: TextStyle(
                                          color: Colors.cyan.withOpacity(0.5),
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    if (_state == AssistantState.LISTENING)
                                      const Text(
                                        'LISTENING...',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    if (_transcript.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16.0),
                                        child: Text(
                                          '"$_transcript"',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            shadows: [Shadow(color: Colors.white, blurRadius: 5)],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Controls
                              Positioned(
                                bottom: 32,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: IconButton(
                                    onPressed: _toggleListening,
                                    icon: Icon(
                                      _state == AssistantState.LISTENING ? Icons.mic_off : Icons.mic,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: _state == AssistantState.LISTENING
                                          ? Colors.red.withOpacity(0.2)
                                          : Colors.cyan.withOpacity(0.2),
                                      foregroundColor: _state == AssistantState.LISTENING
                                          ? Colors.red
                                          : Colors.cyan,
                                      padding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right Panel: Terminal
                      Expanded(
                        flex: 7,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            border: Border.all(color: Colors.cyan.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '> SYSTEM_LOGS_ACTIVE',
                                style: TextStyle(
                                  color: Colors.greenAccent.withOpacity(0.8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(color: Colors.cyan, height: 24),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _logs.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Text(
                                        _logs[index],
                                        style: TextStyle(
                                          color: Colors.cyan.withOpacity(0.8),
                                          fontSize: 12,
                                          fontFamily: 'Courier',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.cyan.withOpacity(0.05),
                                child: Row(
                                  children: [
                                    const Text('>', style: TextStyle(color: Colors.cyan)),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 10,
                                      height: 20,
                                      color: Colors.cyan,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }
}
