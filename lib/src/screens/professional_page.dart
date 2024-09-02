import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class ProfessionalPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Professional Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: DateTime.now(),
              locale: 'es_ES', // Set the locale to Spanish
            ),
            SizedBox(height: 20),
            Text(
              'Welcome to the Professional Page!',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.check),
                    title: Text('Skill 1'),
                  ),
                  ListTile(
                    leading: Icon(Icons.check),
                    title: Text('Skill 2'),
                  ),
                  ListTile(
                    leading: Icon(Icons.check),
                    title: Text('Skill 3'),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to another page
              },
              child: Text('Go to Next Page'),
            ),
          ],
        ),
      ),
    );
  }
}