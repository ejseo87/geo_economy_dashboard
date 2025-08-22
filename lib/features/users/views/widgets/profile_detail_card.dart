import 'package:geo_economy_dashboard/constants/gaps.dart';
import 'package:geo_economy_dashboard/constants/colors.dart';
import 'package:geo_economy_dashboard/constants/typography.dart';
import 'package:geo_economy_dashboard/common/widgets/app_card.dart';
import 'package:flutter/material.dart';

class ProfileDetailCard extends StatelessWidget {
  final String numberString;
  final String numberLabel;
  const ProfileDetailCard({
    super.key,
    required this.numberString,
    required this.numberLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Text(
            numberString,
            style: AppTypography.heading3.copyWith(
              color: AppColors.primary,
            ),
          ),
          Gaps.v3,
          Text(
            numberLabel,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}
