import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:reveal_app/app/data/services/api_service.dart';
import 'package:reveal_app/app/data/providers/notification_provider.dart';
import 'package:reveal_app/app/data/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await initializeDateFormatting('ar');
      } catch (_) {
        // ignore locale init errors
      }
      final provider = context.read<NotificationProvider>();
      await provider.load();

      try {
        final api = ApiService();
        final orders = await api.getOrders();
        await provider.refreshFromOrders(orders);
      } catch (_) {
        // ignore refresh errors
      }

      await provider.markAllRead();
    });
  }

  IconData _iconForStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        return Icons.check_circle_outline;
      case 'PREPARING':
        return Icons.local_fire_department_outlined;
      case 'READY':
        return Icons.notifications_active_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color _colorForStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        return Colors.blue;
      case 'PREPARING':
        return Colors.orange;
      case 'READY':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(String value) {
    try {
      final date = DateTime.parse(value);
      return intl.DateFormat('d MMM, hh:mm a', 'ar').format(date);
    } catch (_) {
      return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        centerTitle: true,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = provider.items;
          if (items.isEmpty) {
            return _buildEmpty();
          }

          return RefreshIndicator(
            onRefresh: provider.load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final color = _colorForStatus(item.status);
                return _buildCard(item, color);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(NotificationItem item, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: item.isRead ? Colors.white : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(_iconForStatus(item.status), color: color),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.body),
            const SizedBox(height: 6),
            Text(
              _formatTime(item.createdAt),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'لا توجد إشعارات حالياً',
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('سيتم عرض إشعارات الطلبات هنا قريباً.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
