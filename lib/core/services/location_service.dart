import 'package:geolocator/geolocator.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  Position? _currentPosition;
  Position? get currentPosition => _currentPosition;

  // Vérifier les permissions de localisation
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  // Demander les permissions de localisation
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Les permissions sont refusées de manière permanente
      return false;
    }
    
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  // Vérifier si le GPS est activé
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Obtenir la position actuelle
  Future<Position?> getCurrentPosition() async {
    try {
      // Vérifier si le service est activé
      if (!await isLocationServiceEnabled()) {
        throw Exception('Le service de localisation est désactivé');
      }

      // Vérifier les permissions
      if (!await hasLocationPermission()) {
        if (!await requestLocationPermission()) {
          throw Exception('Permission de localisation refusée');
        }
      }

      // Obtenir la position avec les nouveaux paramètres
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

      return _currentPosition;
    } catch (e) {
      throw Exception('Erreur lors de l\'obtention de la position: $e');
    }
  }

  // Écouter les changements de position
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mise à jour tous les 10 mètres
      ),
    );
  }

  // Calculer la distance entre deux points
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Ouvrir les paramètres de localisation
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Ouvrir les paramètres d'application
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
