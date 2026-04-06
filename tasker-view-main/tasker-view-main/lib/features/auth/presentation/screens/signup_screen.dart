import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/auth_service.dart';
import 'otp_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _acceptedTerms = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      _showSnackBar('Por favor llena todos los campos');
      return;
    }

    if (!_acceptedTerms) {
      _showSnackBar('Debes aceptar los términos y condiciones');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => OTPVerificationScreen(
            email: email,
            type: OtpType.signup,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTypography.bodySM.copyWith(color: Colors.white)),
        backgroundColor: AppColors.onSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Aesthetic Decorative Element
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24.0, right: 32.0, top: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Back Button (Minimalist)
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.onSurface),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  // App Icon / Decorative Header
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.business_center_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  // Header Section (Editorial Layout)
                  Text(
                    'Crear Cuenta',
                    style: AppTypography.displayMD.copyWith(
                      color: AppColors.onSurface,
                      height: 1.1,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Únete a nuestra comunidad de profesionales hoy mismo.',
                    style: AppTypography.bodyLG.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Form Fields in Architectural Layers
                  _buildInputField(
                    label: 'Nombre completo',
                    controller: _nameController,
                    hint: 'Juan Pérez',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 24),
                  
                  _buildInputField(
                    label: 'Correo electrónico',
                    controller: _emailController,
                    hint: 'ejemplo@correo.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  
                  _buildInputField(
                    label: 'Teléfono de contacto',
                    controller: _phoneController,
                    hint: '+593 99 999 9999',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  
                  _buildInputField(
                    label: 'Contraseña',
                    controller: _passwordController,
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Terms & Conditions (Soft Modern Checkbox)
                  GestureDetector(
                    onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _acceptedTerms ? AppColors.primary : AppColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: _acceptedTerms 
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: AppTypography.bodySM,
                              children: [
                                const TextSpan(text: 'Acepto los '),
                                TextSpan(
                                  text: 'términos y condiciones',
                                  style: AppTypography.bodySM.copyWith(color: AppColors.primary),
                                ),
                                const TextSpan(text: ' de ServiTask.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Primary CTA (Gradient Button)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading 
                          ? const SizedBox(
                              width: 24, 
                              height: 24, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Registrarme ahora',
                              style: AppTypography.labelLG.copyWith(color: Colors.white),
                            ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  // Footer link
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: RichText(
                        text: TextSpan(
                          style: AppTypography.bodyMD,
                          children: [
                            const TextSpan(text: '¿Ya tienes una cuenta? '),
                            TextSpan(
                              text: 'Inicia sesión',
                              style: AppTypography.labelMD.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
          
          // Loading Overlay (Glassmorphism)
          if (_isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.1),
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMD.copyWith(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword && _obscurePassword,
            style: AppTypography.bodyLG.copyWith(color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.bodyLG.copyWith(color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
              prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
              suffixIcon: isPassword 
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.onSurfaceVariant,
                      size: 22,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}




