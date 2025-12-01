
class Course {
  final String id;
  final String name;
  final String description;
  final List<Map<String, String>>? resources; // New field

  Course({
    required this.id,
    required this.name,
    required this.description,
    this.resources, // Include in constructor
  });

  // Factory constructor to create a Course from a Map (e.g., from Firestore)
  factory Course.fromMap(String id, Map<String, dynamic> map) {
    return Course(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      resources: (map['resources'] as List<dynamic>?)
          ?.where((e) => e is Map<String, dynamic>) // Explicitly check if it's a map
          .map((e) => Map<String, String>.from(e as Map<String, dynamic>)) // Cast explicitly
          .toList(),
    );
  }

  // Method to convert a Course to a Map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'resources': resources,
    };
  }
}
