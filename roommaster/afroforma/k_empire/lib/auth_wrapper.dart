import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart'; // New import

class AuthWrapper extends StatelessWidget {
  final bool hasSeenOnboarding; // New parameter

  const AuthWrapper({Key? key, this.hasSeenOnboarding = false}) : super(key: key); // Initialize

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasData) {
          // User is logged in
          if (!hasSeenOnboarding) {
            return const OnboardingScreen(); // Show onboarding if not seen
          }
          return const HomeScreen(); // Otherwise, go to home
        } else {
          return const LoginScreen(); // Not logged in, go to login
        }
      },
    );
  }
}
