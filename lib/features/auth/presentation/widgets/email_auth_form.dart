import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider.dart';

class EmailAuthForm extends StatefulWidget {
  const EmailAuthForm({super.key});

  @override
  State<EmailAuthForm> createState() => _EmailAuthFormState();
}

class _EmailAuthFormState extends State<EmailAuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              // Champ nom (seulement pour l'inscription)
              if (_isSignUp) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (_isSignUp && (value == null || value.trim().isEmpty)) {
                      return 'Le nom est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              // Champ email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Adresse email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'L\'email est obligatoire';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Adresse email invalide';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Champ mot de passe
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le mot de passe est obligatoire';
                  }
                  if (_isSignUp && value.length < 6) {
                    return 'Le mot de passe doit contenir au moins 6 caractères';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Bouton de connexion/inscription
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      bool success;
                      if (_isSignUp) {
                        success = await authProvider.signUpWithEmailPassword(
                          _emailController.text.trim(),
                          _passwordController.text,
                          _nameController.text.trim(),
                        );
                      } else {
                        success = await authProvider.signInWithEmailPassword(
                          _emailController.text.trim(),
                          _passwordController.text,
                        );
                      }
                      
                      if (success && context.mounted) {
                        context.go('/home');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: authProvider.isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          _isSignUp ? 'S\'inscrire' : 'Se connecter',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Bouton pour basculer entre connexion et inscription
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSignUp = !_isSignUp;
                    _formKey.currentState?.reset();
                  });
                },
                child: Text(
                  _isSignUp
                      ? 'Déjà un compte ? Se connecter'
                      : 'Pas de compte ? S\'inscrire',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
