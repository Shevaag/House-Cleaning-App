import 'package:flutter/material.dart';
import 'user_selection.dart';

class StartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector( //to detect user gestures
      onTap: () {
        Navigator.pushReplacement( //navigates to user selection screen
          context,
          MaterialPageRoute(builder: (context) => UserSelectionScreen()),
        );
      },
      child: Scaffold(
        body: Stack( //allows placing widgets on top of the other
          children: [
            Image.asset(
              'assets/background1.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            // Text Overlay
            Center(
              child: Text(
                'Tap to Continue',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 5.0,
                      color: Colors.black.withOpacity(0.5),
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}