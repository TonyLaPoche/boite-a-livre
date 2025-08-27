import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/providers/book_box_provider.dart';
import '../../../../core/services/location_service.dart';
import '../widgets/add_book_box_form.dart';
import '../../../reviews/presentation/screens/reviews_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    // Décaler le chargement des boîtes après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookBoxes();
    });
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final position = await LocationService.instance.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });

        // Centrer la carte seulement quand elle est prête
        _centerMapIfReady();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de localisation: $e')),
        );
      }
    }
  }

  void _centerMapIfReady() {
    if (_mapReady && _currentPosition != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            15.0,
          );
        } catch (e) {
          // Ignorer l'erreur si la carte n'est pas encore prête
          debugPrint('Carte pas encore prête: $e');
        }
      });
    }
  }

  Future<void> _loadBookBoxes() async {
    if (!mounted) return;
    final provider = Provider.of<BookBoxProvider>(context, listen: false);
    await provider.loadBookBoxes();
  }

  void _showAddBookBoxForm(LatLng tappedPoint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddBookBoxForm(
        latitude: tappedPoint.latitude,
        longitude: tappedPoint.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte des Boîtes à Livres'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _currentPosition != null && _mapReady
                ? () {
                    try {
                      _mapController.move(
                        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        15.0,
                      );
                    } catch (e) {
                      debugPrint('Erreur centrage carte: $e');
                    }
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadCurrentLocation();
              _loadBookBoxes();
            },
          ),
        ],
      ),
      body: _isLoadingLocation
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Localisation en cours...'),
                ],
              ),
            )
          : Consumer<BookBoxProvider>(
              builder: (context, provider, child) {
                return Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentPosition != null
                            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                            : const LatLng(46.603354, 1.888334), // Centre de la France
                        initialZoom: 13.0,
                        onTap: (tapPosition, point) {
                          _showAddBookBoxForm(point);
                        },
                        onMapReady: () {
                          setState(() {
                            _mapReady = true;
                          });
                          // Centrer la carte maintenant qu'elle est prête
                          _centerMapIfReady();
                        },
                      ),
                      children: [
                        // Couche de carte
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.antoineterrade.boitealivre',
                        ),
                        // Marqueurs des boîtes à livres
                        MarkerLayer(
                          markers: [
                            // Marqueur de position actuelle
                            if (_currentPosition != null)
                              Marker(
                                point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                width: 40,
                                height: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: const Icon(
                                    Icons.person_pin_circle,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            // Marqueurs des boîtes à livres
                            ...provider.bookBoxes.map(
                              (bookBox) => Marker(
                                point: LatLng(bookBox.latitude, bookBox.longitude),
                                width: 50,
                                height: 50,
                                child: GestureDetector(
                                  onTap: () => _showBookBoxDetails(bookBox),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.menu_book,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Indicateur de chargement
                    if (provider.isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentPosition != null) {
            _showAddBookBoxForm(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Position non disponible')),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showBookBoxDetails(bookBox) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bookBox.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Ville: ${bookBox.city}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.orange),
                const SizedBox(width: 4),
                Text('${bookBox.averageRating.toStringAsFixed(1)}/5'),
                const SizedBox(width: 8),
                Text('(${bookBox.ratings.length} avis)'),
              ],
            ),
            if (bookBox.photoUrl != null) ...[
              const SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(bookBox.photoUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviewsScreen(bookBox: bookBox),
                        ),
                      );
                    },
                    icon: const Icon(Icons.rate_review),
                    label: const Text('Lire les avis'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addRating(bookBox),
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Noter'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addRating(bookBox) {
    double rating = 3.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Noter ${bookBox.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Note:'),
            StatefulBuilder(
              builder: (context, setState) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        rating = index + 1.0;
                      });
                    },
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                    ),
                  );
                }),
              ),
            ),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Commentaire (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<BookBoxProvider>(context, listen: false);
              final success = await provider.addRating(
                bookBoxId: bookBox.id,
                rating: rating,
                comment: commentController.text.trim().isEmpty 
                    ? null 
                    : commentController.text.trim(),
              );
              
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note ajoutée avec succès!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.error ?? 'Erreur')),
                  );
                }
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}
