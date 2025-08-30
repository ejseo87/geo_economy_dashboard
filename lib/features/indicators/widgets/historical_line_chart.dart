import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/sizes.dart';
import '../../worldbank/models/indicator_codes.dart';

class HistoricalLineChart extends StatefulWidget {
  final IndicatorCode indicator;
  final Map<String, List<HistoricalDataPoint>> countryData;
  final String? selectedCountry;
  final Function(String?)? onCountrySelected;
  final double height;
  final bool showLegend;
  final bool showTooltips;

  const HistoricalLineChart({
    super.key,
    required this.indicator,
    required this.countryData,
    this.selectedCountry,
    this.onCountrySelected,
    this.height = 300,
    this.showLegend = true,
    this.showTooltips = true,
  });

  @override
  State<HistoricalLineChart> createState() => _HistoricalLineChartState();
}

class _HistoricalLineChartState extends State<HistoricalLineChart> {
  int? hoveredSpotIndex;
  String? hoveredCountryCode;

  @override
  Widget build(BuildContext context) {
    if (widget.countryData.isEmpty) {
      return _buildEmptyState();
    }

    final minYear = _getMinYear();
    final maxYear = _getMaxYear();
    final minValue = _getMinValue();
    final maxValue = _getMaxValue();

    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(Sizes.size16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showLegend) _buildLegend(),
          if (widget.showLegend) const SizedBox(height: Sizes.size16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: _calculateInterval(minValue, maxValue),
                  verticalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.outline.withValues(alpha: 0.5),
                    strokeWidth: 0.5,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: AppColors.outline.withValues(alpha: 0.3),
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      interval: _calculateInterval(minValue, maxValue),
                      getTitlesWidget: (value, meta) => _buildLeftTitle(value),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 2,
                      getTitlesWidget: (value, meta) => _buildBottomTitle(value, minYear),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: AppColors.outline.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                minX: 0,
                maxX: (maxYear - minYear).toDouble(),
                minY: minValue,
                maxY: maxValue,
                lineBarsData: _buildLineBarsData(minYear),
                lineTouchData: widget.showTooltips ? _buildTouchData(minYear) : LineTouchData(enabled: false),
              ),
            ),
          ),
          if (widget.showTooltips) _buildYearRangeInfo(minYear, maxYear),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: widget.height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: Sizes.size12),
            Text(
              '데이터가 없습니다',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: Sizes.size16,
      runSpacing: Sizes.size8,
      children: widget.countryData.keys.map((countryCode) {
        final color = _getCountryColor(countryCode);
        final isSelected = widget.selectedCountry == countryCode;
        
        return InkWell(
          onTap: () => widget.onCountrySelected?.call(
            isSelected ? null : countryCode,
          ),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Sizes.size12,
              vertical: Sizes.size6,
            ),
            decoration: BoxDecoration(
              color: isSelected 
                ? color.withValues(alpha: 0.1) 
                : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: Sizes.size8),
                Text(
                  _getCountryName(countryCode),
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? color : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLeftTitle(double value) {
    final formatted = _formatValue(value);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        formatted,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildBottomTitle(double value, int minYear) {
    final year = minYear + value.toInt();
    return Text(
      year.toString(),
      style: AppTypography.caption.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildYearRangeInfo(int minYear, int maxYear) {
    return Padding(
      padding: const EdgeInsets.only(top: Sizes.size8),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: Sizes.size4),
          Text(
            '$minYear년 ~ $maxYear년 데이터',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            widget.indicator.unit,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData(int minYear) {
    final List<LineChartBarData> lines = [];
    int colorIndex = 0;

    widget.countryData.forEach((countryCode, dataPoints) {
      final color = _getCountryColor(countryCode);
      final isHighlighted = widget.selectedCountry == null || 
                           widget.selectedCountry == countryCode;
      
      final spots = dataPoints.map((point) {
        return FlSpot(
          (point.year - minYear).toDouble(),
          point.value,
        );
      }).toList();

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.2,
          color: color,
          barWidth: isHighlighted ? 3 : 1.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: isHighlighted,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: color,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: isHighlighted && widget.selectedCountry == countryCode,
            color: color.withValues(alpha: 0.1),
          ),
          preventCurveOverShooting: true,
        ),
      );
      colorIndex++;
    });

    return lines;
  }

  LineTouchData _buildTouchData(int minYear) {
    return LineTouchData(
      enabled: true,
      touchTooltipData: LineTouchTooltipData(
        tooltipRoundedRadius: 8,
        tooltipPadding: const EdgeInsets.all(8),
        tooltipMargin: 16,
        getTooltipColor: (touchedSpot) => AppColors.textPrimary.withValues(alpha: 0.8),
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((LineBarSpot touchedSpot) {
            final countryCode = widget.countryData.keys.elementAt(touchedSpot.barIndex);
            final year = minYear + touchedSpot.x.toInt();
            final value = touchedSpot.y;
            
            return LineTooltipItem(
              '${_getCountryName(countryCode)}\n$year년: ${_formatValue(value)}${widget.indicator.unit}',
              TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            );
          }).toList();
        },
      ),
      touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
        setState(() {
          if (touchResponse != null && touchResponse.lineBarSpots != null) {
            final spot = touchResponse.lineBarSpots!.first;
            hoveredSpotIndex = spot.x.toInt();
            hoveredCountryCode = widget.countryData.keys.elementAt(spot.barIndex);
          } else {
            hoveredSpotIndex = null;
            hoveredCountryCode = null;
          }
        });
      },
    );
  }

  int _getMinYear() {
    int? minYear;
    for (var dataPoints in widget.countryData.values) {
      for (final point in dataPoints) {
        if (minYear == null || point.year < minYear!) {
          minYear = point.year;
        }
      }
    }
    return minYear ?? DateTime.now().year - 10;
  }

  int _getMaxYear() {
    int? maxYear;
    for (var dataPoints in widget.countryData.values) {
      for (final point in dataPoints) {
        if (maxYear == null || point.year > maxYear!) {
          maxYear = point.year;
        }
      }
    }
    return maxYear ?? DateTime.now().year;
  }

  double _getMinValue() {
    double? minValue;
    for (var dataPoints in widget.countryData.values) {
      for (final point in dataPoints) {
        if (minValue == null || point.value < minValue!) {
          minValue = point.value;
        }
      }
    }
    final min = minValue ?? 0.0;
    return min < 0 ? min * 1.1 : min * 0.9;
  }

  double _getMaxValue() {
    double? maxValue;
    for (var dataPoints in widget.countryData.values) {
      for (final point in dataPoints) {
        if (maxValue == null || point.value > maxValue!) {
          maxValue = point.value;
        }
      }
    }
    final max = maxValue ?? 100.0;
    return max > 0 ? max * 1.1 : max * 0.9;
  }

  double _calculateInterval(double min, double max) {
    final range = max - min;
    if (range <= 10) return 1;
    if (range <= 50) return 5;
    if (range <= 100) return 10;
    if (range <= 500) return 50;
    if (range <= 1000) return 100;
    return (range / 10).roundToDouble();
  }

  Color _getCountryColor(String countryCode) {
    final colors = [
      AppColors.primary,
      AppColors.accent,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.brown,
    ];
    
    final index = widget.countryData.keys.toList().indexOf(countryCode);
    return colors[index % colors.length];
  }

  String _getCountryName(String countryCode) {
    const countryNames = {
      'KOR': '한국', 'USA': '미국', 'JPN': '일본', 'DEU': '독일', 'GBR': '영국',
      'FRA': '프랑스', 'ITA': '이탈리아', 'CAN': '캐나다', 'AUS': '호주', 'ESP': '스페인',
      'NLD': '네덜란드', 'BEL': '벨기에', 'CHE': '스위스', 'AUT': '오스트리아', 'SWE': '스웨덴',
      'NOR': '노르웨이', 'DNK': '덴마크', 'FIN': '핀란드', 'POL': '폴란드', 'CZE': '체코',
      'HUN': '헝가리', 'SVK': '슬로바키아', 'SVN': '슬로베니아', 'EST': '에스토니아',
      'LVA': '라트비아', 'LTU': '리투아니아', 'PRT': '포르투갈', 'GRC': '그리스',
      'TUR': '튀르키예', 'MEX': '멕시코', 'CHL': '칠레', 'COL': '콜롬비아', 'CRI': '코스타리카',
      'ISL': '아이슬란드', 'IRL': '아일랜드', 'ISR': '이스라엘', 'LUX': '룩셈부르크',
      'NZL': '뉴질랜드',
    };
    return countryNames[countryCode] ?? countryCode;
  }

  String _formatValue(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else if (value.abs() >= 100) {
      return value.toStringAsFixed(0);
    } else {
      return value.toStringAsFixed(1);
    }
  }
}

class HistoricalDataPoint {
  final int year;
  final double value;

  const HistoricalDataPoint({
    required this.year,
    required this.value,
  });

  factory HistoricalDataPoint.fromJson(Map<String, dynamic> json) {
    return HistoricalDataPoint(
      year: json['year'] as int,
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'value': value,
    };
  }

  @override
  String toString() => 'HistoricalDataPoint(year: $year, value: $value)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoricalDataPoint &&
           other.year == year &&
           other.value == value;
  }

  @override
  int get hashCode => Object.hash(year, value);
}