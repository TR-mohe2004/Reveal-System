import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:reveal_app/app/data/providers/wallet_provider.dart';

class WalletTransferScreen extends StatefulWidget {
  const WalletTransferScreen({super.key});

  @override
  State<WalletTransferScreen> createState() => _WalletTransferScreenState();
}

class _WalletTransferScreenState extends State<WalletTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _walletCodeController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _walletCodeController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final walletCode = _walletCodeController.text.trim();
    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ?? 0.0;
    final note = _noteController.text.trim();

    setState(() => _isSubmitting = true);
    final provider = context.read<WalletProvider>();
    final success = await provider.transferToWallet(
      walletCode: walletCode,
      amount: amount,
      note: note.isEmpty ? null : note,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحويل المبلغ بنجاح')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'تعذر إتمام التحويل')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحويل الأموال'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'أدخل بيانات المحفظة المستلمة والمبلغ المراد تحويله.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _walletCodeController,
                decoration: const InputDecoration(
                  labelText: 'رقم المحفظة أو كود الربط',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء إدخال رقم المحفظة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'المبلغ (د.ل)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) {
                    return 'أدخل مبلغاً صحيحاً';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة (اختياري)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('تأكيد التحويل'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
