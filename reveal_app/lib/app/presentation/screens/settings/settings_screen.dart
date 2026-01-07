import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/data/models/user_model.dart';
import 'package:reveal_app/app/data/providers/theme_provider.dart';
import 'package:reveal_app/app/data/services/api_service.dart';
import 'package:reveal_app/app/presentation/screens/support/support_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _secondaryPhoneController = TextEditingController();
  bool _isSaving = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _apiService.getUserProfile();
      if (!mounted) return;
      setState(() {
        _user = user;
        _secondaryPhoneController.text = user.secondaryPhone ?? '';
      });
    } catch (_) {
      // ignore loading errors
    }
  }

  Future<void> _saveSecondaryPhone() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final phone = _secondaryPhoneController.text.trim();
      await _apiService.updateSecondaryPhone(phone);
      await _loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الرقم الإضافي بنجاح')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _secondaryPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('الوضع الليلي / الداكن'),
              value: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.setDarkMode(value),
              secondary: const Icon(Icons.dark_mode_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'رقم إضافي لتسجيل الدخول',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _secondaryPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'أدخل رقم الهاتف الإضافي',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSecondaryPhone,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('حفظ'),
                    ),
                  ),
                  if (_user != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'الحساب الحالي: ${_user!.email}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'يمكنك استخدام هذا الرقم لتسجيل الدخول لنفس الحساب.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('المساعدة والدعم'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupportScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
