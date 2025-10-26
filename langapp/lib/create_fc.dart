import 'package:flutter/material.dart';
import 'fc_creation_option.dart';

class CreateFlashcardPage extends StatefulWidget {
  const CreateFlashcardPage({Key? key}) : super(key: key);

  @override
  _CreateFlashcardPageState createState() => _CreateFlashcardPageState();
}

class _CreateFlashcardPageState extends State<CreateFlashcardPage> {
  String? selectedSubject;
  final TextEditingController _newSubjectController = TextEditingController();

  final List<String> subjects = ["Math", "Physics", "English"];

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          "Create Flashcards",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Choose Subject:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Dropdown for existing subjects
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSubject,
                    hint: const Text("Select existing subject"),
                    isExpanded: true,
                    items: subjects.map((subject) {
                      return DropdownMenuItem(
                        value: subject,
                        child: Text(subject),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSubject = value;
                      });
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Text field for creating new subject
            TextField(
              controller: _newSubjectController,
              decoration: InputDecoration(
                labelText: "Or create new subject",
                prefixIcon: const Icon(Icons.edit_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Gradient Button
            Center(
              child: Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [Colors.black, Colors.grey],
                  ),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    final subjectFromDropdown = selectedSubject;
                    final subjectFromText = _newSubjectController.text.trim();

                    // Validation logic
                    if ((subjectFromDropdown == null ||
                            subjectFromDropdown.isEmpty) &&
                        subjectFromText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Please select or create a subject"),
                        ),
                      );
                      return;
                    }

                    if (subjectFromDropdown != null &&
                        subjectFromDropdown.isNotEmpty &&
                        subjectFromText.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Choose either an existing subject OR create a new one, not both"),
                        ),
                      );
                      return;
                    }

                    final subject = subjectFromDropdown ?? subjectFromText;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FlashcardModePage(subject: subject),
                      ),
                    );
                  },
                  child: const Text(
                    "Next ➡",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
