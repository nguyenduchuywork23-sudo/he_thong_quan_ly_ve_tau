/// LoginScreen – Đăng nhập & phân quyền
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passFocus = FocusNode();
  bool _obscure = true;
  bool _touched = false;

  String? get _emailErr {
    if (!_touched) return null;
    if (_emailCtrl.text.trim().isEmpty) return 'Vui lòng nhập email';
    return null;
  }

  String? get _passErr {
    if (!_touched) return null;
    if (_passCtrl.text.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (_passCtrl.text.length < 6) return 'Tối thiểu 6 ký tự';
    return null;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _touched = true);
    if (_emailErr != null || _passErr != null) return;

    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text);

    if (!mounted) return;
    if (ok) {
      final role = auth.user?.role ?? 'customer';
      if (role == 'admin') {
        context.go('/admin');
      } else if (role == 'staff') {
        context.go('/staff');
      } else {
        context.canPop() ? context.pop() : context.go('/');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Email hoặc mật khẩu không đúng'),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(children: [
        Container(decoration: const BoxDecoration(gradient: AppTheme.heroGradient)),
        Positioned(top: -60, right: -60,
          child: Container(width: 200, height: 200,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.08)))),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Consumer<AuthProvider>(
              builder: (_, auth, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  IconButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                    icon: const Icon(Icons.arrow_back_ios,
                        color: AppTheme.textSecondary, size: 20),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 28),

                  // Logo
                  Row(children: [
                    Container(width: 46, height: 46,
                      decoration: BoxDecoration(color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(13)),
                      child: const Icon(Icons.train, color: Colors.white, size: 24)),
                    const SizedBox(width: 10),
                    RichText(text: const TextSpan(children: [
                      TextSpan(text: 'Vé', style: TextStyle(fontSize: 24,
                          fontWeight: FontWeight.w900, color: AppTheme.primary)),
                      TextSpan(text: 'Tàu', style: TextStyle(fontSize: 24,
                          fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                    ])),
                  ]),

                  const SizedBox(height: 32),
                  const Text('Đăng nhập', style: TextStyle(fontSize: 28,
                      fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                  const SizedBox(height: 6),
                  const Text('Chào mừng bạn trở lại!',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 32),

                  // Email
                  const _Label('Email'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    onChanged: (_) => setState(() {}),
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_passFocus),
                    decoration: InputDecoration(
                      hintText: 'example@email.com',
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: AppTheme.textHint, size: 20),
                      errorText: _emailErr,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Password
                  const _Label('Mật khẩu'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passCtrl,
                    focusNode: _passFocus,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    onChanged: (_) => setState(() {}),
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AppTheme.textHint, size: 20),
                      errorText: _passErr,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textHint, size: 20),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit button
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                      boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35),
                          blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login, size: 20),
                                SizedBox(width: 8),
                                Text('Đăng nhập', style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700)),
                              ]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Chưa có tài khoản?', style: TextStyle(color: AppTheme.textSecondary)),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: const Text('Đăng ký ngay', style: TextStyle(
                            color: AppTheme.primary, fontWeight: FontWeight.w700)),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Demo accounts info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.info.withOpacity(0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.info_outline, color: AppTheme.info, size: 15),
                          SizedBox(width: 6),
                          Text('Tài khoản thử nghiệm', style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: AppTheme.info)),
                        ]),
                        const SizedBox(height: 8),
                        _DemoRow('Khách hàng:', 'customer@vetau.vn / 123456'),
                        _DemoRow('Admin:', 'admin@vetau.vn / admin123'),
                        _DemoRow('Nhân viên:', 'staff@vetau.vn / staff123'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary));
}

class _DemoRow extends StatelessWidget {
  final String label, value;
  const _DemoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(children: [
      SizedBox(width: 76, child: Text(label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textHint))),
      Expanded(child: Text(value, style: const TextStyle(
          fontSize: 11, color: AppTheme.textSecondary,
          fontWeight: FontWeight.w600))),
    ]),
  );
}
