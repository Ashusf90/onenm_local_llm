import 'package:flutter/material.dart';
import 'package:onenm_local_llm/onenm_local_llm.dart';

class NoteSummarizerApp extends StatefulWidget {
  const NoteSummarizerApp({Key? key}) : super(key: key);
  @override
  _NoteSummarizerAppState createState() => _NoteSummarizerAppState();
}

class _NoteSummarizerAppState extends State<NoteSummarizerApp> {
  final TextEditingController _controller = TextEditingController();
  String _summary = '';
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
      model: OneNmModel.qwen25,
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
        _status = 'Ready to summarize!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error initializing model: $e';
      });
    }
  }

  Future<void> _summarizeText(String text) async {
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _summary = '';
      _isLoading = true;
    });

    try {
      // Use the chat method with a prompt to summarize the text
      final prompt = "Summarize the following text: \n$text";
      final summary = await _ai.chat(prompt);
      setState(() {
        _summary = summary;
      });
    } catch (e) {
      setState(() {
        _summary = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
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
        title: Text('Note Summarizer', style: TextStyle(color: Colors.white)),
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Text(
                    _summary,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  maxLines: 5,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Paste your text here...',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 8.0),
                ElevatedButton(
                  onPressed: () => _summarizeText(_controller.text),
                  child: const Text('Summarize'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
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
