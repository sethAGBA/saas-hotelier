import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:shared_preferences/shared_preferences.dart'; // New import
import 'package:package_info_plus/package_info_plus.dart'; // New import
import 'package:k_empire/services/firestore_service.dart'; // New import
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';
import 'auth_wrapper.dart';

bool hasSeenOnboarding = false; // Global variable to store the flag

// Need a global navigator key for showDialog outside of build method
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Toggle to disable App Check during local debugging. When true in debug mode,
// the app will NOT activate App Check. Note: if App Check enforcement is ON in
// Firebase Console, disabling it here will not help; you must also turn off
// enforcement or register a debug token.
const bool kDisableAppCheckInDebug = false;

void main() async {
  debugPrintEndFrameBanner = false;
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    final opts = Firebase.app().options;
    debugPrint('[FirebaseInit] projectId=${opts.projectId}; storageBucket=${opts.storageBucket}; appId=${opts.appId}');
  } catch (e) {
    debugPrint('[FirebaseInit] could not read app options: $e');
  }

  // Get SharedPreferences instance and check the flag
  SharedPreferences prefs = await SharedPreferences.getInstance();
  hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  // Enable App Check in debug mode using the debug provider so dev uploads work
  // without enforcing production providers. In release, App Check should be
  // activated with the appropriate provider (Play Integrity / DeviceCheck).
  try {
    if (kDebugMode) {
      if (kDisableAppCheckInDebug) {
        debugPrint('Firebase App Check: DISABLED in debug via flag');
      } else {
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
        );
        debugPrint('Firebase App Check: debug provider activated (dev mode)');
      }
    } else {
      await FirebaseAppCheck.instance.activate();
    }
  } catch (e) {
    // Don't block app startup if App Check activation fails in dev.
    debugPrint('FirebaseAppCheck activation failed: $e');
  }

  // Update check logic
  try {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;

    final FirestoreService firestoreService = FirestoreService();
    final Map<String, dynamic>? updateInfo = await firestoreService.getLatestUpdateInfoWithFallback();

    String latestVersion = '';
    if (updateInfo != null) {
      latestVersion = (updateInfo['latest_version'] ?? updateInfo['version'] ?? updateInfo['latestVersion'] ?? '').toString();
    }

    // If a newer version exists, show a dialog when the navigator is ready
    if (latestVersion.isNotEmpty && _isNewVersionAvailable(currentVersion, latestVersion)) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final ctx = navigatorKey.currentContext;
        if (ctx == null) return; // still not ready

        showDialog(
          context: ctx,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Nouvelle mise à jour disponible'),
              content: Text('Une nouvelle version ($latestVersion) est disponible. Votre version actuelle est $currentVersion.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Plus tard'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: const Text('Télécharger'),
                  onPressed: () async {
                    String? platformUrl;
                    final info = await FirestoreService().getLatestUpdateInfoWithFallback();
                    if (info != null) {
                      final dl = info['download_urls'];
                      if (dl is Map) {
                        final platform = Theme.of(navigatorKey.currentContext!).platform;
                        if (platform == TargetPlatform.android) platformUrl = dl['android'] ?? dl['Android'];
                        else if (platform == TargetPlatform.windows) platformUrl = dl['windows'] ?? dl['Windows'];
                        else if (platform == TargetPlatform.macOS) platformUrl = dl['macos'] ?? dl['MacOS'];
                        else if (platform == TargetPlatform.linux) platformUrl = dl['linux'] ?? dl['Linux'];
                        else if (platform == TargetPlatform.iOS) platformUrl = dl['ios'] ?? dl['iOS'];
                      }
                    }

                    if (platformUrl != null && platformUrl.isNotEmpty) {
                      final Uri uri = Uri.parse(platformUrl);
                      if (await canLaunchUrl(uri)) {
                        final bool launched = await launchUrl(uri);
                        if (launched) {
                          debugPrint('Successfully opened download link: $platformUrl');
                        } else {
                          debugPrint('Failed to launch download link: $platformUrl');
                        }
                      } else {
                        debugPrint('Cannot launch URL: $platformUrl');
                      }
                    } else {
                      final platform = Theme.of(navigatorKey.currentContext!).platform;
                      debugPrint('No download link available for this platform: $platform');
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      });
    }
  } catch (e) {
    debugPrint('Update check failed: $e');
  }

  runApp(
    
    KEmpireApp());
}

// Helper function for version comparison
bool _isNewVersionAvailable(String current, String latest) {
  List<int> currentParts = current.split('.').map(int.parse).toList();
  List<int> latestParts = latest.split('.').map(int.parse).toList();

  for (int i = 0; i < latestParts.length; i++) {
    if (i >= currentParts.length) return true; // Latest has more parts, assume newer
    if (latestParts[i] > currentParts[i]) return true;
    if (latestParts[i] < currentParts[i]) return false;
  }
  return false; // Versions are equal or current is newer in some part
}

class KEmpireApp extends StatelessWidget {
  const KEmpireApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Assign navigatorKey
      debugShowCheckedModeBanner: false,
      title: 'K-Empire',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E4064), // Bleu foncé
        primaryColor: const Color(0xFFE5A81B), // Jaune/orangé
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE5A81B),       // Jaune/orangé for main interactive elements
          secondary: Color(0xFFE5A81B),      // Jaune/orangé for accents like FABs
          background: Color(0xFF0E4064),    // Bleu foncé for backgrounds
          surface: Color(0xFF1A4D74),       // A slightly lighter blue for cards, dialogs
          onPrimary: Colors.white,         // Text on yellow/orange elements
          onSecondary: Colors.white,       // Text on yellow/orange elements
          onBackground: Colors.white,      // Text on dark blue background
          onSurface: Colors.white,         // Text on cards/dialogs
          error: Colors.redAccent,
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0E4064), // Explicitly set AppBar background
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE5A81B), // Jaune/orangé
            foregroundColor: Colors.white, // Texte BLANC pour un bon contraste
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFE5A81B), // Jaune/orangé
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A4D74), // Lighter blue for text fields
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: const Color(0xFF1A4D74), // Lighter blue for cards
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
      home: AuthWrapper(hasSeenOnboarding: hasSeenOnboarding),
    );
  }
}
