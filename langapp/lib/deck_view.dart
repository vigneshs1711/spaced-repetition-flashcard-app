import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DeckViewPage extends StatefulWidget {
  final String subject;

  const DeckViewPage({required this.subject, Key? key}) : super(key: key);

  @override
  State<DeckViewPage> createState() => _DeckViewPageState();
}

class _DeckViewPageState extends State<DeckViewPage> {
  int currentIndex = 0;
  bool showAnswer = false;

  // ------------------------
  // Build Main UI
  // ------------------------
  @override
  Widget build(BuildContext context) {
    final subjectRef = FirebaseFirestore.instance
        .collection("flashcards")
        .doc(widget.subject)
        .collection("cards");

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.subject,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: subjectRef.snapshots(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // No data
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No flashcards found 🚀"));
          }

          final allCards = snapshot.data!.docs;
          final now = DateTime.now();

          // Filter cards due for review (Anki-like logic)
          final dueCards = allCards.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['nextReview'] == null) return true;
            final nextReview = (data['nextReview'] as Timestamp).toDate();
            return nextReview.isBefore(now);
          }).toList();

          final cards = dueCards.isNotEmpty ? dueCards : allCards;

          // Finished deck
          if (currentIndex >= cards.length) {
            return _buildFinishScreen();
          }

          final card = cards[currentIndex];
          final data = card.data() as Map<String, dynamic>;
          final nextReview = data['nextReview'] != null
              ? (data['nextReview'] as Timestamp).toDate()
              : null;

          // Flashcard UI
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildProgressIndicator(cards.length),
                const SizedBox(height: 30),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: _buildCard(data, nextReview),
                  ),
                ),
                const SizedBox(height: 25),
                showAnswer
                    ? _buildRatingButtons(card.id)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () => setState(() => showAnswer = true),
                        child: const Text(
                          "Show Answer",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // ------------------------
  // Flashcard Card Widget
  // ------------------------
  Widget _buildCard(Map<String, dynamic> data, DateTime? nextReview) {
    return Container(
      key: ValueKey(showAnswer),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                showAnswer ? data["answer"] : data["question"],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (showAnswer && nextReview != null)
                Text(
                  "Next Review: ${DateFormat('MMM d, yyyy').format(nextReview)}",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------
  // Progress Indicator
  // ------------------------
  Widget _buildProgressIndicator(int total) {
    return Column(
      children: [
        Text(
          "Card ${currentIndex + 1} of $total",
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (currentIndex + 1) / total,
          color: Colors.indigo,
          backgroundColor: Colors.indigo.withOpacity(0.2),
        ),
      ],
    );
  }

  // ------------------------
  // Rating Buttons (SM2)
  // ------------------------
  Widget _buildRatingButtons(String docId) {
    final options = [0, 1, 2, 3, 4, 5];

    return Column(
      children: [
        const Text(
          "How well did you recall?",
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: options.map((rating) {
            return ElevatedButton(
              onPressed: () async {
                await _updateSM2(docId, rating);
                setState(() {
                  currentIndex++;
                  showAnswer = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "$rating",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ------------------------
  // Finish Screen
  // ------------------------
  Widget _buildFinishScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 16),
          const Text(
            "You're done for today! 🎉",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => setState(() => currentIndex = 0),
            child: const Text("Restart Deck"),
          ),
        ],
      ),
    );
  }

  // ------------------------
  // SM2 Algorithm (Spaced Repetition)
  // ------------------------
  Future<void> _updateSM2(String docId, int quality) async {
    final cardRef = FirebaseFirestore.instance
        .collection("flashcards")
        .doc(widget.subject)
        .collection("cards")
        .doc(docId);

    final snapshot = await cardRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    double efactor = (data['efactor'] ?? 2.5).toDouble();
    int repetition = (data['repetition'] ?? 0).toInt();
    int interval = (data['interval'] ?? 1).toInt();

    if (quality < 3) {
      repetition = 0;
      interval = 1;
    } else {
      repetition += 1;
      if (repetition == 1) {
        interval = 1;
      } else if (repetition == 2) {
        interval = 6;
      } else {
        interval = (interval * efactor).round();
      }
    }

    efactor = efactor + 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02);
    if (efactor < 1.3) efactor = 1.3;

    final nextReview = Timestamp.fromDate(
      DateTime.now().add(Duration(days: interval)),
    );

    await cardRef.update({
      "repetition": repetition,
      "efactor": efactor,
      "interval": interval,
      "nextReview": nextReview,
    });
  }
}
