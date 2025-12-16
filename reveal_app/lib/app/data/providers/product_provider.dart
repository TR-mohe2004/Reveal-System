import 'package:flutter/material.dart';
import 'package:reveal_app/app/core/enums/view_state.dart';
import 'package:reveal_app/app/data/models/product_model.dart';
import 'package:reveal_app/app/data/services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  static const String allCategoryLabel = 'All';
  final ApiService _apiService = ApiService();
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  List<Product> _allProducts = [];
  String? _selectedCategory;
  String _searchQuery = '';

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  List<Product> get products => filteredProducts;

  List<Product> get filteredProducts {
    Iterable<Product> filtered = _allProducts;
    final isAllCategory = _selectedCategory == null ||
        _selectedCategory == allCategoryLabel ||
        _selectedCategory == 'all';
    if (!isAllCategory) {
      filtered = filtered.where((p) => p.category == _selectedCategory);
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where(
        (p) =>
            p.name.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query) ||
            p.cafeName.toLowerCase().contains(query) ||
            p.collegeName.toLowerCase().contains(query),
      );
    }
    return filtered.toList();
  }

  Future<void> fetchAllProducts() async {
    _errorMessage = null;
    _setState(ViewState.busy);
    try {
      _allProducts = await _apiService.getProducts();
      _setState(ViewState.retrieved);
    } catch (e) {
      _errorMessage = 'Failed to load products: $e';
      _setState(ViewState.error);
    }
  }

  Future<void> toggleFavorite(String productId) async {
    final index = _allProducts.indexWhere(
      (p) => p.id.toString() == productId.toString(),
    );
    if (index != -1) {
      _allProducts[index].isFavorite = !_allProducts[index].isFavorite;
      notifyListeners();
    }
  }

  void filterByCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<String> get availableCategories {
    final categories = _allProducts
        .map((p) => p.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    categories.sort(
      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
    return categories;
  }

  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }
}
