import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MarksEntryScreen extends StatefulWidget {
  final String courseId;
  final int startDno;
  final int endDno;

  MarksEntryScreen(
      {required this.courseId, required this.startDno, required this.endDno});

  @override
  _MarksEntryScreenState createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends State<MarksEntryScreen> {
  late int currentDno;
  final TextEditingController preparationMarkController =
      TextEditingController();
  final TextEditingController vivaVoceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentDno = widget.startDno;
  }

  void saveMarks() {
    final preparationMark = int.tryParse(preparationMarkController.text.trim());
    final vivaVoce = int.tryParse(vivaVoceController.text.trim());

    if (preparationMark == null || vivaVoce == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid marks')),
      );
      return;
    }

    FirebaseFirestore.instance
        .collection(widget.courseId)
        .doc(currentDno.toString())
        .update({
      'preparationMark': preparationMark,
      'vivaVoce': vivaVoce,
    });

    if (currentDno < widget.endDno) {
      setState(() {
        currentDno++;
        preparationMarkController.clear();
        vivaVoceController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All marks have been entered')),
      );
    }
  }

  Future<void> generatePdf() async {
    final pdf = pw.Document();
    final collection = FirebaseFirestore.instance.collection(widget.courseId);
    final snapshot = await collection.get();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Table.fromTextArray(
            context: context,
            data: <List<String>>[
              ['D.no', 'Preparation Mark', 'Viva Voce'],
              ...snapshot.docs.map((doc) {
                final data = doc.data();
                return [
                  doc.id,
                  data['preparationMark'].toString(),
                  data['vivaVoce'].toString(),
                ];
              }).toList(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter Marks')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('D.no: $currentDno',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: preparationMarkController,
              decoration: InputDecoration(labelText: 'Preparation Mark'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: vivaVoceController,
              decoration: InputDecoration(labelText: 'Viva Voce'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveMarks,
              child: Text('Save and Next'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: generatePdf,
              child: Text('Generate PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
