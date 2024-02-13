import 'package:flutter/material.dart';

class ShowDialog1 extends StatelessWidget {
  const ShowDialog1({Key? key}) : super(key: key);

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Authentication Failed'),
          content: const Text('Invalid email or password. Please try again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the alert box
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _showDialog(context); // Call the showDialog function when needed

    return Scaffold(
      // Your other Scaffold configurations go here
      body: Container(
        // Your other widget tree goes here
      ),
    );
  }
}
