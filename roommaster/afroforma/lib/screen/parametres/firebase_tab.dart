import 'package:flutter/material.dart';
import 'helpers.dart';
import 'package:afroforma/screen/parametres/firebase_settings_panel.dart';

class FirebaseTab extends StatelessWidget {
  const FirebaseTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Important: do not wrap with SingleChildScrollView because the panel contains
    // an internal TabBarView using Expanded which requires bounded height.
    return const FirebaseSettingsPanel();
  }
}
