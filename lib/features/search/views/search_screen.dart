import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:geo_economy_dashboard/constants/colors.dart';
import 'package:geo_economy_dashboard/constants/typography.dart';
import 'package:geo_economy_dashboard/common/countries/models/country.dart';
import 'package:geo_economy_dashboard/features/worldbank/models/indicator_codes.dart';
import '../services/search_history_service.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchingCountries = true; // true: countries, false: indicators
  List<String> _searchHistory = [];
  Timer? _debounceTimer;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
          _showHistory = _searchQuery.isEmpty;
        });
      }
    });
  }

  Future<void> _loadSearchHistory() async {
    final history = await SearchHistoryService.getSearchHistory();
    if (mounted) {
      setState(() {
        _searchHistory = history;
        _showHistory = _searchQuery.isEmpty;
      });
    }
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

  void _onSearchSubmitted(String query) async {
    if (query.trim().isNotEmpty) {
      await SearchHistoryService.addSearchHistory(query);
      await _loadSearchHistory();
    }
  }

  void _onHistoryItemTapped(String query) {
    _searchController.text = query;
    setState(() {
      _searchQuery = query;
      _showHistory = false;
    });
  }

  void _onRemoveHistoryItem(String query) async {
    await SearchHistoryService.removeSearchHistory(query);
    await _loadSearchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: _isSearchingCountries ? '국가명 검색...' : '지표명 검색...',
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _showHistory = true;
                      });
                    },
                  ),
                const Icon(Icons.search, color: Colors.white70),
              ],
            ),
          ),
          style: const TextStyle(color: Colors.white),
          onSubmitted: _onSearchSubmitted,
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

          // 검색 기록 또는 추천 태그 또는 검색 결과
          Expanded(
            child: _showHistory && _searchQuery.isEmpty
                ? _buildSearchHistory()
                : _searchQuery.isEmpty
                    ? _buildRecommendedTags()
                    : (_isSearchingCountries 
                        ? _buildCountryResults()
                        : _buildIndicatorResults()),
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

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return _buildRecommendedTags();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '최근 검색어',
                style: AppTypography.bodyMediumBold,
              ),
              TextButton(
                onPressed: () async {
                  await SearchHistoryService.clearSearchHistory();
                  await _loadSearchHistory();
                },
                child: Text(
                  '전체 삭제',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                final query = _searchHistory[index];
                return ListTile(
                  leading: const Icon(
                    Icons.history,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  title: Text(
                    query,
                    style: AppTypography.bodyMedium,
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    onPressed: () => _onRemoveHistoryItem(query),
                  ),
                  onTap: () => _onHistoryItemTapped(query),
                );
              },
            ),
          ),
          const Divider(),
          _buildRecommendedTagsCompact(),
        ],
      ),
    );
  }

  Widget _buildRecommendedTags() {
    final tags = _isSearchingCountries 
        ? ['한국', '미국', '일본', '독일', '프랑스', '영국', '이탈리아', '캐나다']
        : ['GDP 성장률', '실업률', 'CPI 인플레이션', '경상수지', '1인당 GDP', '제조업 생산', '수출', '수입'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '추천 검색어',
            style: AppTypography.bodyMediumBold,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) => _buildTag(tag)).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            '인기 ${_isSearchingCountries ? "국가" : "지표"}',
            style: AppTypography.bodyMediumBold.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...(_isSearchingCountries ? _buildPopularCountries() : _buildPopularIndicators()),
        ],
      ),
    );
  }

  Widget _buildRecommendedTagsCompact() {
    final tags = _isSearchingCountries 
        ? ['한국', '미국', '일본', '독일']
        : ['GDP', '실업률', '인플레이션', '경상수지'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '추천 검색어',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: tags.map((tag) => _buildTagSmall(tag)).toList(),
        ),
      ],
    );
  }

  List<Widget> _buildPopularCountries() {
    final popularCountries = [
      {'name': '미국', 'flag': '🇺🇸', 'code': 'USA'},
      {'name': '중국', 'flag': '🇨🇳', 'code': 'CHN'},
      {'name': '일본', 'flag': '🇯🇵', 'code': 'JPN'},
      {'name': '독일', 'flag': '🇩🇪', 'code': 'DEU'},
    ];

    return popularCountries.map((country) => 
      ListTile(
        leading: Text(
          country['flag']!,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(country['name']!),
        subtitle: Text(country['code']!),
        trailing: const Icon(Icons.trending_up, size: 16),
        onTap: () {
          _searchController.text = country['name']!;
          setState(() {
            _searchQuery = country['name']!;
            _showHistory = false;
          });
        },
      ),
    ).toList();
  }

  List<Widget> _buildPopularIndicators() {
    final popularIndicators = [
      {'name': 'GDP 성장률', 'icon': Icons.trending_up},
      {'name': '실업률', 'icon': Icons.work_off},
      {'name': 'CPI 인플레이션', 'icon': Icons.attach_money},
      {'name': '경상수지', 'icon': Icons.account_balance},
    ];

    return popularIndicators.map((indicator) => 
      ListTile(
        leading: Icon(
          indicator['icon'] as IconData,
          color: AppColors.accent,
        ),
        title: Text(indicator['name'] as String),
        trailing: const Icon(Icons.trending_up, size: 16),
        onTap: () {
          _searchController.text = indicator['name'] as String;
          setState(() {
            _searchQuery = indicator['name'] as String;
            _showHistory = false;
          });
        },
      ),
    ).toList();
  }

  Widget _buildTag(String tag) {
    return InkWell(
      onTap: () {
        _searchController.text = tag;
        setState(() {
          _searchQuery = tag;
          _showHistory = false;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          tag,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTagSmall(String tag) {
    return InkWell(
      onTap: () {
        _searchController.text = tag;
        setState(() {
          _searchQuery = tag;
          _showHistory = false;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          tag,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 11,
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
          onTap: () async {
            // 검색 기록에 추가
            await SearchHistoryService.addSearchHistory(country.nameKo);
            if (mounted) {
              context.push('/country/${country.code}');
            }
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
          onTap: () async {
            // 검색 기록에 추가
            await SearchHistoryService.addSearchHistory(indicator.name);
            // TODO: Navigate to indicator detail screen with selected country
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${indicator.name} 상세 화면 준비중'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
          },
        );
      },
    );
  }
}