import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../models/sparkline_data.dart';

/// 스파크라인 차트 위젯
class SparklineChart extends StatelessWidget {
  final SparklineData data;
  final double width;
  final double height;
  final bool showMetadata;
  final VoidCallback? onTap;

  const SparklineChart({
    super.key,
    required this.data,
    this.width = 120,
    this.height = 40,
    this.showMetadata = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: showMetadata ? height + 60 : height,
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showMetadata) _buildMetadata(),
            Expanded(
              child: CustomPaint(
                size: Size(width - 8, height),
                painter: SparklinePainter(data),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata() {
    final isPositive = data.changePercentage != null && data.changePercentage! > 0;
    final trendColor = _getTrendColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (data.trend != SparklineTrend.stable) ...[
                Icon(
                  _getTrendIcon(),
                  size: 12,
                  color: trendColor,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  data.indicatorName,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                data.latestPoint?.value.toStringAsFixed(1) ?? '--',
                style: AppTypography.bodySmall.copyWith(
                  color: trendColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                data.unit,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              if (data.changePercentage != null) ...[
                Text(
                  '${isPositive ? '+' : ''}${data.changePercentage!.toStringAsFixed(1)}%',
                  style: AppTypography.bodySmall.copyWith(
                    color: trendColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getTrendColor() {
    switch (data.trend) {
      case SparklineTrend.rising:
        return AppColors.accent; // 상승 트렌드
      case SparklineTrend.falling:
        return AppColors.error; // 하락 트렌드
      case SparklineTrend.volatile:
        return AppColors.warning; // 변동성 높음
      case SparklineTrend.stable:
        return AppColors.primary; // 안정적
    }
  }

  IconData _getTrendIcon() {
    switch (data.trend) {
      case SparklineTrend.rising:
        return Icons.trending_up;
      case SparklineTrend.falling:
        return Icons.trending_down;
      case SparklineTrend.volatile:
        return Icons.timeline;
      case SparklineTrend.stable:
        return Icons.trending_flat;
    }
  }
}

/// 스파크라인 차트 페인터
class SparklinePainter extends CustomPainter {
  final SparklineData data;

  SparklinePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.points.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..style = PaintingStyle.fill;

    // 데이터 정규화
    final minValue = data.minValue;
    final maxValue = data.maxValue;
    final valueRange = maxValue - minValue;
    
    if (valueRange == 0) {
      // 모든 값이 같은 경우 중앙에 수평선 그리기
      paint.color = _getTrendColor().withValues(alpha: 0.7);
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
      return;
    }

    // 점들을 화면 좌표로 변환
    final points = <Offset>[];
    for (int i = 0; i < data.points.length; i++) {
      final point = data.points[i];
      final x = (i / math.max(1, data.points.length - 1)) * size.width;
      final y = size.height - ((point.value - minValue) / valueRange) * size.height;
      points.add(Offset(x, y));
    }

    // 선 그리기
    paint.color = _getTrendColor().withValues(alpha: 0.8);
    
    for (int i = 0; i < points.length - 1; i++) {
      // 추정값인 경우 점선으로 그리기
      if (data.points[i + 1].isEstimated) {
        _drawDashedLine(canvas, points[i], points[i + 1], paint);
      } else {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }

    // 점 그리기
    dotPaint.color = _getTrendColor();
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final isLatest = i == points.length - 1;
      final isEstimated = data.points[i].isEstimated;
      
      if (isLatest) {
        // 최신 점은 크게
        canvas.drawCircle(point, 3, dotPaint);
        // 테두리 추가
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawCircle(point, 3, borderPaint);
      } else if (isEstimated) {
        // 추정값은 빈 원
        final estimatedPaint = Paint()
          ..color = _getTrendColor()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawCircle(point, 1.5, estimatedPaint);
      } else {
        // 일반 점
        canvas.drawCircle(point, 1.5, dotPaint);
      }
    }

    // 배경 그라데이션 (옵션)
    if (data.trend != SparklineTrend.stable) {
      _drawBackgroundGradient(canvas, size, points);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 3.0;
    const dashSpace = 2.0;
    
    final distance = (end - start).distance;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();
    
    for (int i = 0; i < dashCount; i++) {
      final startT = (i * (dashWidth + dashSpace)) / distance;
      final endT = ((i * (dashWidth + dashSpace)) + dashWidth) / distance;
      
      canvas.drawLine(
        Offset.lerp(start, end, startT)!,
        Offset.lerp(start, end, endT)!,
        paint,
      );
    }
  }

  void _drawBackgroundGradient(Canvas canvas, Size size, List<Offset> points) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points.first.dx, size.height);
    
    for (final point in points) {
      path.lineTo(point.dx, point.dy);
    }
    
    path.lineTo(points.last.dx, size.height);
    path.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _getTrendColor().withValues(alpha: 0.1),
        _getTrendColor().withValues(alpha: 0.02),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, paint);
  }

  Color _getTrendColor() {
    switch (data.trend) {
      case SparklineTrend.rising:
        return AppColors.accent;
      case SparklineTrend.falling:
        return AppColors.error;
      case SparklineTrend.volatile:
        return AppColors.warning;
      case SparklineTrend.stable:
        return AppColors.primary;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}

/// 컴팩트한 스파크라인 위젯 (카드 내부용)
class CompactSparkline extends StatelessWidget {
  final SparklineData data;
  final double width;
  final double height;

  const CompactSparkline({
    super.key,
    required this.data,
    this.width = 60,
    this.height = 24,
  });

  @override
  Widget build(BuildContext context) {
    return SparklineChart(
      data: data,
      width: width,
      height: height,
      showMetadata: false,
    );
  }
}