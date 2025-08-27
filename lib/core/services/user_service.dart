import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache du profil utilisateur actuel
  UserProfile? _currentUserProfile;

  // Récupérer le profil de l'utilisateur actuel
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Si en cache, retourner
    if (_currentUserProfile?.uid == user.uid) {
      return _currentUserProfile;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        _currentUserProfile = UserProfile.fromDocument(doc);
      } else {
        // Créer un profil par défaut s'il n'existe pas
        _currentUserProfile = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        
        // Sauvegarder le nouveau profil
        await _firestore.collection('users').doc(user.uid).set(_currentUserProfile!.toMap());
      }
      
      return _currentUserProfile;
    } catch (e) {
      print('Erreur lors de la récupération du profil utilisateur: $e');
      return null;
    }
  }

  // Récupérer le nom d'affichage pour les avis
  Future<String> getDisplayNameForReviews() async {
    final profile = await getCurrentUserProfile();
    return profile?.displayNameForReviews ?? 'Utilisateur';
  }

  // Mettre à jour le profil utilisateur
  Future<bool> updateUserProfile({
    String? displayName,
    bool? useInitials,
  }) async {
    final user = _auth.currentUser;
    if (user == null || _currentUserProfile == null) return false;

    try {
      final updatedProfile = _currentUserProfile!.copyWith(
        displayName: displayName,
        useInitials: useInitials,
        lastLoginAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).update({
        'displayName': updatedProfile.displayName,
        'useInitials': updatedProfile.useInitials,
        'lastLoginAt': Timestamp.fromDate(updatedProfile.lastLoginAt),
      });

      _currentUserProfile = updatedProfile;
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du profil: $e');
      return false;
    }
  }

  // Vérifier si un utilisateur a déjà noté une BookBox
  Future<bool> hasUserRatedBookBox(String bookBoxId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final query = await _firestore
          .collection('ratings')
          .where('bookBoxId', isEqualTo: bookBoxId)
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification du rating: $e');
      return false;
    }
  }

  // Nettoyer le cache lors de la déconnexion
  void clearCache() {
    _currentUserProfile = null;
  }
}
