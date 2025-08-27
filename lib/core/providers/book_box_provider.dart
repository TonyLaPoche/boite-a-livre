import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'dart:math' as math;
import '../models/book_box.dart';

class BookBoxProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  List<BookBox> _bookBoxes = [];
  bool _isLoading = false;
  String? _error;

  List<BookBox> get bookBoxes => _bookBoxes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get currentUser => _auth.currentUser;

  // Charger toutes les boîtes à livres
  Future<void> loadBookBoxes() async {
    _setLoading(true);
    _clearError();

    try {
      final querySnapshot = await _firestore
          .collection('bookBoxes')
          .orderBy('createdAt', descending: true)
          .get();

      _bookBoxes = querySnapshot.docs
          .map((doc) => BookBox.fromDocument(doc))
          .toList();

      // Charger les ratings pour chaque boîte
      for (int i = 0; i < _bookBoxes.length; i++) {
        final ratings = await _loadRatingsForBookBox(_bookBoxes[i].id);
        _bookBoxes[i] = _bookBoxes[i].copyWith(ratings: ratings);
      }

      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement des boîtes à livres: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Charger les ratings d'une boîte spécifique
  Future<List<Rating>> _loadRatingsForBookBox(String bookBoxId) async {
    try {
      final querySnapshot = await _firestore
          .collection('ratings')
          .where('bookBoxId', isEqualTo: bookBoxId)
          .get();

      return querySnapshot.docs
          .map((doc) => Rating.fromDocument(doc))
          .toList();
    } catch (e) {
      debugPrint('Erreur lors du chargement des ratings: $e');
      return [];
    }
  }

  // Créer une nouvelle boîte à livres
  Future<bool> createBookBox({
    required String name,
    required String city,
    required double latitude,
    required double longitude,
    XFile? imageFile,
  }) async {
    if (currentUser == null) {
      _setError('Vous devez être connecté pour créer une boîte à livres');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final bookBoxId = _uuid.v4();
      String? photoUrl;

      // Upload de l'image si fournie
      if (imageFile != null) {
        photoUrl = await _uploadImage(imageFile, bookBoxId);
        if (photoUrl == null) {
          _setError('Erreur lors de l\'upload de l\'image');
          return false;
        }
      }

      // Créer la boîte à livres
      final bookBox = BookBox(
        id: bookBoxId,
        name: name,
        city: city,
        latitude: latitude,
        longitude: longitude,
        photoUrl: photoUrl,
        createdBy: currentUser!.uid,
        createdAt: DateTime.now(),
      );

      // Sauvegarder dans Firestore
      await _firestore
          .collection('bookBoxes')
          .doc(bookBoxId)
          .set(bookBox.toMap());

      // Ajouter à la liste locale
      _bookBoxes.insert(0, bookBox);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Erreur lors de la création de la boîte à livres: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Upload d'image vers Firebase Storage
  Future<String?> _uploadImage(XFile imageFile, String bookBoxId) async {
    try {
      final file = File(imageFile.path);
      final ref = _storage.ref().child('bookBoxes/$bookBoxId.jpg');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Erreur upload image: $e');
      return null;
    }
  }

  // Ajouter une note à une boîte à livres
  Future<bool> addRating({
    required String bookBoxId,
    required double rating,
    String? comment,
  }) async {
    if (currentUser == null) {
      _setError('Vous devez être connecté pour noter une boîte à livres');
      return false;
    }

    if (rating < 0 || rating > 5) {
      _setError('La note doit être entre 0 et 5');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final ratingId = _uuid.v4();
      final newRating = Rating(
        id: ratingId,
        bookBoxId: bookBoxId,
        userId: currentUser!.uid,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      // Sauvegarder dans Firestore
      await _firestore
          .collection('ratings')
          .doc(ratingId)
          .set(newRating.toMap());

      // Mettre à jour localement
      final bookBoxIndex = _bookBoxes.indexWhere((box) => box.id == bookBoxId);
      if (bookBoxIndex != -1) {
        final updatedRatings = [..._bookBoxes[bookBoxIndex].ratings, newRating];
        _bookBoxes[bookBoxIndex] = _bookBoxes[bookBoxIndex].copyWith(
          ratings: updatedRatings,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Erreur lors de l\'ajout de la note: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Vérifier si une nouvelle boîte est proche d'une existante
  List<BookBox> findNearbyBookBoxes(double latitude, double longitude, {double radiusKm = 0.1}) {
    return _bookBoxes.where((box) {
      final distance = _calculateDistance(
        latitude, longitude,
        box.latitude, box.longitude,
      );
      return distance <= radiusKm;
    }).toList();
  }

  // Calculer la distance entre deux points (formule de Haversine simplifiée)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Rayon de la Terre en km
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Sélectionner une image depuis la galerie
  Future<XFile?> pickImage() async {
    try {
      return await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );
    } catch (e) {
      _setError('Erreur lors de la sélection de l\'image: $e');
      return null;
    }
  }

  // Prendre une photo avec l'appareil
  Future<XFile?> takePhoto() async {
    try {
      return await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
      );
    } catch (e) {
      _setError('Erreur lors de la prise de photo: $e');
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
