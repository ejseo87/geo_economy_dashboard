import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/colors.dart';
import '../../../constants/gaps.dart';
import '../../../constants/typography.dart';
import '../models/country.dart';

class CountrySelectionBottomSheet extends StatefulWidget {
  final Country selectedCountry;
  final Function(Country) onCountrySelected;

  const CountrySelectionBottomSheet({
    super.key,
    required this.selectedCountry,
    required this.onCountrySelected,
  });

  @override
  State<CountrySelectionBottomSheet> createState() => _CountrySelectionBottomSheetState();

  /// 바텀시트 표시 헬퍼 메서드
  static void show(
    BuildContext context, {
    required Country selectedCountry,
    required Function(Country) onCountrySelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CountrySelectionBottomSheet(
        selectedCountry: selectedCountry,
        onCountrySelected: onCountrySelected,
      ),
    );
  }
}

class _CountrySelectionBottomSheetState extends State<CountrySelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Country> _filteredCountries = OECDCountries.countries;
  String _selectedTab = 'all'; // 'all', 'region'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredCountries = OECDCountries.searchCountries(_searchController.text);
    });
  }

  void _onCountryTap(Country country) {
    widget.onCountrySelected(country);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildTabBar(),
          Flexible(
            child: _selectedTab == 'all' 
                ? _buildCountryList()
                : _buildRegionGroupedList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 핸들바
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Gaps.v16,
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.globe,
                color: AppColors.primary,
                size: 24,
              ),
              Gaps.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OECD 국가 선택',
                      style: AppTypography.heading3.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '38개국 중에서 선택하세요',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const FaIcon(
                  FontAwesomeIcons.xmark,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '국가명 검색...',
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          prefixIcon: const FaIcon(
            FontAwesomeIcons.magnifyingGlass,
            color: AppColors.textSecondary,
            size: 18,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const FaIcon(
                    FontAwesomeIcons.xmark,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              'all',
              '전체',
              FontAwesomeIcons.list,
            ),
          ),
          Gaps.h12,
          Expanded(
            child: _buildTabButton(
              'region',
              '지역별',
              FontAwesomeIcons.earthAmericas,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String label, IconData icon) {
    final isSelected = _selectedTab == tab;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tab;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 16,
            ),
            Gaps.h8,
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _filteredCountries.length,
      itemBuilder: (context, index) {
        final country = _filteredCountries[index];
        return _buildCountryItem(country);
      },
    );
  }

  Widget _buildRegionGroupedList() {
    final regionMap = OECDCountries.countriesByRegion;
    final regions = regionMap.keys.toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: regions.length,
      itemBuilder: (context, index) {
        final region = regions[index];
        final countries = regionMap[region]!;
        
        return _buildRegionSection(region, countries);
      },
    );
  }

  Widget _buildRegionSection(String region, List<Country> countries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            _getRegionNameKo(region),
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        ...countries.map((country) => _buildCountryItem(country)),
        Gaps.v8,
      ],
    );
  }

  Widget _buildCountryItem(Country country) {
    final isSelected = country.code == widget.selectedCountry.code;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onCountryTap(country),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  country.flagEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                Gaps.h16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        country.nameKo,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${country.name} (${country.code})',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected) ...[
                  Gaps.h12,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '선택됨',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRegionNameKo(String region) {
    switch (region) {
      case 'Asia-Pacific':
        return '아시아-태평양';
      case 'Europe':
        return '유럽';
      case 'North America':
        return '북미';
      case 'Middle East':
        return '중동';
      case 'Latin America':
        return '라틴 아메리카';
      default:
        return region;
    }
  }
}