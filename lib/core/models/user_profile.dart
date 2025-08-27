import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final bool useInitials;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.useInitials = false,
    required this.createdAt,
    required this.lastLoginAt,
  });

  // Nom à afficher dans les avis
  String get displayNameForReviews {
    if (displayName != null && displayName!.isNotEmpty) {
      if (useInitials) {
        return _getInitials(displayName!);
      }
      return displayName!;
    }
    
    // Par défaut, utiliser les initiales de l'email
    return _getInitials(email);
  }

  String _getInitials(String text) {
    final words = text.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0].length >= 2 
          ? '${words[0][0]}${words[0][1]}'.toUpperCase()
          : words[0][0].toUpperCase();
    }
    return 'U'; // User par défaut
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'useInitials': useInitials,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      useInitials: map['useInitials'] ?? false,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLoginAt: map['lastLoginAt'] != null 
          ? (map['lastLoginAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory UserProfile.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile.fromMap(data);
  }

  UserProfile copyWith({
    String? displayName,
    bool? useInitials,
    DateTime? lastLoginAt,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      useInitials: useInitials ?? this.useInitials,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
