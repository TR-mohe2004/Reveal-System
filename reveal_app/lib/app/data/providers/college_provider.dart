import 'package:flutter/material.dart';
import 'package:reveal_app/app/core/enums/view_state.dart';
import 'package:reveal_app/app/data/models/college_model.dart';
import 'package:reveal_app/app/data/services/api_service.dart';

class CollegeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<College> _colleges = [];
  College? _selectedCollege;
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  List<College> get colleges => _colleges;
  College? get selectedCollege => _selectedCollege;
  ViewState get state => _state;
  String? get errorMessage => _errorMessage;

  Future<void> fetchColleges() async {
    _state = ViewState.busy;
    notifyListeners();

    try {
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

  void selectCollege(College? college) {
    _selectedCollege = college;
    notifyListeners();
  }

  void clearSelection() {
    _selectedCollege = null;
    notifyListeners();
  }
}
