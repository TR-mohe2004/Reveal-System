import 'package:flutter/material.dart';
import 'package:reveal_app/app/core/enums/view_state.dart';
import 'package:reveal_app/app/data/models/wallet_model.dart';
import 'package:reveal_app/app/data/services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Wallet? _wallet;
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  Wallet? get wallet => _wallet;
  ViewState get state => _state;
  String? get errorMessage => _errorMessage;

  WalletProvider() {
    fetchUserWallet();
  }

  Future<void> fetchUserWallet() async {
    _state = ViewState.busy;
    notifyListeners();
    try {
      _wallet = await _apiService.getWallet();
      _state = ViewState.idle;
    } catch (e) {
      _errorMessage = "فشل جلب المحفظة";
      _state = ViewState.error;
    }
    notifyListeners();
  }
}
