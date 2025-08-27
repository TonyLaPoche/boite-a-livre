import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/book_box_provider.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/models/user_profile.dart';

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
}
