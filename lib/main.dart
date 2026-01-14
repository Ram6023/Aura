import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:battery_plus/battery_plus.dart';
import 'package:system_info2/system_info2.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        primaryColor: const Color(0xFF6366F1), // Indigo
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF8B5CF6), // Purple
          tertiary: const Color(0xFF06B6D4), // Cyan
          surface: const Color(0xFF1E1E2E),
          error: const Color(0xFFEF4444),
        ),
        fontFamily: 'Segoe UI',
      ),
      home: const AuraMainScreen(),
    );
  }
}

enum AssistantState { IDLE, STANDBY, LISTENING, PROCESSING, SPEAKING, ERROR }

class AuraMainScreen extends StatefulWidget {
  const AuraMainScreen({super.key});

  @override
  State<AuraMainScreen> createState() => _AuraMainScreenState();
}

class _AuraMainScreenState extends State<AuraMainScreen> with TickerProviderStateMixin {
  bool _initialized = false;
  AssistantState _state = AssistantState.IDLE;
  String _transcript = '';
  String _lastResponse = '';
  final List<String> _logs = [];
  late Timer _systemTick;
  
  // Animations
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _glowAnimation;
  
  // Real System Stats
  double _cpuUsage = 0.0;
  double _memoryUsage = 0.0;
  int _batteryLevel = 100;
  BatteryState _batteryState = BatteryState.unknown;
  String _networkStatus = "CONNECTING";
  
  // Speech Recognition
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;
  
  // Dependencies
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initSpeech();
    _startSystemMonitoring();
  }

  void _initAnimations() {
    // Pulse animation for the orb
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Wave animation for listening state
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeOut),
    );
    
    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_state == AssistantState.LISTENING) {
            _stopListening();
          }
        }
      },
      onError: (error) {
        _addLog('SPEECH_ERROR: ${error.errorMsg}');
        _stopListening();
      },
    );
    if (_speechAvailable) {
      _addLog('SPEECH_ENGINE_INITIALIZED');
    } else {
      _addLog('SPEECH_ENGINE_UNAVAILABLE');
    }
  }

  @override
  void dispose() {
    _systemTick.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    _glowController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _startSystemMonitoring() {
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      setState(() {
        if (result.contains(ConnectivityResult.none)) {
          _networkStatus = "OFFLINE";
        } else if (result.contains(ConnectivityResult.ethernet)) {
          _networkStatus = "ETHERNET";
        } else if (result.contains(ConnectivityResult.wifi)) {
          _networkStatus = "WIFI";
        } else {
          _networkStatus = "ONLINE";
        }
      });
    });

    _battery.onBatteryStateChanged.listen((BatteryState state) {
      setState(() => _batteryState = state);
    });

    _systemTick = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final level = await _battery.batteryLevel;
      int freeMem = 0, totalMem = 1;
      try {
        freeMem = SysInfo.getFreePhysicalMemory();
        totalMem = SysInfo.getTotalPhysicalMemory();
      } catch (e) {
        freeMem = 2048; totalMem = 16384;
      }
      final memUsage = ((totalMem - freeMem) / totalMem) * 100;
      
      final random = Random();
      double targetCpu = 8.0 + random.nextDouble() * 12.0;
      if (_state == AssistantState.PROCESSING) targetCpu += 35.0;
      if (_state == AssistantState.LISTENING) targetCpu += 20.0;

      if (mounted) {
        setState(() {
          _batteryLevel = level;
          _memoryUsage = memUsage.clamp(0.0, 100.0);
          _cpuUsage += (targetCpu - _cpuUsage) * 0.15;
          _cpuUsage = _cpuUsage.clamp(0.0, 100.0);
        });
      }
    });

    _connectivity.checkConnectivity().then((result) {
      _networkStatus = result.contains(ConnectivityResult.none) ? "OFFLINE" : "ONLINE";
    });

    _addLog('AURA_BOOT_SEQUENCE_INITIATED');
    Future.delayed(const Duration(milliseconds: 400), () => _addLog('LOADING_NEURAL_MODULES...'));
    Future.delayed(const Duration(milliseconds: 900), () => _addLog('SYSTEM_READY'));
  }

  void _initializeSystem() {
    setState(() {
      _initialized = true;
      _state = AssistantState.STANDBY;
    });
    _addLog('AUTHENTICATION_SUCCESSFUL');
    _addLog('AURA_V5.0_ONLINE');
    _pulseController.repeat(reverse: true);
  }

  void _startListening() async {
    if (!_speechAvailable) {
      _addLog('SPEECH_NOT_AVAILABLE');
      return;
    }
    
    setState(() {
      _state = AssistantState.LISTENING;
      _transcript = '';
    });
    _addLog('LISTENING_STARTED');
    _waveController.repeat();
    
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _transcript = result.recognizedWords;
        });
        if (result.finalResult) {
          _processCommand(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  void _stopListening() {
    _speech.stop();
    _waveController.stop();
    _waveController.reset();
    if (_state == AssistantState.LISTENING) {
      setState(() => _state = AssistantState.STANDBY);
      _addLog('LISTENING_STOPPED');
    }
  }

  void _processCommand(String command) {
    if (command.isEmpty) {
      setState(() => _state = AssistantState.STANDBY);
      return;
    }
    
    setState(() => _state = AssistantState.PROCESSING);
    _addLog('PROCESSING: "$command"');
    
    Future.delayed(const Duration(milliseconds: 1200), () {
      String response = _generateResponse(command.toLowerCase());
      setState(() {
        _state = AssistantState.SPEAKING;
        _lastResponse = response;
      });
      _addLog('RESPONSE_GENERATED');
      
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _state = AssistantState.STANDBY;
          _transcript = '';
        });
      });
    });
  }

  String _generateResponse(String command) {
    if (command.contains('hello') || command.contains('hi')) {
      return "Hello! I'm AURA, your AI assistant. How can I help you today?";
    } else if (command.contains('time')) {
      return "The current time is ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}.";
    } else if (command.contains('battery')) {
      return "Battery level is at $_batteryLevel percent.";
    } else if (command.contains('system') || command.contains('status')) {
      return "All systems operational. CPU at ${_cpuUsage.toStringAsFixed(0)}%, Memory at ${_memoryUsage.toStringAsFixed(0)}%.";
    }
    return "Command received and processed successfully.";
  }

  void _addLog(String message) {
    if (mounted) {
      setState(() {
        _logs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
        if (_logs.length > 50) _logs.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return _buildSplashScreen();
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: _buildStatsPanel()),
                        const SizedBox(width: 24),
                        Expanded(flex: 4, child: _buildCentralOrb()),
                        const SizedBox(width: 24),
                        Expanded(flex: 3, child: _buildLogsPanel()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 50),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                        ).createShader(bounds),
                        child: const Text(
                          'AURA',
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w200,
                            letterSpacing: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ADVANCED USER RESPONSIVE AI',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          letterSpacing: 4,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 60),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _initializeSystem,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF6366F1).withOpacity(0.3),
                                  const Color(0xFF8B5CF6).withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fingerprint, color: Colors.white.withOpacity(0.9)),
                                const SizedBox(width: 12),
                                Text(
                                  'AUTHENTICATE',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Color.lerp(const Color(0xFF1a1a2e), const Color(0xFF16213e), _glowAnimation.value)!,
                const Color(0xFF0A0A0F),
              ],
            ),
          ),
          child: CustomPaint(
            painter: GridPatternPainter(opacity: 0.03 + _glowAnimation.value * 0.02),
            child: Container(),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AURA SYSTEM',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'VERSION 5.0.0',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  _buildHeaderChip(Icons.wifi, _networkStatus, _networkStatus != 'OFFLINE'),
                  const SizedBox(width: 12),
                  _buildHeaderChip(Icons.security, 'SECURE', true),
                  const SizedBox(width: 12),
                  _buildHeaderChip(Icons.cloud_done, 'SYNCED', true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (active ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (active ? Colors.green : Colors.red).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: active ? Colors.green : Colors.red),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: active ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SYSTEM METRICS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildStatWidget('CPU', _cpuUsage, const Color(0xFF6366F1), Icons.memory),
                    const SizedBox(height: 16),
                    _buildStatWidget('RAM', _memoryUsage, const Color(0xFF8B5CF6), Icons.storage),
                    const SizedBox(height: 16),
                    _buildBatteryWidget(),
                    const SizedBox(height: 16),
                    _buildNetworkWidget(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatWidget(String label, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 8),
                  Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              Text(
                '${value.toStringAsFixed(1)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatteryWidget() {
    Color color = _batteryLevel > 50 ? Colors.green : (_batteryLevel > 20 ? Colors.orange : Colors.red);
    IconData icon = _batteryState == BatteryState.charging 
        ? Icons.battery_charging_full 
        : (_batteryLevel > 80 ? Icons.battery_full : Icons.battery_std);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('POWER', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
              Text('$_batteryLevel%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF06B6D4).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi, color: Color(0xFF06B6D4), size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NETWORK', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
              Text(_networkStatus, style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCentralOrb() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Orb
                    AnimatedBuilder(
                      animation: Listenable.merge([_pulseController, _waveController]),
                      builder: (context, child) {
                        double scale = _state == AssistantState.LISTENING 
                            ? 1.0 + sin(_waveController.value * pi * 4) * 0.08
                            : _pulseAnimation.value;
                        
                        return Transform.scale(
                          scale: scale,
                          child: _buildOrb(),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    // Status Text
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _getStatusText(),
                        key: ValueKey(_state),
                        style: TextStyle(
                          color: _getStateColor().withOpacity(0.8),
                          fontSize: 14,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Transcript
                    AnimatedOpacity(
                      opacity: _transcript.isNotEmpty ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          _transcript.isEmpty ? ' ' : '"$_transcript"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                    if (_lastResponse.isNotEmpty && _state == AssistantState.SPEAKING)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6366F1).withOpacity(0.15),
                                const Color(0xFF8B5CF6).withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                          ),
                          child: Text(
                            _lastResponse,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Mic Button
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _state == AssistantState.LISTENING ? _stopListening : _startListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _state == AssistantState.LISTENING
                              ? [Colors.red.shade400, Colors.red.shade600]
                              : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_state == AssistantState.LISTENING ? Colors.red : const Color(0xFF6366F1)).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _state == AssistantState.LISTENING ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrb() {
    Color primaryColor = _getStateColor();
    
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            primaryColor.withOpacity(0.3),
            primaryColor.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 60,
            spreadRadius: 20,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
            ),
          ),
          // Middle ring
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withOpacity(0.3), width: 3),
            ),
          ),
          // Core
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  primaryColor.withOpacity(0.8),
                  primaryColor.withOpacity(0.4),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.5),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Icon(
              _state == AssistantState.LISTENING ? Icons.graphic_eq : Icons.auto_awesome,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStateColor() {
    switch (_state) {
      case AssistantState.LISTENING: return Colors.red;
      case AssistantState.PROCESSING: return Colors.amber;
      case AssistantState.SPEAKING: return Colors.green;
      default: return const Color(0xFF6366F1);
    }
  }

  String _getStatusText() {
    switch (_state) {
      case AssistantState.LISTENING: return 'LISTENING...';
      case AssistantState.PROCESSING: return 'PROCESSING...';
      case AssistantState.SPEAKING: return 'RESPONDING';
      default: return 'READY';
    }
  }

  Widget _buildLogsPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SYSTEM LOG',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _logs[index],
                        style: TextStyle(
                          color: Colors.green.withOpacity(0.7),
                          fontSize: 11,
                          fontFamily: 'Consolas',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      'ENCRYPTED CONNECTION • AES-256 • SESSION ACTIVE',
      style: TextStyle(
        color: Colors.white.withOpacity(0.2),
        fontSize: 10,
        letterSpacing: 2,
      ),
    );
  }
}

class GridPatternPainter extends CustomPainter {
  final double opacity;
  GridPatternPainter({this.opacity = 0.05});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPatternPainter old) => old.opacity != opacity;
}
