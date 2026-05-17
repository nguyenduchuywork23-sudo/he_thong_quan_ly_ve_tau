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
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXL),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    boxShadow: AppTheme.softShadow,
                    border: Border.all(color: AppTheme.cardBorder, width: 0.5),
                  ),
                  child: Consumer<AuthProvider>(
                    builder: (_, auth, __) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () =>
                                  context.canPop() ? context.pop() : context.go('/'),
                              icon: const Icon(Icons.arrow_back_ios,
                                  color: AppTheme.textSecondary, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const Spacer(),
                            // Logo
                            Container(width: 40, height: 40,
                              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.train, color: AppTheme.primary, size: 22)),
                            const SizedBox(width: 8),
                            RichText(text: const TextSpan(children: [
                              TextSpan(text: 'Vé', style: TextStyle(fontSize: 20,
                                  fontWeight: FontWeight.w900, color: AppTheme.primary)),
                              TextSpan(text: 'Tàu', style: TextStyle(fontSize: 20,
                                  fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                            ])),
                          ],
                        ),

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
                        const SizedBox(height: 16),

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
                        const SizedBox(height: 32),

                        // Submit button
                        ElevatedButton(
                          onPressed: auth.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                            ),
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
                        const SizedBox(height: 16),

                        // Demo accounts info
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(children: [
                                Icon(Icons.info_outline, color: AppTheme.info, size: 16),
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
                      ],
                    ),
                  ),
                ),
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
