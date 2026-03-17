import 'package:flutter/material.dart';
import 'note_summarizer_app.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: NoteSummarizerApp(),
  ));
}
TextField(
  maxLines: 5,
  decoration: InputDecoration(
    hintText: "Enter text to summarize...",
    border: OutlineInputBorder(),
    contentPadding: EdgeInsets.all(12),
  ),
)
