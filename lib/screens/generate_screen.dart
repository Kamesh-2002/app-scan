import 'package:flutter/material.dart';

class GenerateScreen extends StatelessWidget {
  const GenerateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate'),
      ),
      body: const Center(
        child: Text(
          'Generate Screen',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}