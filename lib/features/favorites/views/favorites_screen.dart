import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/colors.dart';
import '../../../constants/typography.dart';
import '../../../constants/gaps.dart';
import '../../../common/widgets/app_bar_widget.dart';
import '../../indicators/view_models/indicator_detail_view_model.dart';
import '../../worldbank/models/indicator_codes.dart';
import '../models/favorite_item.dart';
import '../services/favorites_service.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeFavorites() async {
    await FavoritesService.instance.initialize();
    setState(() {}); // Refresh UI after initialization
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkItems = ref.read(bookmarkViewModelProvider.notifier).getBookmarkItems();
    final favoriteItems = FavoritesService.instance.favorites;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBarWidget(
        title: '즐겨찾기',
        showGlobe: false,
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookmarksTab(bookmarkItems),
                _buildFavoritesTab(favoriteItems),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: '즐겨찾기 검색...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabs: [
          Tab(
            icon: const FaIcon(FontAwesomeIcons.bookmark, size: 16),
            text: '북마크',
          ),
          Tab(
            icon: const FaIcon(FontAwesomeIcons.solidHeart, size: 16),
            text: '즐겨찾기',
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksTab(List<BookmarkItem> bookmarkItems) {
    if (bookmarkItems.isEmpty) {
      return _buildEmptyState(
        icon: FontAwesomeIcons.bookmark,
        title: '저장된 북마크가 없습니다',
        subtitle: '지표 상세 페이지에서 북마크를 추가해보세요',
      );
    }

    final filteredItems = _searchQuery.isEmpty
        ? bookmarkItems
        : bookmarkItems
            .where((item) =>
                item.indicatorCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.countryCode.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    if (filteredItems.isEmpty) {
      return _buildEmptyState(
        icon: FontAwesomeIcons.magnifyingGlass,
        title: '검색 결과가 없습니다',
        subtitle: '다른 검색어를 시도해보세요',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildBookmarkCard(item);
      },
    );
  }

  Widget _buildFavoritesTab(List<FavoriteItem> favoriteItems) {
    if (favoriteItems.isEmpty) {
      return _buildEmptyState(
        icon: FontAwesomeIcons.solidHeart,
        title: '저장된 즐겨찾기가 없습니다',
        subtitle: '관심있는 비교나 분석을 즐겨찾기에 추가해보세요',
      );
    }

    final filteredItems = _searchQuery.isEmpty
        ? favoriteItems
        : FavoritesService.instance.searchFavorites(_searchQuery);

    if (filteredItems.isEmpty) {
      return _buildEmptyState(
        icon: FontAwesomeIcons.magnifyingGlass,
        title: '검색 결과가 없습니다',
        subtitle: '다른 검색어를 시도해보세요',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _buildFavoriteCard(item);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            icon,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          Gaps.v20,
          Text(
            title,
            style: AppTypography.heading3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Gaps.v8,
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkCard(BookmarkItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: FaIcon(
              FontAwesomeIcons.chartLine,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
        title: Text(
          _getIndicatorName(item.indicatorCode),
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          _getCountryName(item.countryCode),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: IconButton(
          icon: const FaIcon(
            FontAwesomeIcons.solidBookmark,
            color: AppColors.accent,
            size: 16,
          ),
          onPressed: () => _removeBookmark(item),
        ),
        onTap: () => _navigateToIndicatorDetail(item),
      ),
    );
  }

  Widget _buildFavoriteCard(FavoriteItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getFavoriteTypeColor(item.type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: FaIcon(
              _getFavoriteTypeIcon(item.type),
              color: _getFavoriteTypeColor(item.type),
              size: 20,
            ),
          ),
        ),
        title: Text(
          item.title,
          style: AppTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.type.displayName,
              style: AppTypography.caption.copyWith(
                color: _getFavoriteTypeColor(item.type),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (item.description != null) ...[
              Gaps.v4,
              Text(
                item.description!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          icon: const FaIcon(
            FontAwesomeIcons.ellipsisVertical,
            size: 16,
            color: AppColors.textSecondary,
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.shareNodes,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Text('공유'),
                ],
              ),
              onTap: () => _shareFavorite(item),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.trash,
                    size: 14,
                    color: AppColors.error,
                  ),
                  SizedBox(width: 8),
                  Text('삭제'),
                ],
              ),
              onTap: () => _removeFavorite(item),
            ),
          ],
        ),
        isThreeLine: item.description != null,
        onTap: () => _navigateToFavorite(item),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _showFavoriteOptions,
      backgroundColor: AppColors.primary,
      child: const FaIcon(
        FontAwesomeIcons.plus,
        color: Colors.white,
      ),
    );
  }

  void _showFavoriteOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Gaps.v16,
            Text(
              '즐겨찾기 추가',
              style: AppTypography.heading3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Gaps.v20,
            _buildFavoriteOption(
              icon: FontAwesomeIcons.flag,
              title: '국가 요약',
              subtitle: '현재 선택된 국가의 주요 지표를 저장',
              onTap: () => _createCountrySummaryFavorite(),
            ),
            Gaps.v12,
            _buildFavoriteOption(
              icon: FontAwesomeIcons.chartBar,
              title: '지표 비교',
              subtitle: '선택된 지표의 국가별 비교를 저장',
              onTap: () => _createIndicatorComparisonFavorite(),
            ),
            Gaps.v12,
            _buildFavoriteOption(
              icon: FontAwesomeIcons.userGear,
              title: '사용자 정의',
              subtitle: '나만의 분석 조합을 저장',
              onTap: () => _createCustomFavorite(),
            ),
            Gaps.v20,
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '취소',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: FaIcon(icon, color: AppColors.primary, size: 20),
        ),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  String _getIndicatorName(String code) {
    try {
      final indicator = IndicatorCode.values.firstWhere(
        (i) => i.code == code,
        orElse: () => IndicatorCode.gdpRealGrowth,
      );
      return indicator.name;
    } catch (e) {
      return code;
    }
  }

  String _getCountryName(String code) {
    const countryNames = {
      'KOR': '한국',
      'USA': '미국',
      'JPN': '일본',
      'DEU': '독일',
      'FRA': '프랑스',
      'GBR': '영국',
      'CAN': '캐나다',
      'AUS': '호주',
    };
    return countryNames[code] ?? code;
  }

  Color _getFavoriteTypeColor(FavoriteType type) {
    switch (type) {
      case FavoriteType.countrySummary:
        return AppColors.primary;
      case FavoriteType.indicatorComparison:
        return AppColors.accent;
      case FavoriteType.customComparison:
        return AppColors.warning;
      case FavoriteType.indicatorDetail:
        return Colors.purple;
    }
  }

  IconData _getFavoriteTypeIcon(FavoriteType type) {
    switch (type) {
      case FavoriteType.countrySummary:
        return FontAwesomeIcons.flag;
      case FavoriteType.indicatorComparison:
        return FontAwesomeIcons.chartBar;
      case FavoriteType.customComparison:
        return FontAwesomeIcons.userGear;
      case FavoriteType.indicatorDetail:
        return FontAwesomeIcons.chartLine;
    }
  }

  void _removeBookmark(BookmarkItem item) {
    final indicatorCode = IndicatorCode.values.firstWhere(
      (i) => i.code == item.indicatorCode,
      orElse: () => IndicatorCode.gdpRealGrowth,
    );
    ref.read(bookmarkViewModelProvider.notifier).toggleBookmark(
      indicatorCode,
      item.countryCode,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('북마크가 제거되었습니다'),
        backgroundColor: AppColors.textSecondary,
      ),
    );
  }

  void _removeFavorite(FavoriteItem item) {
    FavoritesService.instance.removeFavorite(item.id);
    setState(() {}); // Refresh UI
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('즐겨찾기가 제거되었습니다'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _shareFavorite(FavoriteItem item) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('공유 기능을 준비 중입니다...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _navigateToIndicatorDetail(BookmarkItem item) {
    try {
      final indicatorCode = IndicatorCode.values.firstWhere(
        (i) => i.code == item.indicatorCode,
      );
      context.push('/indicator/${indicatorCode.code}/${item.countryCode}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('해당 지표를 찾을 수 없습니다'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _navigateToFavorite(FavoriteItem item) {
    // TODO: Navigate based on favorite type
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('즐겨찾기 탐색 기능을 준비 중입니다...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _createCountrySummaryFavorite() {
    // TODO: Implement country summary favorite creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('국가 요약 즐겨찾기 생성 기능을 준비 중입니다...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _createIndicatorComparisonFavorite() {
    // TODO: Implement indicator comparison favorite creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('지표 비교 즐겨찾기 생성 기능을 준비 중입니다...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _createCustomFavorite() {
    // TODO: Implement custom favorite creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('사용자 정의 즐겨찾기 생성 기능을 준비 중입니다...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}