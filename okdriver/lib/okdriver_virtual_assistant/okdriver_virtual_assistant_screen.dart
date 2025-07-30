import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:provider/provider.dart';
import 'package:okdriver/theme/theme_provider.dart';

import 'components/chat_bubble.dart';
import 'models/chat_message.dart';
import 'service/assistant_service.dart';

class OkDriverVirtualAssistantScreen extends StatefulWidget {
  const OkDriverVirtualAssistantScreen({super.key});

  @override
  State<OkDriverVirtualAssistantScreen> createState() =>
      _OkDriverVirtualAssistantScreenState();
}

class _OkDriverVirtualAssistantScreenState
    extends State<OkDriverVirtualAssistantScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final AssistantService _assistantService = AssistantService();

  bool _isListening = false;
  String _text = '';
  bool _isLoading = false;
  List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  late bool _isDarkMode;
  final String _userId = 'default'; // Could be replaced with actual user ID

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();

    // Initialize _isDarkMode from ThemeProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      setState(() {
        _isDarkMode = themeProvider.isDarkTheme;
      });

      // Load conversation history
      _loadHistory();
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _scrollController.dispose();
    super.dispose();
  }

  // Initialize speech recognition
  void _initSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() {
            _isListening = false;
          });
          if (_text.isNotEmpty) {
            _sendMessageToBackend(_text);
          }
        }
      },
    );
  }

  // Initialize text-to-speech
  void _initTts() async {
    await _flutterTts
        .setLanguage("hi-IN"); // Hindi language for Hinglish support
    await _flutterTts
        .setSpeechRate(0.5); // Slower speech rate for better understanding
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  // Load conversation history
  void _loadHistory() async {
    try {
      final history = await _assistantService.getHistory(_userId);
      setState(() {
        _messages = history;
      });
      _scrollToBottom();
    } catch (e) {
      // Handle error silently
    }
  }

  // Start listening to user's voice
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _text = '';
        });
        _speech.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
            });
          },
          localeId:
              "en_IN", // English (India) for better recognition of Indian accent
        );
      }
    } else {
      setState(() {
        _isListening = false;
      });
      _speech.stop();
      if (_text.isNotEmpty) {
        _sendMessageToBackend(_text);
      }
    }
  }

  // Send message to backend API
  void _sendMessageToBackend(String message) async {
    if (message.isEmpty) return;

    final userMessage = ChatMessage(text: message, isUser: true);

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    // Scroll to bottom after adding user message
    _scrollToBottom();

    try {
      final data = await _assistantService.sendMessage(message, _userId);
      final aiResponse = data['response'];
      final audioId = data['audio_id'];

      final assistantMessage = ChatMessage(text: aiResponse, isUser: false);

      setState(() {
        _messages.add(assistantMessage);
        _isLoading = false;
      });

      // Speak the response
      await _flutterTts.speak(aiResponse);

      // Scroll to bottom after adding AI response
      _scrollToBottom();

      // Check for audio URL
      _checkAudioStatus(audioId);
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
            text: "Network error. Please check your connection.",
            isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  // Check audio status and play if available
  void _checkAudioStatus(String audioId) async {
    try {
      final data = await _assistantService.checkAudioStatus(audioId);
      if (data['status'] == 'completed' && data['audio_url'] != null) {
        // Audio is ready, you can use it if needed
        // For now we're using flutter_tts directly
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearHistory() async {
    try {
      await _assistantService.clearHistory(_userId);
      setState(() {
        _messages = [];
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes
    final themeProvider = Provider.of<ThemeProvider>(context);
    _isDarkMode = themeProvider.isDarkTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OkDriver Assistant'),
        backgroundColor: _isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: _isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _messages.isNotEmpty ? _clearHistory : null,
            tooltip: 'Clear conversation',
          ),
        ],
      ),
      backgroundColor: _isDarkMode ? Colors.black : const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _messages.isEmpty ? _buildEmptyState() : _buildChatList(),
            ),
          ),

          // Loading indicator
          if (_isListening)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                _text.isEmpty ? 'Listening...' : _text,
                style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _isDarkMode ? Colors.purpleAccent : Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

          // Input area with mic button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mic button with glow effect
                AvatarGlow(
                  animate: _isListening,
                  glowColor: const Color(0xFF9C27B0),
                  glowRadiusFactor: 60.0,
                  duration: const Duration(milliseconds: 2000),
                  repeat: true,
                  child: GestureDetector(
                    onTap: _listen,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9C27B0).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy_rounded,
            size: 80,
            color: _isDarkMode
                ? const Color(0xFF9C27B0).withOpacity(0.7)
                : const Color(0xFF9C27B0),
          ),
          const SizedBox(height: 20),
          Text(
            'Tap the mic and start speaking',
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'I can help you with driving tips, route suggestions, and more!',
            style: TextStyle(
              color: _isDarkMode ? Colors.white54 : Colors.black45,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return ChatBubble(
          message: _messages[index].text,
          isUser: _messages[index].isUser,
        );
      },
    );
  }
}
