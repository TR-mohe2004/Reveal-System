import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:reveal_app/app/data/models/notification_model.dart';
import 'package:reveal_app/app/data/models/order_model.dart';

class NotificationService {
  static const String _notificationsKey = 'local_notifications';
  static const String _statusCacheKey = 'order_status_cache';
  static const int _maxNotifications = 50;

  Future<List<NotificationItem>> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notificationsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
      return decoded.map((item) => NotificationItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveNotifications(List<NotificationItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = items.take(_maxNotifications).toList();
    final encoded = json.encode(trimmed.map((item) => item.toJson()).toList());
    await prefs.setString(_notificationsKey, encoded);
  }

  Future<void> markAllRead() async {
    final items = await loadNotifications();
    final updated = items.map((item) => item.copyWith(isRead: true)).toList();
    await saveNotifications(updated);
  }

  Future<int> getUnreadCount() async {
    final items = await loadNotifications();
    return items.where((item) => !item.isRead).length;
  }

  Future<List<NotificationItem>> updateFromOrders(List<OrderModel> orders) async {
    final statusCache = await _loadStatusCache();
    final items = await loadNotifications();

    for (final order in orders) {
      final key = order.id.toString();
      final status = order.status.toUpperCase();
      final prev = statusCache[key];

      if (prev == null) {
        statusCache[key] = status;
        continue;
      }

      if (prev != status) {
        final notification = _buildNotification(order, status);
        if (notification != null) {
          items.insert(0, notification);
        }
        statusCache[key] = status;
      }
    }

    await saveNotifications(items);
    await _saveStatusCache(statusCache);
    return items;
  }

  NotificationItem? _buildNotification(OrderModel order, String status) {
    final orderNumber = order.orderNumber.isNotEmpty ? order.orderNumber : order.id.toString();
    switch (status) {
      case 'ACCEPTED':
        return NotificationItem(
          id: '${order.id}-accepted-${DateTime.now().millisecondsSinceEpoch}',
          orderId: order.id,
          status: status,
          title: 'تم قبول طلبك بنجاح',
          body: 'تم قبول طلبك #$orderNumber بنجاح.',
          createdAt: DateTime.now().toIso8601String(),
        );
      case 'PREPARING':
        return NotificationItem(
          id: '${order.id}-preparing-${DateTime.now().millisecondsSinceEpoch}',
          orderId: order.id,
          status: status,
          title: 'طلبك قيد التحضير',
          body: 'طلبك #$orderNumber قيد التحضير.',
          createdAt: DateTime.now().toIso8601String(),
        );
      case 'READY':
        return NotificationItem(
          id: '${order.id}-ready-${DateTime.now().millisecondsSinceEpoch}',
          orderId: order.id,
          status: status,
          title: 'طلبك جاهز للاستلام',
          body: 'طلبك #$orderNumber جاهز للاستلام.',
          createdAt: DateTime.now().toIso8601String(),
        );
      default:
        return null;
    }
  }

  Future<Map<String, String>> _loadStatusCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statusCacheKey);
    if (raw == null || raw.isEmpty) {
      return {};
    }
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveStatusCache(Map<String, String> cache) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statusCacheKey, json.encode(cache));
  }
}
