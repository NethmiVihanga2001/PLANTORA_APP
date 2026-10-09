class PlantModel {
  final String id;
  final String name;
  final String scientificName;
  final String family;
  final String category; // herb, flower, fruit, vegetable, tree
  final String description;
  final String imageUrl;
  final String emoji;
  final List<String> commonNames;
  final CareInfo careInfo;
  final List<String> diseases;
  final List<String> uses;
  final List<String> tags;
  final double confidenceScore;

  const PlantModel({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.family,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.emoji,
    required this.commonNames,
    required this.careInfo,
    required this.diseases,
    required this.uses,
    required this.tags,
    this.confidenceScore = 0.95,
  });

  factory PlantModel.fromMap(Map<String, dynamic> map) {
    return PlantModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      scientificName: map['scientificName'] ?? '',
      family: map['family'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      emoji: map['emoji'] ?? '🌿',
      commonNames: List<String>.from(map['commonNames'] ?? []),
      careInfo: CareInfo.fromMap(map['careInfo'] ?? {}),
      diseases: List<String>.from(map['diseases'] ?? []),
      uses: List<String>.from(map['uses'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      confidenceScore: (map['confidenceScore'] ?? 0.95).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'family': family,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'emoji': emoji,
      'commonNames': commonNames,
      'careInfo': careInfo.toMap(),
      'diseases': diseases,
      'uses': uses,
      'tags': tags,
      'confidenceScore': confidenceScore,
    };
  }
}

class CareInfo {
  final String wateringFrequency; // e.g., "Every 2-3 days"
  final String sunlightRequirement; // Full sun, Partial shade, Full shade
  final String soilType;
  final String temperature; // e.g., "18-25°C"
  final String humidity;
  final String fertilizer;
  final String pruning;
  final String propagation;
  final String growthRate; // Slow, Medium, Fast
  final String difficulty; // Easy, Moderate, Difficult
  final List<String> tips;

  const CareInfo({
    required this.wateringFrequency,
    required this.sunlightRequirement,
    required this.soilType,
    required this.temperature,
    required this.humidity,
    required this.fertilizer,
    required this.pruning,
    required this.propagation,
    required this.growthRate,
    required this.difficulty,
    this.tips = const [],
  });

  factory CareInfo.fromMap(Map<String, dynamic> map) {
    return CareInfo(
      wateringFrequency: map['wateringFrequency'] ?? 'Weekly',
      sunlightRequirement: map['sunlightRequirement'] ?? 'Full sun',
      soilType: map['soilType'] ?? 'Well-draining',
      temperature: map['temperature'] ?? '20-25°C',
      humidity: map['humidity'] ?? 'Moderate',
      fertilizer: map['fertilizer'] ?? 'Monthly',
      pruning: map['pruning'] ?? 'As needed',
      propagation: map['propagation'] ?? 'Seeds',
      growthRate: map['growthRate'] ?? 'Medium',
      difficulty: map['difficulty'] ?? 'Easy',
      tips: List<String>.from(map['tips'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'wateringFrequency': wateringFrequency,
      'sunlightRequirement': sunlightRequirement,
      'soilType': soilType,
      'temperature': temperature,
      'humidity': humidity,
      'fertilizer': fertilizer,
      'pruning': pruning,
      'propagation': propagation,
      'growthRate': growthRate,
      'difficulty': difficulty,
      'tips': tips,
    };
  }
}
