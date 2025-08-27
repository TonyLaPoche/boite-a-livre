import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/book_box.dart';
import '../../../../core/providers/book_box_provider.dart';

class EditRatingDialog extends StatefulWidget {
  final Rating rating;
  final VoidCallback onUpdated;

  const EditRatingDialog({
    super.key,
    required this.rating,
    required this.onUpdated,
  });

  @override
  State<EditRatingDialog> createState() => _EditRatingDialogState();
}

class _EditRatingDialogState extends State<EditRatingDialog> {
  late double _rating;
  late TextEditingController _commentController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.rating.rating;
    _commentController = TextEditingController(text: widget.rating.comment ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier mon avis'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sélection d'étoiles
            const Text('Note:'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            _rating = index + 1.0;
                          });
                        },
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                    size: 32,
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 16),
            
            // Champ de commentaire
            TextField(
              controller: _commentController,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                labelText: 'Commentaire (optionnel)',
                border: OutlineInputBorder(),
                hintText: 'Partagez votre expérience...',
              ),
              maxLines: 4,
              maxLength: 500,
            ),
          ],
        ),
      ),
      actions: [
        // Bouton Supprimer
        TextButton(
          onPressed: _isSubmitting ? null : () => _showDeleteConfirmation(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('Supprimer'),
        ),
        
        // Bouton Annuler
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        
        // Bouton Sauvegarder
        ElevatedButton(
          onPressed: _isSubmitting ? null : _updateRating,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Sauvegarder'),
        ),
      ],
    );
  }

  Future<void> _updateRating() async {
    setState(() {
      _isSubmitting = true;
    });

    final provider = Provider.of<BookBoxProvider>(context, listen: false);
    
    final success = await provider.updateRating(
      ratingId: widget.rating.id,
      newRating: _rating,
      newComment: _commentController.text.trim().isEmpty 
          ? null 
          : _commentController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        Navigator.pop(context);
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avis mis à jour avec succès!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Erreur lors de la mise à jour')),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'avis'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer votre avis ? '
          'Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _deleteRating(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRating() async {
    Navigator.pop(context); // Fermer la confirmation
    
    setState(() {
      _isSubmitting = true;
    });

    final provider = Provider.of<BookBoxProvider>(context, listen: false);
    
    final success = await provider.deleteRating(widget.rating.id);

    if (mounted) {
      Navigator.pop(context); // Fermer le dialogue d'édition
      
      if (success) {
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avis supprimé avec succès!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Erreur lors de la suppression')),
        );
      }
    }
  }
}
