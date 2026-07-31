import 'package:supabase_flutter/supabase_flutter.dart';

abstract class CategoryDataSource {
  /// Obtiene todas las categorías dinámicamente desde la BD
  /// Filtra por tipo si se especifica (expense, income, o null para todas)
  Future<List<Map<String, dynamic>>> getCategories({String? type});
}

class CategoryDataSourceImpl implements CategoryDataSource {
  final SupabaseClient supabaseClient;

  // Caché de categorías
  Map<String, String> _categoryIdToName = {};
  Map<String, String> _categoryNameToId = {};
  Map<String, String> _categoryIdToIcon = {};
  Map<String, String> _categoryIdToType = {};
  bool _categoriesLoaded = false;

  CategoryDataSourceImpl(this.supabaseClient);

  /// Carga las categorías desde la BD y las cachea
  Future<void> loadCategories() async {
    if (_categoriesLoaded) return;

    try {
      final response = await supabaseClient.from('categories').select('id, name, icon, type');

      _categoryIdToName.clear();
      _categoryNameToId.clear();
      _categoryIdToIcon.clear();
      _categoryIdToType.clear();

      for (var category in response as List) {
        final id = category['id'] as String;
        final name = category['name'] as String;
        final icon = category['icon'] as String?;
        final type = category['type'] as String?;

        _categoryIdToName[id] = name;
        _categoryNameToId[name] = id;
        if (icon != null) {
          _categoryIdToIcon[id] = icon;
        }
        if (type != null) {
          _categoryIdToType[id] = type;
        }
      }

      _categoriesLoaded = true;
    } catch (e) {
      print('Error cargando categorías: $e');
      _categoriesLoaded = false;
    }
  }

  /// Obtiene el nombre de una categoría desde su UUID
  String getCategoryName(String? categoryId) {
    if (categoryId == null) return 'Otro';
    return _categoryIdToName[categoryId] ?? 'Otro';
  }

  /// Obtiene el UUID de una categoría desde su nombre
  String getCategoryId(String categoryName) {
    if (!_categoriesLoaded) {
      return _categoryNameToId[categoryName] ?? '550e8400-e29b-41d4-a716-446655440007';
    }
    return _categoryNameToId[categoryName] ?? '550e8400-e29b-41d4-a716-446655440007';
  }

  /// Obtiene el icono de una categoría
  String? getCategoryIcon(String? categoryId) {
    if (categoryId == null) return null;
    return _categoryIdToIcon[categoryId];
  }

  @override
  Future<List<Map<String, dynamic>>> getCategories({String? type}) async {
    await loadCategories();

    try {
      var query = supabaseClient.from('categories').select('id, name, icon, type');

      if (type != null) {
        query = query.eq('type', type);
      }

      final response = await query.order('name');
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error obteniendo categorías: $e');
      return [];
    }
  }

  bool get isLoaded => _categoriesLoaded;
}
