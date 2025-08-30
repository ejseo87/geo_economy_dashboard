import 'package:geo_economy_dashboard/constants/colors.dart';
import 'package:geo_economy_dashboard/constants/typography.dart';
import 'package:geo_economy_dashboard/features/settings/view_models/settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class NavTab extends ConsumerWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const NavTab({
    required this.icon,
    required this.selectedIcon,
    required this.text,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(settingsProvider).darkmode;
    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? Colors.white38 : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: AppTypography.bodySmall.copyWith(
                  color: isSelected ? activeColor : inactiveColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
