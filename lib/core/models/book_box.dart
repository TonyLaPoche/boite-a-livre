import 'package:cloud_firestore/cloud_firestore.dart';

class BookBox {
  final String id;
  final String name;
  final String city;
  final double latitude;
  final double longitude;
  final String? photoUrl;
  final String createdBy;
  final DateTime createdAt;
  final List<Rating> ratings;

  const BookBox({
    required this.id,
    required this.name,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.photoUrl,
    required this.createdBy,
    required this.createdAt,
    this.ratings = const [],
  });

  // Calcul de la note moyenne
  double get averageRating {
    if (ratings.isEmpty) return 0.0;
    return ratings.map((r) => r.rating).reduce((a, b) => a + b) / ratings.length;
  }

  // Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'photoUrl': photoUrl,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Création depuis Map Firestore
  factory BookBox.fromMap(Map<String, dynamic> map) {
    return BookBox(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      city: map['city'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      photoUrl: map['photoUrl'],
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // Création depuis DocumentSnapshot
  factory BookBox.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookBox.fromMap(data);
  }

  // Copie avec modifications
  BookBox copyWith({
    String? id,
    String? name,
    String? city,
    double? latitude,
    double? longitude,
    String? photoUrl,
    String? createdBy,
    DateTime? createdAt,
    List<Rating>? ratings,
  }) {
    return BookBox(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      photoUrl: photoUrl ?? this.photoUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      ratings: ratings ?? this.ratings,
    );
  }

  @override
  String toString() {
    return 'BookBox(id: $id, name: $name, city: $city, lat: $latitude, lng: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookBox && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Rating {
  final String id;
  final String bookBoxId;
  final String userId;
  final double rating; // 0.0 à 5.0
  final String? comment;
  final DateTime createdAt;
  final List<String> upVotes; // IDs des utilisateurs qui ont voté +
  final List<String> downVotes; // IDs des utilisateurs qui ont voté -

  const Rating({
    required this.id,
    required this.bookBoxId,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.upVotes = const [],
    this.downVotes = const [],
  });

  // Score de vote (upvotes - downvotes)
  int get voteScore => upVotes.length - downVotes.length;

  // Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookBoxId': bookBoxId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'upVotes': upVotes,
      'downVotes': downVotes,
    };
  }

  // Création depuis Map Firestore
  factory Rating.fromMap(Map<String, dynamic> map) {
    return Rating(
      id: map['id'] ?? '',
      bookBoxId: map['bookBoxId'] ?? '',
      userId: map['userId'] ?? '',
      rating: map['rating']?.toDouble() ?? 0.0,
      comment: map['comment'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      upVotes: List<String>.from(map['upVotes'] ?? []),
      downVotes: List<String>.from(map['downVotes'] ?? []),
    );
  }

  // Création depuis DocumentSnapshot
  factory Rating.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Rating.fromMap(data);
  }

  @override
  String toString() {
    return 'Rating(id: $id, rating: $rating, userId: $userId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Rating && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
