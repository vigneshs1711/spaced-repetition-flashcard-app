import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'deck_view.dart';

class SubjectListPage extends StatelessWidget {
  const SubjectListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subjectsRef = FirebaseFirestore.instance.collection("flashcards");

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "📚 Flashcard Subjects",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: subjectsRef.snapshots(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No subjects created yet 🚀",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          // Data available
          final subjects = snapshot.data!.docs;

          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subjectDoc = subjects[index];
              final subjectName = subjectDoc['name'] ?? subjectDoc.id;

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  title: Text(
                    subjectName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.indigo,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeckViewPage(subject: subjectName),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
