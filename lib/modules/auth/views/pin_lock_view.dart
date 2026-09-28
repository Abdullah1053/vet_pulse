import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../routes/app_routes.dart';
import '../controllers/auth_controller.dart';

class PinLockView extends StatefulWidget {
  const PinLockView({super.key});

  @override
  State<PinLockView> createState() => _PinLockViewState();
}

class _PinLockViewState extends State<PinLockView> {
  final AuthController controller = Get.find<AuthController>();
  String currentPin = '';

  void _onKeyPress(String digit) {
    if (currentPin.length < 4) {
      setState(() {
        currentPin += digit;
      });
      if (currentPin.length == 4) {
        controller.unlockWithPin(currentPin);
        setState(() {
          currentPin = '';
        });
      }
    }
  }

  void _onBackspace() {
    if (currentPin.isNotEmpty) {
      setState(() {
        currentPin = currentPin.substring(0, currentPin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_clock, size: 32, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStringsAr.quickUnlock,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNeutral,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'أدخل رمز PIN السريع (الافتراضي: 1234)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  // PIN indicators (dots)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < currentPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? AppColors.primary : AppColors.border,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 40),

                  // Keypad 1-9, 0, Backspace
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 3,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      for (var i = 1; i <= 9; i++) _buildKey('$i'),
                      TextButton(
                        onPressed: () => Get.offAllNamed(AppRoutes.login),
                        child: const Text('دخول كامل', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ),
                      _buildKey('0'),
                      IconButton(
                        onPressed: _onBackspace,
                        icon: const Icon(Icons.backspace_outlined, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKey(String label) {
    return InkWell(
      onTap: () => _onKeyPress(label),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.darkNeutral,
          ),
        ),
      ),
    );
  }
}
