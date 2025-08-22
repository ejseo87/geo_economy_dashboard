import 'package:flutter/material.dart';
import 'package:geo_economy_dashboard/constants/colors.dart';
import 'package:geo_economy_dashboard/constants/gaps.dart';
import 'package:geo_economy_dashboard/constants/typography.dart';

class TrendChartCard extends StatelessWidget {
  const TrendChartCard({
    super.key,
    required this.title,
    required this.value,
    required this.period,
    required this.changePercentage,
    required this.isPositive,
    required this.isDark,
    required this.chartData,
  });

  final String title;
  final String value;
  final String period;
  final String changePercentage;
  final bool isPositive;
  final bool isDark;
  final List<double> chartData;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDark ? const Color(0xFF16213E) : AppColors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDark ? Colors.white60 : AppColors.textSecondary;
    final changeColor = isPositive ? AppColors.accent : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                period,
                style: AppTypography.bodySmall.copyWith(color: subtitleColor),
              ),
            ],
          ),
          Gaps.v8,
          Text(
            value,
            style: AppTypography.heading1.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Gaps.v4,
          Text(
            '$period $changePercentage',
            style: AppTypography.bodyMedium.copyWith(
              color: changeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Gaps.v16,
          SizedBox(height: 80, child: _buildMiniChart()),
          Gaps.v12,
          _buildYearLabels(),
        ],
      ),
    );
  }

  Widget _buildMiniChart() {
    return CustomPaint(
      size: const Size(double.infinity, 80),
      painter: _TrendChartPainter(
        data: chartData,
        isDark: isDark,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildYearLabels() {
    final years = ['2019', '2020', '2021', '2022', '2023'];
    final subtitleColor = isDark ? Colors.white60 : AppColors.textSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: years
          .map(
            (year) => Text(
              year,
              style: AppTypography.bodySmall.copyWith(
                color: subtitleColor,
                fontSize: 10,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> data;
  final bool isDark;
  final Color color;

  _TrendChartPainter({
    required this.data,
    required this.isDark,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = range == 0 ? 0.5 : (data[i] - minValue) / range;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw dots at each data point
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final normalizedValue = range == 0 ? 0.5 : (data[i] - minValue) / range;
      final y = size.height - (normalizedValue * size.height);

      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
