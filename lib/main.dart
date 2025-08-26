import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialisé avec succès');
  } catch (e) {
    debugPrint('Erreur lors de l\'initialisation Firebase: $e');
    // En mode développement, on peut continuer sans Firebase
    // En production, vous devriez gérer cette erreur différemment
  }
  
  runApp(const App());
}
