import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shimmer/shimmer.dart';

import 'deck_view.dart';
import 'home_page.dart';

class AIAssistedPage extends StatefulWidget {
  final String subject;

  const AIAssistedPage({required this.subject});

  @override
  _AIAssistedPageState createState() => _AIAssistedPageState();
}

class _AIAssistedPageState extends State<AIAssistedPage> {
  final TextEditingController _textController = TextEditingController();
  bool isLoading = false;
  List<Map<String, String>> _previewCards = [];
  bool _autoRedirect = false;

  // ------------------------
  // Pick PDF File
  // ------------------------
  Future<void> pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      PDFDoc doc = await PDFDoc.fromFile(file);
      String text = await doc.text;

      _textController.text =
          text.length > 2000 ? text.substring(0, 2000) : text;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ PDF loaded! You can now generate flashcards.")),
      );
    }
  }

  // ------------------------
  // Generate Flashcards with Gemini AI
  // ------------------------
  Future<void> _generateFlashcards(String inputText) async {
    if (inputText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠ Please enter some text")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      _previewCards = [];
    });

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      final model = GenerativeModel(model: 'gemini-pro-latest', apiKey: apiKey!);

      final prompt = '''
Create 5 flashcards from this text: "$inputText"
Return strictly JSON array like:
[
  {"question":"...","answer":"..."}
]
''';

      final response = await model.generateContent([Content.text(prompt)]);
      String? rawText = response.text;

      if (rawText == null || rawText.isEmpty) throw Exception("Empty response");

      rawText = rawText.replaceAll("\njson", "").replaceAll("\n", "").trim();

      dynamic parsed;
      try {
        parsed = jsonDecode(rawText);
      } catch (_) {
        final start = rawText.indexOf('[');
        final end = rawText.lastIndexOf(']');
        if (start != -1 && end != -1) {
          parsed = jsonDecode(rawText.substring(start, end + 1));
        }
      }

      if (parsed is! List) throw Exception("Invalid format");

      final flashcardsRef = FirebaseFirestore.instance.collection("flashcards");

      for (var card in parsed) {
        final q = card['question']?.toString() ?? "";
        final a = card['answer']?.toString() ?? "";

        if (q.isEmpty && a.isEmpty) continue;

        await flashcardsRef.doc(widget.subject).set(
          {
            "name": widget.subject,
            "createdAt": FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        await flashcardsRef.doc(widget.subject).collection("cards").add({
          "question": q,
          "answer": a,
          "repetition": 0,
          "efactor": 2.5,
          "interval": 1,
          "nextReview": Timestamp.now(),
          "createdAt": FieldValue.serverTimestamp(),
        });

        _previewCards.add({"question": q, "answer": a});
      }

      if (_autoRedirect) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DeckViewPage(subject: widget.subject),
          ),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠ Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ------------------------
  // Build UI
  // ------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AI Flashcards - ${widget.subject}"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Text / PDF Input
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _textController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Paste text or upload a PDF...",
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // PDF Upload & Generate Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Upload PDF"),
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: pickPDF,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.smart_toy),
                    label:
                        isLoading ? const Text("Generating...") : const Text("Generate"),
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      backgroundColor: Colors.blueAccent,
                    ),
                    onPressed:
                        isLoading ? null : () => _generateFlashcards(_textController.text),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Auto Redirect Toggle
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                title: const Text("Auto-open Deck after generation"),
                value: _autoRedirect,
                onChanged: (v) => setState(() => _autoRedirect = v),
              ),
            ),
            const SizedBox(height: 20),

            // Flashcards Preview / Loading / Empty
            if (isLoading)
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (_, __) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(height: 80),
                    ),
                  ),
                ),
              )
            else if (_previewCards.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _previewCards.length,
                  itemBuilder: (context, index) {
                    final card = _previewCards[index];
                    return _FlashcardItem(
                      question: card["question"]!,
                      answer: card["answer"]!,
                    );
                  },
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text(
                    "No flashcards yet 🚀",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FlashcardItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FlashcardItem({
    required this.question,
    required this.answer,
  });

  @override
  State<_FlashcardItem> createState() => _FlashcardItemState();
}

class _FlashcardItemState extends State<_FlashcardItem>
    with SingleTickerProviderStateMixin {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showAnswer = !_showAnswer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _showAnswer
                ? [Colors.green.shade300, Colors.green.shade600]
                : [Colors.blue.shade300, Colors.blue.shade600],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4),
          ],
        ),
        child: Text(
          _showAnswer
              ? "A: ${widget.answer}"
              : "Q: ${widget.question}",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
