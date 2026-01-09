import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recovery_app/screens/Ho%C5%9FgeldinizEkran%C4%B1.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:recovery_app/screens/AnaEkran.dart';
import 'package:recovery_app/screens/AmeliyatEkran%C4%B1.dart';
import 'package:recovery_app/services/auth_service.dart';
import 'package:recovery_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recovery_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Shared Preferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(StorageService(prefs)),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recovery App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: authState.when(
        data: (user) {
          if (user != null) {
            return AuthWrapper();
          } else {
            return HoGeldinEkran();
          }
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, stack) => Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If we are here, user is logged in (handled by wrapper above)
    // Check if we have local surgery data
    final hasData = ref.watch(storageServiceProvider).hasSurgeryData();
    
    if (hasData) {
      return AnaEkran();
    } else {
      return AmeliyatEkran();
    }
  }
}
