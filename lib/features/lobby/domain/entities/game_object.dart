class GameObject {
  final String id;
  final String name;
  final String categoryId;
  final List<String>? hints;

  const GameObject({
    required this.id,
    required this.name,
    required this.categoryId,
    this.hints,
  });
}
