import '../entities/category.dart';
import '../entities/game_object.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories();
  Future<List<GameObject>> getObjectsByCategory(String categoryId);
}
