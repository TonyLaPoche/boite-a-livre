import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/book_box.dart';
import '../../../../core/providers/book_box_provider.dart';
import '../widgets/rating_item.dart';
import '../widgets/edit_rating_dialog.dart';

class ReviewsScreen extends StatefulWidget {
  final BookBox bookBox;

  const ReviewsScreen({super.key, required this.bookBox});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  @override
  void initState() {
    super.initState();
    // Ne pas charger automatiquement pour éviter les crashes
    // L'utilisateur peut rafraîchir manuellement si besoin
  }

  Future<void> _loadRatings() async {
    // Méthode vide pour éviter les crashes
    // Les données se rafraîchissent avec le bouton 🔄 de la carte
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Avis - ${widget.bookBox.name}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<BookBoxProvider>(
        builder: (context, provider, child) {
          // Trouver la boîte mise à jour
          final updatedBox = provider.bookBoxes.firstWhere(
            (box) => box.id == widget.bookBox.id,
            orElse: () => widget.bookBox,
          );

          final ratings = updatedBox.ratings;

          return Column(
            children: [
              // En-tête avec stats
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Column(
                  children: [
                    Text(
                      updatedBox.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      updatedBox.city,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          '${updatedBox.averageRating.toStringAsFixed(1)}/5',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '(${ratings.length} avis)',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Liste des avis
              Expanded(
                child: ratings.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Aucun avis pour le moment',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Soyez le premier à donner votre avis !',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRatings,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: ratings.length,
                          itemBuilder: (context, index) {
                            final rating = ratings[index];
                            return RatingItem(
                              rating: rating,
                              bookBoxId: updatedBox.id,
                              onEdit: () => _editRating(rating),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewRating(),
        child: const Icon(Icons.rate_review),
      ),
    );
  }

  void _editRating(Rating rating) {
    showDialog(
      context: context,
      builder: (context) => EditRatingDialog(
        rating: rating,
        onUpdated: () {
          _loadRatings();
        },
      ),
    );
  }

  void _addNewRating() {
    double newRating = 3.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Noter ${widget.bookBox.name}'),
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
                        newRating = index + 1.0;
                      });
                    },
                    icon: Icon(
                      index < newRating ? Icons.star : Icons.star_border,
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
                bookBoxId: widget.bookBox.id,
                rating: newRating,
                comment: commentController.text.trim().isEmpty 
                    ? null 
                    : commentController.text.trim(),
              );
              
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Avis ajouté avec succès!')),
                  );
                  _loadRatings();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.error ?? 'Erreur')),
                  );
                }
              }
            },
            child: const Text('Publier'),
          ),
        ],
      ),
    );
  }
}
