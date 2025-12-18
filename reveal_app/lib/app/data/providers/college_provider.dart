import 'package:flutter/material.dart';
import 'package:reveal_app/app/core/enums/view_state.dart';
import 'package:reveal_app/app/data/models/college_model.dart'; // ✅ المودل الجديد
import 'package:reveal_app/app/data/services/api_service.dart';

class CollegeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CollegeModel> _colleges = []; // ✅ استخدام CollegeModel
  CollegeModel? _selectedCollege;
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  List<CollegeModel> get colleges => _colleges;
  CollegeModel? get selectedCollege => _selectedCollege;
  ViewState get state => _state;
  String? get errorMessage => _errorMessage;

  Future<void> fetchColleges() async {
    _state = ViewState.busy;
    notifyListeners();

    try {
      // ✅ جلب الكليات باستخدام المودل الجديد
      _colleges = await _apiService.getCafes(); 
      _errorMessage = null;
      _state = ViewState.idle;
    } catch (e) {
      _errorMessage = e.toString();
      _state = ViewState.error;
    } finally {
      notifyListeners();
    }
  }

  void selectCollege(CollegeModel? college) {
    _selectedCollege = college;
    notifyListeners();
  }

  void clearSelection() {
    _selectedCollege = null;
    notifyListeners();
  }
}