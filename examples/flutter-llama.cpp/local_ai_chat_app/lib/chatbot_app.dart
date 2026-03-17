import 'package:flutter/material.dart';
import 'package:onenm_local_llm/onenm_local_llm.dart';

class ChatbotApp extends StatefulWidget {
  @override
  _ChatbotAppState createState() => _ChatbotAppState();
}

class _ChatbotAppState extends State<ChatbotApp> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  late OneNm _ai;
  String _status = 'Initializing...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    _ai = OneNm(
      model: OneNmModel.llama32,
      onProgress: (status) {
        setState(() {
          _status = status;
        });
      },
    );

    try {
      await _ai.initialize();
      setState(() {
        _isLoading = false;
        _status = 'Ready to chat!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error initializing model: $e';
      });
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'user': message});
      _controller.clear();
      _isLoading = true; // Show loading indicator
    });

    try {
      final reply = await _ai.chat(message);
      setState(() {
        _messages.add({'bot': reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({'bot': 'Error: $e'});
      });
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  void dispose() {
    _ai.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('AI Chatbot', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    _status,
                    style: TextStyle(color: Colors.greenAccent),
                  ),
                ],
              ),
            ),
          if (!_isLoading)
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message.containsKey('user');
                  return Container(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    child: Text(
                      message.values.first,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.greenAccent,
                      ),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.greenAccent),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
