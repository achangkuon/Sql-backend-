import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/auth_service.dart';
import '../../../dashboard/presentation/screens/main_dashboard_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final OtpType type;

  const OTPVerificationScreen({
    super.key,
    required this.email,
    this.type = OtpType.signup,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    final code = _otpController.text.trim();

    if (code.isEmpty || code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el código de 6 dígitos.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.verifyOTP(
        email: widget.email,
        token: code,
        type: widget.type,
      );

      if (!mounted) return;

      if (response.user != null) {
        // Verification success
        final isComplete = await _authService.isProfileComplete(response.user!.id);
        
        if (!mounted) return;

        if (isComplete) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainDashboardScreen()),
            (route) => false,
          );
        } else {
          // If profile is not complete, we might want to send them to a completion screen
          // For now, if they come from SignUp, the trigger in SQL should have created the profile.
          // We'll proceed to dash for now, but in a real app, this is where "Setup Profile" happens.
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainDashboardScreen()),
            (route) => false,
          );
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código inválido: ${e.message}'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isResending = true);
    try {
      await _authService.resendOTP(email: widget.email, type: widget.type);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código reenviado con éxito.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Decorative Circle
          Positioned(
            top: -150,
            right: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              // Asymmetric editorial margins: 24px left, 32px right
              padding: const EdgeInsets.only(left: 24.0, right: 32.0, top: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  
                  Text(
                    'Verifica\ntu cuenta',
                    style: AppTypography.displayMD.copyWith(
                      color: AppColors.onSurface,
                      height: 1.1,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ingresa el código que enviamos a tu correo electrónico para confirmar tu cuenta.',
                    style: AppTypography.bodyLG.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // OTP Input Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.onSurface.withValues(alpha: 0.04),
                          blurRadius: 40,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Código de 6 dígitos',
                          style: AppTypography.labelMD.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: AppTypography.displayMD.copyWith(
                            letterSpacing: 12,
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
                            hintText: '000000',
                            hintStyle: AppTypography.displayMD.copyWith(
                              letterSpacing: 12,
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
                            ),
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Verify Button (Premium Gradient)
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Confirmar y entrar', style: AppTypography.labelLG.copyWith(color: Colors.white)),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Resend Option
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '¿No recibiste el código?', 
                          style: AppTypography.bodyMD.copyWith(color: AppColors.onSurfaceVariant)
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isResending ? null : _resendCode,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isResending 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(
                                'Reenviar código ahora',
                                style: AppTypography.labelMD.copyWith(color: AppColors.primary),
                              ),
                        ),
                      ],
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
                filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
}



