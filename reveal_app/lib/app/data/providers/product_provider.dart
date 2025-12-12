import 'package:flutter/material.dart';
import 'package:reveal_app/app/core/enums/view_state.dart';
import 'package:reveal_app/app/data/models/college_model.dart';
import 'package:reveal_app/app/data/models/product_model.dart';
import 'package:reveal_app/app/data/services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  ViewState _state = ViewState.idle;
  String? _errorMessage;

  final List<College> _colleges = [];
  List<Product> _allProducts = [];
  String? _selectedCategory;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  List<College> get colleges => _colleges;
  String? get selectedCategory => _selectedCategory;

  // Unified getter used by UI code (returns filtered results)
  List<Product> get products => filteredProducts;

  List<Product> get filteredProducts {
    if (_selectedCategory == null || _selectedCategory == 'الكل') return _allProducts;
    return _allProducts.where((p) => p.category == _selectedCategory).toList();
  }

  // Placeholder: colleges can be fetched via CollegeProvider when needed
  Future<void> fetchColleges() async {
    // Implement if this provider needs to own college fetching
  }

  Future<void> fetchAllProducts() async {
    _setState(ViewState.busy);
    try {
      _allProducts = await _apiService.getProducts();
      _setState(ViewState.idle);
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء جلب المنتجات: $e';
      _setState(ViewState.error);
    }
  }

  void filterByCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }
}
