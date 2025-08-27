import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/location_service.dart';
import '../services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Écouter les changements d'état d'authentification
    _auth.authStateChanges().listen((User? user) {
      final wasAuthenticated = _user != null;
      _user = user;
      
      // Demander les permissions de localisation quand l'utilisateur se connecte pour la première fois
      if (!wasAuthenticated && user != null) {
        _requestLocationPermissionOnLogin();
      }
      
      notifyListeners();
    });
  }
  
  // Demander automatiquement les permissions de localisation après connexion
  Future<void> _requestLocationPermissionOnLogin() async {
    try {
      // Attendre un peu pour que l'UI soit prête
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Vérifier si on a déjà les permissions
      final hasPermission = await LocationService.instance.hasLocationPermission();
      
      if (!hasPermission) {
        // Demander les permissions
        await LocationService.instance.requestLocationPermission();
      }
      
      // Initialiser/mettre à jour le profil utilisateur
      await UserService().getCurrentUserProfile();
    } catch (e) {
      debugPrint('Erreur lors de la demande de permissions: $e');
    }
  }

  // Réinitialiser l'erreur
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Définir l'état de chargement
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Définir l'erreur
  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  // Connexion avec Google
  Future<bool> signInWithGoogle() async {
    try {
      _clearError();
      _setLoading(true);
      
      // Déconnexion de Google si déjà connecté
      await _googleSignIn.signOut();
      
      // Lancer le processus de connexion Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        _setLoading(false);
        return false; // L'utilisateur a annulé
      }
      
      // Obtenir les informations d'authentification
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Créer les credentials Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Se connecter à Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        _setLoading(false);
        return true;
      } else {
        _setError('Échec de la connexion à Firebase');
        return false;
      }
    } catch (e) {
      _setError('Erreur lors de la connexion avec Google: $e');
      return false;
    }
  }

  // Connexion avec email/mot de passe
  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      _clearError();
      _setLoading(true);
      
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        _setLoading(false);
        return true;
      } else {
        _setError('Échec de la connexion');
        return false;
      }
    } catch (e) {
      String errorMessage = 'Erreur lors de la connexion';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'Aucun utilisateur trouvé avec cet email';
            break;
          case 'wrong-password':
            errorMessage = 'Mot de passe incorrect';
            break;
          case 'invalid-email':
            errorMessage = 'Adresse email invalide';
            break;
          case 'user-disabled':
            errorMessage = 'Ce compte a été désactivé';
            break;
          default:
            errorMessage = 'Erreur: ${e.message}';
        }
      }
      _setError(errorMessage);
      return false;
    }
  }
  
  // Inscription avec email/mot de passe
  Future<bool> signUpWithEmailPassword(String email, String password, String displayName) async {
    try {
      _clearError();
      _setLoading(true);
      
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Mettre à jour le nom d'affichage
        await userCredential.user!.updateDisplayName(displayName);
        await userCredential.user!.reload();
        _user = _auth.currentUser;
        
        _setLoading(false);
        return true;
      } else {
        _setError('Échec de la création du compte');
        return false;
      }
    } catch (e) {
      String errorMessage = 'Erreur lors de la création du compte';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'weak-password':
            errorMessage = 'Le mot de passe est trop faible';
            break;
          case 'email-already-in-use':
            errorMessage = 'Un compte existe déjà avec cet email';
            break;
          case 'invalid-email':
            errorMessage = 'Adresse email invalide';
            break;
          default:
            errorMessage = 'Erreur: ${e.message}';
        }
      }
      _setError(errorMessage);
      return false;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      _clearError();
      _setLoading(true);
      
      // Déconnexion de Google
      await _googleSignIn.signOut();
      
      // Déconnexion de Firebase
      await _auth.signOut();
      
      // Nettoyer le cache du profil utilisateur
      UserService().clearCache();
      
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la déconnexion: $e');
    }
  }

  // Nettoyer l'erreur manuellement
  void clearError() {
    _clearError();
  }
}
