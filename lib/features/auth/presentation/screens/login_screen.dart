import 'package:flutter/material.dart';
import '../widgets/social_auth_buttons.dart';
import '../widgets/email_auth_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Espacement en haut
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              
              // Logo et titre
              const Icon(
                Icons.book,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              Text(
                'Boîte à Livre',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Votre bibliothèque personnelle',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Boutons d'authentification
              const SocialAuthButtons(),
              
              const SizedBox(height: 16),
              
              // Formulaire email/mot de passe
              const EmailAuthForm(),
              
              const SizedBox(height: 24),
              
              // Message d'information
              Text(
                'En vous connectant, vous acceptez nos conditions d\'utilisation',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              
              // Espacement en bas
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            ],
          ),
        ),
      ),
    );
  }
}
