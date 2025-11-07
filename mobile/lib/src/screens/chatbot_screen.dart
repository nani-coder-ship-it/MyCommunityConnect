import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final _controller = TextEditingController();

  final Map<String, String> _faq = {
    'hello': 'Hello! How can I help you today?',
    'hi': 'Hi there! What can I do for you?',
    'help':
        'I can help you with:\n• Community rules\n• Maintenance requests\n• Event information\n• Visitor registration\n• Emergency contacts',
    'rules':
        'Community rules:\n• No loud music after 10 PM\n• Keep common areas clean\n• Park only in designated areas\n• Visitors must register at security',
    'maintenance':
        'To request maintenance, go to the Maintenance screen from the home page and submit a request.',
    'events': 'Check the Events screen to see upcoming community events!',
    'visitors':
        'To register a visitor, go to the Visitors screen and fill in their details.',
    'emergency':
        'For emergencies:\n• Fire: Call 101\n• Police: Call 100\n• Ambulance: Call 108\n• Or use the Emergency Alert button on home screen',
    'contact': 'You can find emergency contacts in the Contacts tab.',
    'bye': 'Goodbye! Feel free to ask if you need anything!',
    'thanks': 'You\'re welcome! Happy to help! 😊',
  };

  @override
  void initState() {
    super.initState();
    _addMessage('Hi! I\'m your community assistant. Ask me anything!', false);
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add({
        'text': text,
        'isUser': isUser,
        'time': DateTime.now(),
      });
    });
  }

  void _handleMessage(String text) {
    if (text.trim().isEmpty) return;

    _addMessage(text, true);
    _controller.clear();

    // Simple keyword matching
    final lowerText = text.toLowerCase().trim();
    String? response;

    for (final entry in _faq.entries) {
      if (lowerText.contains(entry.key)) {
        response = entry.value;
        break;
      }
    }

    response ??=
        'I\'m sorry, I didn\'t understand that. Try asking about:\n• help\n• rules\n• maintenance\n• events\n• visitors\n• emergency';

    Future.delayed(const Duration(milliseconds: 500), () {
      _addMessage(response!, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.indigo,
              radius: 16,
              child: Icon(Icons.smart_toy, size: 20, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Community Assistant'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('Ask me anything!',
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600])),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final msg = _messages[i];
                      final isUser = msg['isUser'] as bool;
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.blue : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Text(
                            msg['text'] as String,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: _handleMessage,
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _handleMessage(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
