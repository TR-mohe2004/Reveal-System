import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reveal_app/app/data/providers/auth_provider.dart';

class ProfileScreenNew extends StatelessWidget {
  const ProfileScreenNew({super.key});

  static const Color _teal = Color(0xFF2DBA9D);
  static const Color _deepTeal = Color(0xFF1A9A8A);
  static const Color _orange = Color(0xFFF27E49);
  static const Color _background = Color(0xFFF4F7F9);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final name = (user?.fullName.trim().isNotEmpty ?? false) ? user!.fullName : 'ضيف ريڤيل';
    final email = (user?.email.trim().isNotEmpty ?? false) ? user!.email : 'لم يتم تسجيل بريد إلكتروني';
    final phone = (user?.phoneNumber.trim().isNotEmpty ?? false) ? user!.phoneNumber : 'لم يتم إضافة رقم هاتف';
    const address = 'العنوان غير مضاف بعد';
    final avatarLetter = name.isNotEmpty ? name.characters.first : 'ر';
    final profileImage = user?.profileImage;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              _ProfileHeader(
                name: name,
                email: email,
                avatarLetter: avatarLetter,
                profileImage: profileImage,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 72, 20, 24),
                  child: Column(
                    children: [
                      _InfoCard(
                        icon: Icons.person_outline,
                        label: 'الاسم الكامل',
                        value: name,
                        iconColor: _teal,
                      ),
                      _InfoCard(
                        icon: Icons.phone_rounded,
                        label: 'رقم الهاتف',
                        value: phone,
                        iconColor: _orange,
                      ),
                      _InfoCard(
                        icon: Icons.location_on_outlined,
                        label: 'العنوان',
                        value: address,
                        iconColor: Colors.teal.shade700,
                      ),
                      _InfoCard(
                        icon: Icons.alternate_email_rounded,
                        label: 'البريد الإلكتروني',
                        value: email,
                        iconColor: _deepTeal,
                      ),
                      const SizedBox(height: 12),
                      _NotificationsButton(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.avatarLetter,
    this.profileImage,
  });

  final String name;
  final String email;
  final String avatarLetter;
  final String? profileImage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 190,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [ProfileScreenNew._teal, ProfileScreenNew._deepTeal],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    _HeaderIcon(
                      icon: Icons.settings_outlined,
                      background: Colors.white.withOpacity(0.2),
                    ),
                    const Spacer(),
                    _HeaderIcon(
                      icon: Icons.edit_outlined,
                      background: Colors.white.withOpacity(0.2),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'بطاقة حسابك',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: -50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: ProfileScreenNew._background,
                  backgroundImage: (profileImage != null && profileImage!.isNotEmpty)
                      ? NetworkImage(profileImage!)
                      : null,
                  child: (profileImage == null || profileImage!.isEmpty)
                      ? Text(
                          avatarLetter,
                          style: const TextStyle(
                            color: ProfileScreenNew._teal,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Icon(Icons.chevron_left_rounded, color: Colors.grey.shade400),
      ),
    );
  }
}

class _NotificationsButton extends StatelessWidget {
  const _NotificationsButton({
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.notifications_none_rounded, size: 22),
        label: const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'الإشعارات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 8,
          shadowColor: backgroundColor.withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.background});

  final IconData icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }
}
