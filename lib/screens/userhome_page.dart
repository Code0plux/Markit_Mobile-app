import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:markit/screens/markentry_page.dart';

class UserhomePage extends StatefulWidget {
  final String name; // Staff name
  UserhomePage({super.key, required this.name});

  @override
  State<UserhomePage> createState() => _UserhomePageState();
}

class _UserhomePageState extends State<UserhomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.name,
          style: TextStyle(fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 224, 147, 238),
      ),
      body: Column(
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                "Courses",
                style: TextStyle(fontSize: 31, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Staffs') // Main collection
                  .doc(widget.name) // Document for the staff name
                  .collection('courses') // Sub-collection for courses
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No courses found"),
                  );
                }

                // Extract course names
                final courses = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final courseName =
                        courses[index].id; // Document ID as course name
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(
                          courseName,
                          style: const TextStyle(fontSize: 18),
                        ),
                        onTap: () {},
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
