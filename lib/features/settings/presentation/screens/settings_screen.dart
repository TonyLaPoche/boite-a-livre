import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _biometricEnabled = false;
  String _language = 'Français';
  String _fontSize = 'Moyen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section Notifications
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            'Activer les notifications',
            'Recevoir des alertes pour vos livres',
            Icons.notifications_outlined,
            _notificationsEnabled,
            (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Section Apparence
          _buildSectionHeader('Apparence'),
          _buildSwitchTile(
            'Mode sombre',
            'Utiliser le thème sombre',
            Icons.dark_mode_outlined,
            _darkModeEnabled,
            (value) {
              setState(() {
                _darkModeEnabled = value;
              });
            },
          ),
          
          _buildListTile(
            'Taille de police',
            _fontSize,
            Icons.text_fields,
            () => _showFontSizeDialog(),
          ),
          
          const SizedBox(height: 24),
          
          // Section Sécurité
          _buildSectionHeader('Sécurité'),
          _buildSwitchTile(
            'Authentification biométrique',
            'Utiliser l\'empreinte ou Face ID',
            Icons.fingerprint_outlined,
            _biometricEnabled,
            (value) {
              setState(() {
                _biometricEnabled = value;
              });
            },
          ),
          
          _buildListTile(
            'Changer le mot de passe',
            '',
            Icons.lock_outlined,
            () {
              // TODO: Implémenter le changement de mot de passe
            },
          ),
          
          const SizedBox(height: 24),
          
          // Section Langue
          _buildSectionHeader('Langue'),
          _buildListTile(
            'Langue de l\'application',
            _language,
            Icons.language_outlined,
            () => _showLanguageDialog(),
          ),
          
          const SizedBox(height: 24),
          
          // Section À propos
          _buildSectionHeader('À propos'),
          _buildListTile(
            'Version de l\'application',
            '1.0.0',
            Icons.info_outlined,
            null,
          ),
          
          _buildListTile(
            'Conditions d\'utilisation',
            '',
            Icons.description_outlined,
            () {
              // TODO: Afficher les conditions d'utilisation
            },
          ),
          
          _buildListTile(
            'Politique de confidentialité',
            '',
            Icons.privacy_tip_outlined,
            () {
              // TODO: Afficher la politique de confidentialité
            },
          ),
          
          const SizedBox(height: 24),
          
          // Bouton de réinitialisation
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showResetDialog(),
              icon: const Icon(Icons.restore),
              label: const Text('Réinitialiser les paramètres'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Theme.of(context).colorScheme.error),
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        secondary: Icon(icon),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        title: Text(title),
        subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
        leading: Icon(icon),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Taille de police'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Petit',
            'Moyen',
            'Grand',
            'Très grand',
          ].map((size) => RadioListTile<String>(
            title: Text(size),
            value: size,
            groupValue: _fontSize,
            onChanged: (value) {
              setState(() {
                _fontSize = value!;
              });
              Navigator.of(context).pop();
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Langue de l\'application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Français',
            'English',
            'Español',
            'Deutsch',
          ].map((language) => RadioListTile<String>(
            title: Text(language),
            value: language,
            groupValue: _language,
            onChanged: (value) {
              setState(() {
                _language = value!;
              });
              Navigator.of(context).pop();
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser les paramètres'),
        content: const Text(
          'Êtes-vous sûr de vouloir réinitialiser tous les paramètres ? '
          'Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _notificationsEnabled = true;
                _darkModeEnabled = false;
                _biometricEnabled = false;
                _language = 'Français';
                _fontSize = 'Moyen';
              });
              Navigator.of(context).pop();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paramètres réinitialisés'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }
}
