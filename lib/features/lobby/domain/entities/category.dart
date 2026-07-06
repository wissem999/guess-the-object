class Category {
  final String id;
  final String name;
  final String iconUrl;
  final String description;
  final int order;

  const Category({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.description,
    this.order = 0,
  });
}
