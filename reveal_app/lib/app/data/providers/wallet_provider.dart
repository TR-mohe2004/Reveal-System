import 'package:flutter/material.dart';
import 'package:reveal_app/app/core/enums/view_state.dart';
import 'package:reveal_app/app/data/models/wallet_model.dart';
import 'package:reveal_app/app/data/services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  WalletModel? _wallet;
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  WalletModel? get wallet => _wallet;
  ViewState get state => _state;
  String? get errorMessage => _errorMessage;

  Future<void> fetchWalletData() async {
    _state = ViewState.busy;
    _errorMessage = null;
    notifyListeners();

    try {
      _wallet = await _apiService.getWallet();
      _state = ViewState.retrieved;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _apiService.removeToken();
        _wallet = null;
        _errorMessage = 'Session expired. Please log in again.';
      } else {
        _errorMessage = e.message;
      }
      _state = ViewState.error;
    } catch (e) {
      _errorMessage = 'Failed to load wallet: $e';
      _state = ViewState.error;
    }

    notifyListeners();
  }

  Future<bool> linkWallet(String code) async {
    _state = ViewState.busy;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.linkWalletWithCode(code);
      if (success) {
        _wallet = await _apiService.getWallet();
        _state = ViewState.retrieved;
      } else {
        _state = ViewState.error;
        _errorMessage = 'Failed to link wallet.';
      }
      return success;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _apiService.removeToken();
        _wallet = null;
        _errorMessage = 'Session expired. Please log in again.';
      } else {
        _errorMessage = e.message;
      }
      _state = ViewState.error;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to link wallet: $e';
      _state = ViewState.error;
      return false;
    } finally {
      notifyListeners();
    }
  }

  void updateLocalBalance(double newBalance) {
    if (_wallet == null) return;
    _wallet = WalletModel(
      id: _wallet!.id,
      balance: newBalance,
      currency: _wallet!.currency,
      college: _wallet!.college,
      linkCode: _wallet!.linkCode,
      userFullName: _wallet!.userFullName,
      transactions: _wallet!.transactions,
    );
    notifyListeners();
  }

  Future<bool> transferToWallet({
    required String walletCode,
    required double amount,
    String? note,
  }) async {
    _state = ViewState.busy;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.transferWallet(
        walletCode: walletCode,
        amount: amount,
        note: note,
      );

      if (success) {
        _wallet = await _apiService.getWallet();
        _state = ViewState.retrieved;
        notifyListeners();
        return true;
      }

      _state = ViewState.error;
      _errorMessage = 'فشل التحويل.';
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _apiService.removeToken();
        _wallet = null;
        _errorMessage = 'Session expired. Please log in again.';
      } else {
        _errorMessage = e.message;
      }
      _state = ViewState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'فشل التحويل: $e';
      _state = ViewState.error;
      notifyListeners();
      return false;
    }
  }
}
