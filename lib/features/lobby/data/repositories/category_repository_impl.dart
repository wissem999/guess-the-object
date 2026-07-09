import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/game_object.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_datasource.dart';
import '../models/category_dto.dart';
import '../models/game_object_dto.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final FirestoreDataSource _dataSource;

  CategoryRepositoryImpl(this._dataSource);

  @override
  Future<List<Category>> getCategories() async {
    try {
      final dtos = await _dataSource.getCategories();
      return dtos.map((json) {
        final dto = CategoryDto.fromJson({...json, 'id': json['id']});
        return Category(
          id: dto.id,
          name: dto.name,
          iconUrl: dto.iconUrl,
          description: dto.description,
          order: dto.order,
        );
      }).toList();
    } catch (e) {
      throw ServerException('Failed to load categories: $e');
    }
  }

  @override
  Future<List<GameObject>> getObjectsByCategory(String categoryId) async {
    try {
      final dtos = await _dataSource.getObjectsByCategory(categoryId);
      return dtos.map((json) {
        final dto = GameObjectDto.fromJson({...json, 'id': json['id']});
        return GameObject(
          id: dto.id,
          name: dto.name,
          categoryId: dto.categoryId,
          hints: dto.hints,
        );
      }).toList();
    } catch (e) {
      throw ServerException('Failed to load objects: $e');
    }
  }
}
