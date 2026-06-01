import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> with SingleTickerProviderStateMixin {
  bool _isSubmitting = false;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _menuFadeAnimation;
  late final Animation<Offset> _menuSlideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    _menuFadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.15, 0.95, curve: Curves.easeOutCubic),
    );
    _menuSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.15, 0.95, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _changeEmail() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      return;
    }

    final controller = TextEditingController(text: user.email);
    final formKey = GlobalKey<FormState>();

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Email'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Email baru',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email wajib diisi';
                }
                final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch(value.trim());
                if (!isValid) {
                  return 'Format email belum valid';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (approved != true) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthService.instance.updateEmail(controller.text);
      if (!mounted) {
        return;
      }
      _showMessage('Email berhasil diperbarui.');
      setState(() {});
    } on AuthException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ubah Kata Sandi'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: currentController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Kata sandi saat ini',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscureCurrent = !obscureCurrent;
                            });
                          },
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: newController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Kata sandi baru',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Kata sandi minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: confirmController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi kata sandi baru',
                        prefixIcon: const Icon(Icons.lock_clock_outlined),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value != newController.text) {
                          return 'Konfirmasi password tidak sama';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (approved != true) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthService.instance.updatePassword(
        currentPassword: currentController.text,
        newPassword: newController.text,
      );
      if (!mounted) {
        return;
      }
      _showMessage('Kata sandi berhasil diperbarui.');
    } on AuthException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isSubmitting = true;
    });

    await AuthService.instance.signOut();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFE57373) : const Color(0xFF1F8A70);
    final titleColor = isDestructive ? const Color(0xFFD32F2F) : const Color(0xFF1B4D3E);
    final iconBgColor = isDestructive ? const Color(0xFFFFEBEE) : const Color(0xFF1F8A70).withOpacity(0.08);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: titleColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF6B8A80),
          fontSize: 12.5,
          height: 1.3,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF8BA69D),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: const Center(child: Text('Data profil tidak tersedia.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1F8A70), Color(0xFF35A285)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1F8A70).withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.35), width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          child: Text(
                            user.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.username}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          FadeTransition(
            opacity: _menuFadeAnimation,
            child: SlideTransition(
              position: _menuSlideAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1F8A70).withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF1F8A70).withOpacity(0.06),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.email_outlined,
                      title: 'Ubah Email',
                      subtitle: user.email,
                      onTap: _isSubmitting ? null : _changeEmail,
                    ),
                    const Divider(height: 1, indent: 78, endIndent: 16),
                    _buildMenuItem(
                      icon: Icons.lock_reset_outlined,
                      title: 'Ubah Kata Sandi',
                      subtitle: 'Perbarui kata sandi akses akun Anda',
                      onTap: _isSubmitting ? null : _changePassword,
                    ),
                    const Divider(height: 1, indent: 78, endIndent: 16),
                    _buildMenuItem(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      subtitle: 'Keluar dari sesi masuk aplikasi',
                      isDestructive: true,
                      onTap: _isSubmitting ? null : _logout,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
