import 'package:flutter/material.dart';

import 'package:reveal_app/app/data/models/notification_model.dart';
import 'package:reveal_app/app/data/models/order_model.dart';
import 'package:reveal_app/app/data/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationItem> _items = [];
  bool _isLoading = false;

  List<NotificationItem> get items => _items;
  bool get isLoading => _isLoading;
  int get unreadCount => _items.where((item) => !item.isRead).length;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _items = await _service.loadNotifications();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshFromOrders(List<OrderModel> orders) async {
    _items = await _service.updateFromOrders(orders);
    notifyListeners();
  }

  Future<void> markAllRead() async {
    await _service.markAllRead();
    _items = await _service.loadNotifications();
    notifyListeners();
  }
}
