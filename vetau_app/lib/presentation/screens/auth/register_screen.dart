/// RegisterScreen – Đăng ký tài khoản mới
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../presentation/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmPassFocus = FocusNode();
  
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  bool _touched = false;

  String? get _fullNameErr {
    if (!_touched) return null;
    if (_fullNameCtrl.text.trim().isEmpty) return 'Vui lòng nhập họ và tên';
    return null;
  }

  String? get _emailErr {
    if (!_touched) return null;
    if (_emailCtrl.text.trim().isEmpty) return 'Vui lòng nhập email';
    if (!_emailCtrl.text.contains('@')) return 'Email không hợp lệ';
    return null;
  }

  String? get _passErr {
    if (!_touched) return null;
    if (_passCtrl.text.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (_passCtrl.text.length < 6) return 'Tối thiểu 6 ký tự';
    return null;
  }

  String? get _confirmPassErr {
    if (!_touched) return null;
    if (_confirmPassCtrl.text.isEmpty) return 'Vui lòng xác nhận mật khẩu';
    if (_confirmPassCtrl.text != _passCtrl.text) return 'Mật khẩu không khớp';
    return null;
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _touched = true);
    if (_fullNameErr != null || _emailErr != null || _passErr != null || _confirmPassErr != null) return;

    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      _emailCtrl.text.trim(), 
      _passCtrl.text,
      _fullNameCtrl.text.trim(),
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Đăng ký thành công!'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
      
      // Navigate to home after successful registration
      context.canPop() ? context.pop() : context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Đăng ký thất bại. Vui lòng thử lại.'),
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
                              onPressed: () => context.pop(),
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
                          ],
                        ),

                        const SizedBox(height: 24),
                        const Text('Tạo tài khoản', style: TextStyle(fontSize: 28,
                            fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                        const SizedBox(height: 6),
                        const Text('Tham gia cùng chúng tôi ngay hôm nay!',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                        const SizedBox(height: 32),

                        // Full Name
                        const _Label('Họ và tên'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _fullNameCtrl,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
                          decoration: InputDecoration(
                            hintText: 'Nguyễn Văn A',
                            prefixIcon: const Icon(Icons.person_outline,
                                color: AppTheme.textHint, size: 20),
                            errorText: _fullNameErr,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email
                        const _Label('Email'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailCtrl,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passFocus),
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
                          obscureText: _obscurePass,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_confirmPassFocus),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: AppTheme.textHint, size: 20),
                            errorText: _passErr,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppTheme.textHint, size: 20),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password
                        const _Label('Xác nhận mật khẩu'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _confirmPassCtrl,
                          focusNode: _confirmPassFocus,
                          obscureText: _obscureConfirmPass,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: AppTheme.textHint, size: 20),
                            errorText: _confirmPassErr,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppTheme.textHint, size: 20),
                              onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
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
                                    Icon(Icons.person_add, size: 20),
                                    SizedBox(width: 8),
                                    Text('Đăng ký', style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w700)),
                                  ]),
                        ),
                        
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Đã có tài khoản?', style: TextStyle(color: AppTheme.textSecondary)),
                            TextButton(
                              onPressed: () => context.pop(),
                              child: const Text('Đăng nhập ngay', style: TextStyle(
                                  color: AppTheme.primary, fontWeight: FontWeight.w700)),
                            )
                          ],
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
