import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:langapp/deck_view.dart';
import 'home_page.dart';

class ManualFlashcardPage extends StatefulWidget {
  final String subject;

  ManualFlashcardPage({required this.subject});

  @override
  _ManualFlashcardPageState createState() => _ManualFlashcardPageState();
}

class _ManualFlashcardPageState extends State<ManualFlashcardPage> {
  final TextEditingController _qController = TextEditingController();
  final TextEditingController _aController = TextEditingController();

  // ------------------------
  // Add Flashcard Function
  // ------------------------
  Future<void> _addFlashcard() async {
    if (_qController.text.trim().isEmpty || _aController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠ Both Question & Answer required")),
      );
      return;
    }

    final flashcardsRef = FirebaseFirestore.instance.collection("flashcards");

    await flashcardsRef.doc(widget.subject).set(
      {
        "name": widget.subject,
        "createdAt": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await flashcardsRef.doc(widget.subject).collection("cards").add({
      "question": _qController.text.trim(),
      "answer": _aController.text.trim(),
      "repetition": 0,
      "efactor": 2.5,
      "interval": 1,
      "nextReview": Timestamp.now(),
      "createdAt": FieldValue.serverTimestamp(),
    });

    _qController.clear();
    _aController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("✅ Flashcard Saved!"),
        content: const Text("Your flashcard has been added successfully."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DeckViewPage(subject: widget.subject),
                ),
              );
            },
            child: const Text("📂 Open Deck"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            },
            child: const Text("🏠 Back to Home"),
          ),
        ],
      ),
    );
  }

  // ------------------------
  // Delete Flashcard Function
  // ------------------------
  Future<void> _deleteFlashcard(String docId) async {
    await FirebaseFirestore.instance
        .collection("flashcards")
        .doc(widget.subject)
        .collection("cards")
        .doc(docId)
        .delete();
  }

  // ------------------------
  // Build UI
  // ------------------------
  @override
  Widget build(BuildContext context) {
    final subjectRef = FirebaseFirestore.instance
        .collection("flashcards")
        .doc(widget.subject)
        .collection("cards")
        .orderBy("createdAt", descending: true);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 80,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.grey],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(25),
            ),
          ),
        ),
        title: Text(
          "Manual Flashcards - ${widget.subject}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),

      // ------------------------
      // Body
      // ------------------------
      body: Column(
        children: [
          // Add Flashcard Form
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _qController,
                      decoration: const InputDecoration(
                        labelText: "Question",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.help_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _aController,
                      decoration: const InputDecoration(
                        labelText: "Answer",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lightbulb_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _addFlashcard,
                        child: const Text(
                          "➕ Add Flashcard",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Flashcards List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: subjectRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No flashcards yet 🚀",
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  );
                }

                final flashcards = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: flashcards.length,
                  itemBuilder: (context, index) {
                    var card = flashcards[index];

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        title: Text(
                          card["question"],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          card["answer"],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteFlashcard(card.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
  