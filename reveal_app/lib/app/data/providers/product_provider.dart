import 'package:flutter/material.dart';
import 'package:reveal_app/app/core/enums/view_state.dart';
import 'package:reveal_app/app/data/models/college_model.dart';
import 'package:reveal_app/app/data/models/product_model.dart';
import 'package:reveal_app/app/data/services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // الحالة الأولية (Idle)
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  List<College> _colleges = [];
  List<Product> _allProducts = [];
  String? _selectedCategory;

  // Getters
  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  List<College> get colleges => _colleges;
  String? get selectedCategory => _selectedCategory;

  // A unified products getter used by UI code (returns filtered results)
  List<Product> get products => filteredProducts;

  // تصفية المنتجات حسب الفئة المختارة
  List<Product> get filteredProducts {
    if (_selectedCategory == null || _selectedCategory == 'الكل') return _allProducts;
    return _allProducts.where((p) => p.category == _selectedCategory).toList();
  }

  // 1. جلب الكليات (تم نقله إلى CollegeProvider)
  Future<void> fetchColleges() async {
    // هذه الدالة متروكة فارغة عمدًا لأننا نستخدم CollegeProvider
  }

  // 2. جلب جميع المنتجات (REST API)
  Future<void> fetchAllProducts() async {
    _setState(ViewState.busy);
    try {
      _allProducts = await _apiService.getProducts();
      _setState(ViewState.idle);
    } catch (e) {
      _errorMessage = "خطأ في جلب المنتجات: $e";
      _setState(ViewState.error);
    }
  }

  // التحكم بالفلتر
  void filterByCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }
}