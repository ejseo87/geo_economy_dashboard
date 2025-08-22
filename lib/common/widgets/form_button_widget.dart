import 'package:geo_economy_dashboard/constants/sizes.dart';
import 'package:geo_economy_dashboard/constants/colors.dart';
import 'package:geo_economy_dashboard/constants/typography.dart';
import 'package:flutter/material.dart';

class FormButtonWidget extends StatelessWidget {
  final bool isValid;
  final String text;
  final ButtonType type;
  final VoidCallback? onPressed;

  const FormButtonWidget({
    super.key,
    required this.isValid,
    required this.text,
    this.type = ButtonType.primary,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: MediaQuery.of(context).size.width * 0.7,
      height: Sizes.size52,
      duration: Duration(milliseconds: 300),
      child: ElevatedButton(
        onPressed: isValid ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(),
          foregroundColor: _getTextColor(),
          side: type == ButtonType.secondary
              ? null
              : BorderSide(color: AppColors.primary, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          disabledBackgroundColor: AppColors.background,
          disabledForegroundColor: AppColors.textSecondary,
        ),
        child: Text(
          text,
          style: AppTypography.button.copyWith(color: _getTextColor()),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (!isValid) return AppColors.background;

    switch (type) {
      case ButtonType.primary:
        return AppColors.primary;
      case ButtonType.secondary:
        return AppColors.white;
    }
  }

  Color _getTextColor() {
    if (!isValid) return AppColors.textSecondary;

    switch (type) {
      case ButtonType.primary:
        return AppColors.white;
      case ButtonType.secondary:
        return AppColors.primary;
    }
  }
}

enum ButtonType { primary, secondary }
