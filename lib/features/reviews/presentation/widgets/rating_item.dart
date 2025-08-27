import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/book_box.dart';
import '../../../../core/providers/book_box_provider.dart';

class RatingItem extends StatelessWidget {
  final Rating rating;
  final String bookBoxId;
  final VoidCallback? onEdit;

  const RatingItem({
    super.key,
    required this.rating,
    required this.bookBoxId,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookBoxProvider>(context, listen: false);
    final currentUser = provider.currentUser;
    final isOwner = currentUser?.uid == rating.userId;
    final hasUpVoted = currentUser != null && rating.upVotes.contains(currentUser.uid);
    final hasDownVoted = currentUser != null && rating.downVotes.contains(currentUser.uid);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isOwner ? Colors.blue[50] : null,
      child: Container(
        decoration: isOwner 
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge "Mon avis" pour le propriétaire
              if (isOwner) ...[
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Mon avis',
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            // En-tête avec étoiles et actions
            Row(
              children: [
                // Étoiles
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating.rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 20,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(
                  '${rating.rating.toStringAsFixed(1)}/5',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                
                // Bouton d'édition pour le propriétaire
                if (isOwner && onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                    tooltip: 'Modifier mon avis',
                  ),
              ],
            ),

            // Date
            const SizedBox(height: 8),
            Text(
              _formatDate(rating.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),

            // Commentaire
            if (rating.comment != null && rating.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                rating.comment!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],

            // Actions de vote
            const SizedBox(height: 16),
            Row(
              children: [
                // Upvote
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        hasUpVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                        color: hasUpVoted ? Colors.green : (isOwner ? Colors.grey[300] : Colors.grey),
                      ),
                      onPressed: currentUser != null && !isOwner ? () => _voteUp(context) : null,
                      tooltip: isOwner ? 'Vous ne pouvez pas voter sur votre propre avis' : 'Utile',
                    ),
                    Text(
                      '${rating.upVotes.length}',
                      style: TextStyle(
                        color: hasUpVoted ? Colors.green : (isOwner ? Colors.grey[400] : Colors.grey),
                        fontWeight: hasUpVoted ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // Downvote
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        hasDownVoted ? Icons.thumb_down : Icons.thumb_down_outlined,
                        color: hasDownVoted ? Colors.red : (isOwner ? Colors.grey[300] : Colors.grey),
                      ),
                      onPressed: currentUser != null && !isOwner ? () => _voteDown(context) : null,
                      tooltip: isOwner ? 'Vous ne pouvez pas voter sur votre propre avis' : 'Pas utile',
                    ),
                    Text(
                      '${rating.downVotes.length}',
                      style: TextStyle(
                        color: hasDownVoted ? Colors.red : (isOwner ? Colors.grey[400] : Colors.grey),
                        fontWeight: hasDownVoted ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Score total
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(rating.voteScore).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getScoreColor(rating.voteScore)),
                  ),
                  child: Text(
                    'Score: ${rating.voteScore >= 0 ? '+' : ''}${rating.voteScore}',
                    style: TextStyle(
                      color: _getScoreColor(rating.voteScore),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getScoreColor(int score) {
    if (score > 0) return Colors.green;
    if (score < 0) return Colors.red;
    return Colors.grey;
  }

  Future<void> _voteUp(BuildContext context) async {
    final provider = Provider.of<BookBoxProvider>(context, listen: false);
    await provider.voteOnRating(rating.id, true);
  }

  Future<void> _voteDown(BuildContext context) async {
    final provider = Provider.of<BookBoxProvider>(context, listen: false);
    await provider.voteOnRating(rating.id, false);
  }
}
