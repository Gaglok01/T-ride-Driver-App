import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:t_rider_services_app/consts/appConst.dart';
import 'package:t_rider_services_app/data/repositories/auth_repository.dart';
import 'package:t_rider_services_app/views/splash/auth_screens/login_screen.dart';
import 'package:t_rider_services_app/views/widgets/app_snackbar.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String role;

  const ProfileSetupScreen({super.key, required this.role});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthRepository _authRepository = AuthRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    final password = _passwordController.text.trim();
    return _nameController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        password.length >= 8 &&
        password == _confirmPasswordController.text.trim();
  }

  Future<void> _submitProfile() async {
    if (!_isFormValid || _isLoading) return;

    final args = Get.arguments as Map<String, dynamic>? ?? {};
    final identifier = args['identifier'] as String? ?? '';
    final languageId = (args['language_id'] as int?) ?? 1;

    if (identifier.isEmpty) {
      AppSnackbar.showError(message: 'Missing registration identifier.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _authRepository.register(
        identifier: identifier,
        name: _nameController.text.trim(),
        password: _passwordController.text.trim(),
        role: 'driver',
        languageId: languageId,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        AppSnackbar.showSuccess(
          message: 'Driver account created successfully. Please login.',
        );
        Get.offAll(() => const LoginScreen());
      } else {
        AppSnackbar.showError(
          message: 'Registration failed. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.showApiError(e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _input({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppConst.black,
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFFFF6DD),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14.w,
              vertical: 16.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoChip(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: AppConst.primaryColor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: AppConst.black),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(
              color: AppConst.black,
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 28.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              SizedBox(height: 8.h),
              Text(
                'Create driver profile',
                style: TextStyle(
                  color: AppConst.black,
                  fontSize: 30.sp,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Tell us who you are. Your account will be created as a T-Ride driver.',
                style: TextStyle(
                  color: AppConst.grey,
                  fontSize: 14.sp,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _infoChip('Driver account', Icons.drive_eta_rounded),
                  _infoChip('OTP verified', Icons.verified_rounded),
                ],
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  color: AppConst.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppConst.black.withOpacity(0.07),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _input(
                      label: 'Full name',
                      hint: 'Enter your legal full name',
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                    ),
                    SizedBox(height: 16.h),
                    _input(
                      label: 'Address',
                      hint: 'Street address',
                      controller: _addressController,
                      keyboardType: TextInputType.streetAddress,
                    ),
                    SizedBox(height: 16.h),
                    _input(
                      label: 'City',
                      hint: 'Enter your city',
                      controller: _cityController,
                    ),
                    SizedBox(height: 16.h),
                    _input(
                      label: 'Password',
                      hint: 'Minimum 8 characters',
                      controller: _passwordController,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _input(
                      label: 'Confirm password',
                      hint: 'Re-enter password',
                      controller: _confirmPasswordController,
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: _obscureConfirm,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                      ),
                    ),
                    SizedBox(height: 22.h),
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: _isFormValid && !_isLoading
                            ? _submitProfile
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConst.black,
                          disabledBackgroundColor: AppConst.black.withOpacity(
                            0.35,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.r),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppConst.white,
                                ),
                              )
                            : Text(
                                'Create driver account',
                                style: TextStyle(
                                  color: AppConst.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                'Vehicle details, documents, background check, and payout setup will be completed after account creation.',
                style: TextStyle(
                  color: AppConst.grey,
                  fontSize: 12.sp,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
