import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MarksEntryScreen extends StatefulWidget {
  final String courseId;

  const MarksEntryScreen({super.key, required this.courseId});

  @override
  _MarksEntryScreenState createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends State<MarksEntryScreen> {
  late int startDno;
  late int endDno;
  late int currentDno;
  String? selectedExercise;
  List<String> exerciseList = [];
  final TextEditingController preparationMarkController =
      TextEditingController();
  final TextEditingController vivaVoceController = TextEditingController();
  final TextEditingController dnoController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCourseDetails();
  }

  Future<void> fetchCourseDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch course data
      final courseSnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(widget.courseId)
          .get();

      final courseData = courseSnapshot.data();
      if (courseData != null) {
        fetchExercises(); // Fetch exercises first to determine Dno range
      }
    } catch (e) {
      print('Error fetching course details: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchExercises() async {
    setState(() {
      isLoading = true;
    });

    try {
      final courseSnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(widget.courseId)
          .get();

      final courseData = courseSnapshot.data();
      final totalExercises = courseData?['totalex'] ?? 0;

      // Generate exercise list
      exerciseList =
          List.generate(totalExercises, (index) => 'Ex ${index + 1}');
      if (exerciseList.isNotEmpty) {
        selectedExercise = exerciseList.first;
        await fetchDnoRange(
            selectedExercise!); // Fetch the Dno range dynamically
        fetchMarks(); // Fetch marks for the first Dno
      }
    } catch (e) {
      print('Error fetching exercises: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchDnoRange(String exercise) async {
    try {
      // Query all documents in the selected exercise collection
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(widget.courseId)
          .collection(exercise)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Extract document IDs and sort them to determine start and end Dno
        final docIds = querySnapshot.docs
            .map((doc) => int.tryParse(doc.id))
            .whereType<int>()
            .toList();
        docIds.sort();
        startDno = docIds.first;
        endDno = docIds.last;
        currentDno = startDno;
        dnoController.text = currentDno.toString();
      } else {
        throw Exception('No documents found in exercise collection');
      }
    } catch (e) {
      print('Error fetching Dno range: $e');
      startDno = 1;
      endDno = 1;
      currentDno = startDno;
      dnoController.text = currentDno.toString();
    }
  }

  Future<void> fetchMarks() async {
    if (selectedExercise == null) return;

    final markDoc = await FirebaseFirestore.instance
        .collection('Courses')
        .doc(widget.courseId)
        .collection(selectedExercise!)
        .doc(currentDno.toString())
        .get();

    final markData = markDoc.data();
    if (markData != null) {
      preparationMarkController.text = markData['preparationMark'].toString();
      vivaVoceController.text = markData['vivaVoce'].toString();
    } else {
      preparationMarkController.clear();
      vivaVoceController.clear();
    }
  }

  Future<void> saveMarks() async {
    if (selectedExercise == null) return;

    final preparationMark = int.tryParse(preparationMarkController.text) ?? 0;
    final vivaVoce = int.tryParse(vivaVoceController.text) ?? 0;

    await FirebaseFirestore.instance
        .collection('Courses')
        .doc(widget.courseId)
        .collection(selectedExercise!)
        .doc(currentDno.toString())
        .set({
      'preparationMark': preparationMark,
      'vivaVoce': vivaVoce,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Marks saved for Dno $currentDno')),
    );
  }

  void nextDno() async {
    await saveMarks();
    if (currentDno < endDno) {
      setState(() {
        currentDno++;
        dnoController.text = currentDno.toString();
      });
      fetchMarks();
    }
  }

  void previousDno() async {
    await saveMarks();
    if (currentDno > startDno) {
      setState(() {
        currentDno--;
        dnoController.text = currentDno.toString();
      });
      fetchMarks();
    }
  }

  void updateDno() async {
    final newDno = int.tryParse(dnoController.text);
    if (newDno != null && newDno >= startDno && newDno <= endDno) {
      await saveMarks();
      setState(() {
        currentDno = newDno;
      });
      fetchMarks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid Dno')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Marks Entry - ${widget.courseId}'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<String>(
                    value: selectedExercise,
                    onChanged: (value) {
                      setState(() {
                        selectedExercise = value;
                        currentDno = startDno;
                        dnoController.text = currentDno.toString();
                      });
                      fetchMarks();
                    },
                    items: exerciseList
                        .map((exercise) => DropdownMenuItem(
                              value: exercise,
                              child: Text(exercise),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: preparationMarkController,
                    decoration: InputDecoration(labelText: 'Preparation Mark'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: vivaVoceController,
                    decoration: InputDecoration(labelText: 'Viva Voce'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: previousDno,
                        child: Text('Previous Dno'),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: dnoController,
                          decoration: InputDecoration(labelText: 'Dno'),
                          keyboardType: TextInputType.number,
                          onSubmitted: (value) => updateDno(),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: nextDno,
                        child: Text('Next Dno'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
