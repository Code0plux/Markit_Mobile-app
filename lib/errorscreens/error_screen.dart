import 'package:flutter/material.dart';

class ErrorScreen extends StatefulWidget {
  final String errormsg;

  const ErrorScreen({super.key, required this.errormsg});

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  @override
  void initState() {
    super.initState();

    // Show SnackBar when the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.errormsg)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      bottomSheet: Center(
        child: Text(
          "An error has occurred",
          style: TextStyle(fontSize: 20, color: Colors.red),
        ),
      ),
    );
  }
}
