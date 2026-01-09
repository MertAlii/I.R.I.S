import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/groq_service.dart';

// Model for chat messages
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

// State provider for messages
class ChatNotifier extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() {
    return [
      ChatMessage(
        text: 'Merhaba! Ben I.R.I.S, iyileşme asistanınızım. Size nasıl yardımcı olabilirim?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }

  void addMessage(String text, bool isUser) {
    state = [...state, ChatMessage(text: text, isUser: isUser, timestamp: DateTime.now())];
  }
}

final chatProvider = NotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);

class YapayZekaEkran extends ConsumerStatefulWidget {
  @override
  _YapayZekaEkranState createState() => _YapayZekaEkranState();
}

class _YapayZekaEkranState extends ConsumerState<YapayZekaEkran> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    ref.read(chatProvider.notifier).addMessage(text, true);
    _controller.clear();
    _scrollToBottom();

    setState(() => _isLoading = true);

    try {
      // Get response from Groq
      final response = await ref.read(groqServiceProvider).sendMessage(text);
      ref.read(chatProvider.notifier).addMessage(response, false);
    } catch (e) {
      ref.read(chatProvider.notifier).addMessage("Bir hata oluştu, lütfen tekrar deneyin.", false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('AI Sağlık Asistanı', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: message.isUser ? const Color(0xFF6BAA75) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: message.isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: message.isUser ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : const Color(0xFF2D3436),
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          
          // Quick Questions
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildQuickChip("Ağrı ne zaman geçer?"),
                const SizedBox(width: 8),
                _buildQuickChip("Ne yemem gerekir?"),
                const SizedBox(width: 8),
                _buildQuickChip("Yürüyüş yapabilir miyim?"),
                const SizedBox(width: 8),
                _buildQuickChip("İlaç takibi"),
              ],
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: 'Sorunuzu yazın...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF1F3F5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF6BAA75),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildQuickChip(String text) {
    return ActionChip(
      label: Text(text),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE9ECEF)),
      onPressed: () => _sendMessage(text),
    );
  }
}