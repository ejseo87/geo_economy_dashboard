import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants/colors.dart';
import '../../../constants/sizes.dart';
import '../../../common/widgets/app_bar_widget.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBarWidget(
        title: '즐겨찾기',
        showGlobe: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.solidBookmark,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: Sizes.size16),
            Text(
              '즐겨찾기 기능 구현 예정',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}