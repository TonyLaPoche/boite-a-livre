import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/providers/book_box_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/models/book_box.dart';
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
            icon: const Icon(Icons.refresh, size: 28),
            onPressed: () {
              _loadCurrentLocation();
              _loadBookBoxes();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔄 Données actualisées !'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Actualiser les données',
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
          : Consumer2<BookBoxProvider, AuthProvider>(
              builder: (context, provider, authProvider, child) {
                final currentUserId = authProvider.user?.uid;
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
                            // Marqueurs des boîtes à livres (filtrées selon statut)
                            ...provider.bookBoxes
                                .where((bookBox) => _shouldShowBookBox(bookBox, currentUserId))
                                .map(
                              (bookBox) => Marker(
                                point: LatLng(bookBox.latitude, bookBox.longitude),
                                width: 50,
                                height: 50,
                                child: GestureDetector(
                                  onTap: () => _showBookBoxDetails(bookBox),
                                  child: _buildBookBoxMarker(bookBox, currentUserId),
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
            // Bouton signaler (seulement si ce n'est pas ma BookBox)
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final isMyBookBox = bookBox.createdBy == authProvider.user?.uid;
                if (isMyBookBox) return const SizedBox.shrink();
                
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showReportDialog(bookBox),
                        icon: const Icon(Icons.flag_outlined, color: Colors.red),
                        label: const Text('Signaler un problème', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
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
                    const SnackBar(
                      content: Text('Note ajoutée ! Appuyez sur 🔄 pour voir votre avis.'),
                      duration: Duration(seconds: 3),
                    ),
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

  // Détermine si une BookBox doit être affichée selon son statut
  bool _shouldShowBookBox(BookBox bookBox, String? currentUserId) {
    switch (bookBox.status) {
      case BookBoxStatus.normal:
      case BookBoxStatus.verified:
        return true; // Toujours visible
      case BookBoxStatus.reported:
        // Visible seulement pour le propriétaire
        return bookBox.createdBy == currentUserId;
    }
  }

  // Construit le marqueur selon le type de BookBox
  Widget _buildBookBoxMarker(BookBox bookBox, String? currentUserId) {
    final isMyBookBox = bookBox.createdBy == currentUserId;
    final isReported = bookBox.status == BookBoxStatus.reported;
    
    // Déterminer couleur et icône
    Color markerColor;
    IconData markerIcon;
    
    if (isReported) {
      markerColor = Colors.red;
      markerIcon = Icons.warning;
    } else if (isMyBookBox) {
      markerColor = Colors.green;
      markerIcon = Icons.home;
    } else {
      markerColor = Colors.orange;
      markerIcon = Icons.menu_book;
    }

    return Container(
      decoration: BoxDecoration(
        color: markerColor,
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
      child: Icon(
        markerIcon,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  // Dialog de signalement d'une BookBox
  void _showReportDialog(BookBox bookBox) {
    // Fermer la modal ET ouvrir le dialog en une seule action
    Navigator.pop(context); // Fermer la modal des détails
    
    // Attendre que l'animation de fermeture se termine
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      
      ReportReason? selectedReason;
      final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Signaler un problème'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Boîte à livres: ${bookBox.name}'),
                const SizedBox(height: 16),
                const Text('Raison du signalement:'),
                const SizedBox(height: 8),
                ...ReportReason.values.map((reason) => RadioListTile<ReportReason>(
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) => setState(() => selectedReason = value),
                  title: Text(_getReasonText(reason)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                )),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optionnelle)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: selectedReason != null
                  ? () => _submitReport(bookBox, selectedReason!, descriptionController.text.trim())
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Signaler', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    }); // Fermer le Future.delayed
  }

  String _getReasonText(ReportReason reason) {
    switch (reason) {
      case ReportReason.duplicate:
        return 'Lieu en double';
      case ReportReason.notFound:
        return 'Boîte inexistante';
      case ReportReason.inappropriate:
        return 'Contenu inapproprié';
      case ReportReason.wrongLocation:
        return 'Mauvaise localisation';
      case ReportReason.damaged:
        return 'Boîte endommagée';
      case ReportReason.other:
        return 'Autre raison';
    }
  }

  Future<void> _submitReport(BookBox bookBox, ReportReason reason, String description) async {
    // Traitement simple sans navigation complexe
    try {
      final provider = Provider.of<BookBoxProvider>(context, listen: false);
      Navigator.pop(context); // Fermer seulement le dialog de signalement
      
      final success = await provider.reportBookBox(
        bookBoxId: bookBox.id,
        reason: reason,
        description: description.isEmpty ? null : description,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signalement envoyé. Merci ! Appuyez sur 🔄 pour voir les changements.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Erreur lors du signalement'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
