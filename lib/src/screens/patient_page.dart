import 'package:flutter/material.dart';

class PatientPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Page'),
      ),
      body: Center(
        child: Text('Welcome to the Patient Page!'),
      ),
    );
  }
}