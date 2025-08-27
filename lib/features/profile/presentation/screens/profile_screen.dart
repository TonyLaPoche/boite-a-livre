import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/book_box_provider.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/models/book_box.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await UserService().getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showEditProfileDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer2<AuthProvider, BookBoxProvider>(
              builder: (context, authProvider, bookBoxProvider, child) {
                final user = authProvider.user;
          
                final myBookBoxes = bookBoxProvider.bookBoxes.where((box) => box.createdBy == user?.uid).toList();
                final myReportedBookBoxes = myBookBoxes.where((box) => box.status == BookBoxStatus.reported).toList();
                final myRatingsCount = bookBoxProvider.bookBoxes
                    .expand((box) => box.ratings)
                    .where((rating) => rating.userId == user?.uid)
                    .length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête du profil
                      _buildProfileHeader(user),
                      
                      const SizedBox(height: 24),
                      
                      // Configuration d'affichage
                      _buildDisplaySettingsCard(),
                      
                      const SizedBox(height: 24),
                      
                      // Mes statistiques personnelles
                      _buildMyStatsCard(myBookBoxes.length, myRatingsCount),
                      
                      const SizedBox(height: 24),
                      
                      // Mes boîtes à livres créées
                      _buildMyBookBoxesSection(myBookBoxes),
                      
                      const SizedBox(height: 24),
                      
                      // Section modération (si j'ai des BookBox signalées)
                      if (myReportedBookBoxes.isNotEmpty) ...[
                        _buildModerationSection(myReportedBookBoxes),
                        const SizedBox(height: 24),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // Bouton de déconnexion
                      _buildLogoutButton(authProvider),
                    ],
                  ),
                );
        },
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              _userProfile?.displayNameForReviews ?? 'U',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userProfile?.displayName ?? user?.email?.split('@')[0] ?? 'Utilisateur',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          if (user?.email != null) ...[
            const SizedBox(height: 8),
            Text(
              user!.email!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDisplaySettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Affichage dans les avis',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Utiliser des initiales : ${_userProfile?.displayNameForReviews ?? "U"}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Switch(
                  value: _userProfile?.useInitials ?? false,
                  onChanged: (value) async {
                    final success = await UserService().updateUserProfile(useInitials: value);
                    if (success && mounted) {
                      await _loadUserProfile();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyStatsCard(int myBookBoxes, int myRatings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Mes contributions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Boîtes créées', myBookBoxes.toString(), Icons.add_location),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem('Avis donnés', myRatings.toString(), Icons.rate_review),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMyBookBoxesSection(List myBookBoxes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Mes boîtes à livres (${myBookBoxes.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            myBookBoxes.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Vous n\'avez créé aucune boîte à livres pour l\'instant.'),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: myBookBoxes.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final bookBox = myBookBoxes[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            '${bookBox.ratings.length}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(bookBox.name),
                        subtitle: Text('${bookBox.city} • ${bookBox.averageRating.toStringAsFixed(1)}⭐'),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // TODO: Navigation vers détails de la BookBox
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(authProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Déconnexion'),
              content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Déconnexion'),
                ),
              ],
            ),
          );
          
          if (confirmed == true && context.mounted) {
            await authProvider.signOut();
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text('Se déconnecter'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: _userProfile?.displayName ?? '');
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom d\'affichage',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final success = await UserService().updateUserProfile(displayName: result);
      if (success && mounted) {
        await _loadUserProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès!')),
        );
      }
    }

    nameController.dispose();
  }

  Widget _buildModerationSection(List myReportedBookBoxes) {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red[700]),
                const SizedBox(width: 12),
                Text(
                  'Modération requise (${myReportedBookBoxes.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Ces boîtes à livres ont été signalées et nécessitent votre attention:',
              style: TextStyle(color: Colors.red[600]),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: myReportedBookBoxes.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final bookBox = myReportedBookBoxes[index];
                final latestReport = bookBox.reports.isNotEmpty ? bookBox.reports.last : null;
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.red[600], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bookBox.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (latestReport != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Raison: ${_getReportReasonText(latestReport.reason)}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        if (latestReport.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Description: ${latestReport.description}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _revalidateBookBox(bookBox.id),
                              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                              label: const Text('Revalider', style: TextStyle(color: Colors.green)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.green),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _deleteBookBox(bookBox),
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getReportReasonText(ReportReason reason) {
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

  Future<void> _revalidateBookBox(String bookBoxId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revalider la boîte à livres'),
        content: const Text(
          'Êtes-vous sûr que cette boîte à livres est correcte et doit rester visible ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revalider'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await Provider.of<BookBoxProvider>(context, listen: false)
          .revalidateBookBox(bookBoxId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Boîte à livres revalidée ! Retournez sur la carte pour voir les changements.'
                : 'Erreur lors de la revalidation'),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _deleteBookBox(bookBox) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer définitivement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir supprimer "${bookBox.name}" ?'),
            const SizedBox(height: 8),
            const Text(
              'Cette action est irréversible et supprimera également tous les avis associés.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await Provider.of<BookBoxProvider>(context, listen: false)
          .deleteBookBox(bookBox.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
                ? 'Boîte à livres supprimée définitivement ! Retournez sur la carte pour voir les changements.'
                : 'Erreur lors de la suppression'),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
