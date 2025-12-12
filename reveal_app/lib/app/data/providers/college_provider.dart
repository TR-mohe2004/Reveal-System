import 'package:flutter/material.dart';
import 'package:reveal_app/app/data/models/college_model.dart';
import 'package:reveal_app/app/data/services/api_service.dart';

enum CollegeState { initial, loading, loaded, error }

class CollegeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<College> _availableColleges = [];
  College? _selectedCollege; // Can be null initially
  CollegeState _state = CollegeState.initial;
  String _errorMessage = '';

  CollegeProvider() {
    fetchColleges();
  }

  // Getters
  List<College> get availableColleges => _availableColleges;
  College? get selectedCollege => _selectedCollege;
  CollegeState get state => _state;
  String get errorMessage => _errorMessage;

  // Fetch colleges from the API
  Future<void> fetchColleges() async {
    _state = CollegeState.loading;
    notifyListeners();
    try {
      _availableColleges = await _apiService.getCafes();
      if (_availableColleges.isNotEmpty) {
        _selectedCollege = _availableColleges.first;
        _state = CollegeState.loaded;
      } else {
        _state = CollegeState.error;
        _errorMessage = 'No colleges found.';
      }
    } catch (e) {
      _state = CollegeState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  // Setter for selecting a college
  void selectCollege(College newCollege) {
    if (_selectedCollege?.id != newCollege.id) {
      _selectedCollege = newCollege;
      notifyListeners();
    }
  }
}
