import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('SmartKart FlutterError: ${details.exception}');
      };

      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (error) {
        // Authentication still works through the mock/OTP flow without a
        // configured Firebase back end. Log and continue rather than crashing
        // the app on startup.
        debugPrint('SmartKart Firebase init failed: $error');
      }

      runApp(const ProviderScope(child: SmartKartApp()));
    },
    (error, stack) {
      debugPrint('SmartKart uncaught async error: $error');
    },
  );
}
