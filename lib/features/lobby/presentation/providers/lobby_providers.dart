import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/game_object.dart';
import '../../domain/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(ref.watch(firestoreDataSourceProvider));
});

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).getCategories();
});

final objectsByCategoryProvider =
    FutureProvider.family<List<GameObject>, String>((ref, categoryId) {
  return ref.watch(categoryRepositoryProvider).getObjectsByCategory(categoryId);
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);
