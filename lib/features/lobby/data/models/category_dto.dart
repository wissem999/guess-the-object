class CategoryDto {
  final String id;
  final String name;
  final String iconUrl;
  final String description;
  final int order;

  const CategoryDto({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.description,
    this.order = 0,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: json['id'] as String,
      name: json['name'] as String,
      iconUrl: json['iconUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}
