class GameObjectDto {
  final String id;
  final String name;
  final String categoryId;
  final List<String>? hints;

  const GameObjectDto({
    required this.id,
    required this.name,
    required this.categoryId,
    this.hints,
  });

  factory GameObjectDto.fromJson(Map<String, dynamic> json) {
    return GameObjectDto(
      id: json['id'] as String,
      name: json['name'] as String,
      categoryId: json['categoryId'] as String,
      hints: (json['hints'] as List<dynamic>?)?.cast<String>(),
    );
  }
}
