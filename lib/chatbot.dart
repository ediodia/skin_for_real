import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SkinChatbot extends StatefulWidget {
  final String skinType;
  final String skinTone;
  final String currentRecommendations;

  const SkinChatbot({
    super.key,
    required this.skinType,
    required this.skinTone,
    required this.currentRecommendations,
  });

  @override
  State<SkinChatbot> createState() => _SkinChatbotState();
}

class _SkinChatbotState extends State<SkinChatbot>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  static const String _groqProxy = 'https://groqchat-yp4lhrod3q-uc.a.run.app';

  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();

    _messages.add({
      'role': 'assistant',
      'content':
          'Hey! I\'m the SkinForReal AI assistant. I can see your skin was analyzed as ${widget.skinType} with a ${widget.skinTone} tone. I\'m here to help you understand your skin better, but I\'m not a licensed dermatologist — always check with a professional for medical concerns. Ask me anything about your routine or products!',
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _cleanText(String text) {
    return text
        .replaceAll('**', '')
        .replaceAll(RegExp(r'[^\x00-\x7F\n\r\t ]'), '');
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final systemPrompt =
          '''You are SkinForReal AI, a skincare assistant built to help users understand their skin better. You are not a licensed dermatologist or medical professional. Your suggestions are educational and informational only and may not always be accurate. Always recommend consulting a licensed dermatologist for medical advice or concerns.

The user's current skin analysis:
- Skin Type: ${widget.skinType}
- Skin Tone: ${widget.skinTone}
- Current Recommendations: ${widget.currentRecommendations}

Always give personalized advice based on their specific skin type and tone. Be friendly, concise, and practical. Keep responses under 150 words unless a detailed explanation is needed. Do not use markdown formatting or asterisks. Always remind users to consult a dermatologist for serious concerns.''';

      final messages = [
        {'role': 'system', 'content': systemPrompt},
        ..._messages.map((m) => {'role': m['role']!, 'content': m['content']!}),
      ];

      final response = await http.post(
        Uri.parse(_groqProxy),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': messages,
          'max_tokens': 300,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = _cleanText(data['choices'][0]['message']['content']);
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Sorry, something went wrong. Try again.'
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': 'Connection error. Please try again.'
        });
        _isLoading = false;
      });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 600;

    final inner = Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1e1e2e) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20)
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.deepPurple, size: 18),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SkinForReal AI',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87)),
                    Text('Skincare assistant — not a dermatologist',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close_rounded, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.withValues(alpha: 0.15), height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator(isDark);
                }
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                return _buildMessage(message['content']!, isUser, isDark);
              },
            ),
          ),
          AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1e1e2e) : Colors.white,
                border: Border(
                    top:
                        BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2a2a3e)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ask about your skin...',
                          hintStyle: TextStyle(
                              color: Colors.grey.shade500, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: _sendMessage,
                        textInputAction: TextInputAction.send,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(_controller.text),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                          color: Colors.deepPurple, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return SlideTransition(
        position: _slideAnimation,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: inner,
        ),
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, sheetScrollController) {
        return SlideTransition(
          position: _slideAnimation,
          child: inner,
        );
      },
    );
  }

  Widget _buildMessage(String content, bool isUser, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 14, color: Colors.deepPurple),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.deepPurple
                    : isDark
                        ? const Color(0xFF2a2a3e)
                        : const Color(0xFFF0EDFF),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isUser
                      ? Colors.white
                      : isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.black87,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 14, color: Colors.deepPurple),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2a2a3e) : const Color(0xFFF0EDFF),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.4 + (value * 0.6)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
