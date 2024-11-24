import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:markit/main.dart';
import 'package:markit/screens/markentry_page.dart';

class CourseSetupScreen extends StatelessWidget {
  final TextEditingController courseIdController = TextEditingController();
  final TextEditingController startDnoController = TextEditingController();
  final TextEditingController endDnoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Setup Course')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: courseIdController,
              decoration: InputDecoration(labelText: 'Course ID'),
            ),
            TextField(
              controller: startDnoController,
              decoration: InputDecoration(labelText: 'Starting D.no'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: endDnoController,
              decoration: InputDecoration(labelText: 'Ending D.no'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final courseId = courseIdController.text.trim();
                final startDno = int.tryParse(startDnoController.text.trim());
                final endDno = int.tryParse(endDnoController.text.trim());

                if (courseId.isEmpty || startDno == null || endDno == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill all fields correctly')),
                  );
                  return;
                }

                FirebaseFirestore.instance.collection(courseId).get().then((_) {
                  for (int dno = startDno; dno <= endDno; dno++) {
                    FirebaseFirestore.instance
                        .collection(courseId)
                        .doc(dno.toString())
                        .set({
                      'preparationMark': 0,
                      'vivaVoce': 0,
                    });
                  }
                });

                ;
              },
              child: Text('Create Collection'),
            ),
          ],
        ),
      ),
    );
  }
}
