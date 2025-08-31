import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:geo_economy_dashboard/constants/colors.dart';
import 'package:geo_economy_dashboard/constants/typography.dart';
import 'package:geo_economy_dashboard/common/countries/models/country.dart';
import 'package:geo_economy_dashboard/features/worldbank/models/indicator_codes.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchingCountries = true; // true: countries, false: indicators

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Country> get _filteredCountries {
    if (_searchQuery.isEmpty) return OECDCountries.countries;
    return OECDCountries.searchCountries(_searchQuery);
  }

  List<IndicatorCode> get _filteredIndicators {
    if (_searchQuery.isEmpty) return IndicatorCode.values;
    final query = _searchQuery.toLowerCase();
    return IndicatorCode.values.where((indicator) {
      return indicator.name.toLowerCase().contains(query) ||
             indicator.code.toLowerCase().contains(query) ||
             indicator.unit.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: const InputDecoration(
            hintText: '국가명 또는 지표명 검색...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            suffixIcon: Icon(Icons.search, color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // 검색 카테고리 토글
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildCategoryButton(
                    '국가',
                    _isSearchingCountries,
                    () => setState(() => _isSearchingCountries = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCategoryButton(
                    '지표',
                    !_isSearchingCountries,
                    () => setState(() => _isSearchingCountries = false),
                  ),
                ),
              ],
            ),
          ),

          // 추천 태그
          if (_searchQuery.isEmpty) _buildRecommendedTags(),

          // 검색 결과
          Expanded(
            child: _isSearchingCountries 
                ? _buildCountryResults()
                : _buildIndicatorResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String title, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary,
            width: 1,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedTags() {
    final tags = _isSearchingCountries 
        ? ['한국', '미국', '일본', '독일', '중국']
        : ['GDP', '실업률', '인플레이션', '경상수지', '제조업'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '추천 검색어',
            style: AppTypography.bodyMediumBold,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: tags.map((tag) => _buildTag(tag)).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    return InkWell(
      onTap: () {
        _searchController.text = tag;
        setState(() {
          _searchQuery = tag;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          tag,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCountryResults() {
    final countries = _filteredCountries;
    
    if (countries.isEmpty) {
      return const Center(
        child: Text(
          '검색 결과가 없습니다',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: countries.length,
      itemBuilder: (context, index) {
        final country = countries[index];
        return ListTile(
          leading: Text(
            country.flagEmoji,
            style: const TextStyle(fontSize: 24),
          ),
          title: Text(country.nameKo),
          subtitle: Text(country.name),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            context.push('/country/${country.code}');
          },
        );
      },
    );
  }

  Widget _buildIndicatorResults() {
    final indicators = _filteredIndicators;
    
    if (indicators.isEmpty) {
      return const Center(
        child: Text(
          '검색 결과가 없습니다',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: indicators.length,
      itemBuilder: (context, index) {
        final indicator = indicators[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const FaIcon(
              FontAwesomeIcons.chartLine,
              size: 20,
              color: AppColors.accent,
            ),
          ),
          title: Text(indicator.name),
          subtitle: Text(
            '${indicator.code} • ${indicator.unit}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // TODO: Navigate to indicator detail screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${indicator.name} 상세 화면으로 이동'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        );
      },
    );
  }
}