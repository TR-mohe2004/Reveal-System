import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي')),
      body: const Center(child: Text('سجل الطلبات فارغ', style: TextStyle(fontSize: 20))),
    );
  }
}
