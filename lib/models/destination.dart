import 'package:flutter/foundation.dart' show listEquals;

/// A single place worth visiting.
///
/// Mirrors the `Destination` schema of the Tourist Explorer REST API, whose
/// JSON is camelCase and maps onto these fields one for one. This type is a
/// passive value holder: fetching lives in the data source, querying in the
/// repository.
class Destination {
  const Destination({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.longDescription,
    required this.category,
    required this.province,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.popularity,
    required this.imageUrl,
    required this.gallery,
    required this.openingHours,
    required this.entryFee,
    required this.bestTimeToVisit,
    required this.suggestedDuration,
    required this.latitude,
    required this.longitude,
    required this.tags,
  });

  /// Builds a [Destination] from one decoded JSON object.
  ///
  /// Throws [TypeError] if a field is missing or has an unexpected type, which
  /// is deliberate: malformed seed data should fail loudly at load time rather
  /// than surface as a blank card later.
  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'] as int,
      name: json['name'] as String,
      shortDescription: json['shortDescription'] as String,
      longDescription: json['longDescription'] as String,
      category: json['category'] as String,
      province: json['province'] as String,
      address: json['address'] as String,
      // `num` first: the JSON holds whole numbers for some ratings.
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      popularity: json['popularity'] as int,
      imageUrl: json['imageUrl'] as String,
      gallery: _stringList(json['gallery']),
      openingHours: json['openingHours'] as String,
      entryFee: json['entryFee'] as String,
      bestTimeToVisit: json['bestTimeToVisit'] as String,
      suggestedDuration: json['suggestedDuration'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      tags: _stringList(json['tags']),
    );
  }

  /// Stable identifier, unique within the catalogue.
  final int id;
  final String name;

  /// One-line summary, for list cards.
  final String shortDescription;

  /// Full write-up, for the detail screen.
  final String longDescription;

  /// Broad grouping such as `Temple`, `Beach` or `Nature`.
  final String category;

  /// Cambodian province the destination sits in.
  final String province;
  final String address;

  /// Average score out of 5.
  final double rating;
  final int reviewCount;

  /// Editorial ranking out of 100; the default list sort.
  final int popularity;

  /// Primary image, used for list cards and the detail header.
  final String imageUrl;

  /// Additional images for the detail screen carousel.
  final List<String> gallery;

  final String openingHours;
  final String entryFee;
  final String bestTimeToVisit;

  /// Rough visit length, e.g. `Half day`.
  final String suggestedDuration;

  final double latitude;
  final double longitude;

  /// Free-form labels used for search and filtering.
  final List<String> tags;

  /// Inverse of [Destination.fromJson]; round-trips back to the seed format.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'shortDescription': shortDescription,
      'longDescription': longDescription,
      'category': category,
      'province': province,
      'address': address,
      'rating': rating,
      'reviewCount': reviewCount,
      'popularity': popularity,
      'imageUrl': imageUrl,
      'gallery': gallery,
      'openingHours': openingHours,
      'entryFee': entryFee,
      'bestTimeToVisit': bestTimeToVisit,
      'suggestedDuration': suggestedDuration,
      'latitude': latitude,
      'longitude': longitude,
      'tags': tags,
    };
  }

  static List<String> _stringList(Object? value) {
    return (value as List<dynamic>).cast<String>();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Destination &&
        other.id == id &&
        other.name == name &&
        other.shortDescription == shortDescription &&
        other.longDescription == longDescription &&
        other.category == category &&
        other.province == province &&
        other.address == address &&
        other.rating == rating &&
        other.reviewCount == reviewCount &&
        other.popularity == popularity &&
        other.imageUrl == imageUrl &&
        listEquals(other.gallery, gallery) &&
        other.openingHours == openingHours &&
        other.entryFee == entryFee &&
        other.bestTimeToVisit == bestTimeToVisit &&
        other.suggestedDuration == suggestedDuration &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        listEquals(other.tags, tags);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      shortDescription,
      longDescription,
      category,
      province,
      address,
      rating,
      reviewCount,
      popularity,
      imageUrl,
      Object.hashAll(gallery),
      openingHours,
      entryFee,
      bestTimeToVisit,
      suggestedDuration,
      latitude,
      longitude,
      Object.hashAll(tags),
    );
  }

  @override
  String toString() => 'Destination($id, $name)';
}
