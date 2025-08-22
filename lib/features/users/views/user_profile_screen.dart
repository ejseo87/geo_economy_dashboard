import 'package:geo_economy_dashboard/constants/gaps.dart';
import 'package:geo_economy_dashboard/constants/sizes.dart';
import 'package:geo_economy_dashboard/features/settings/views/settings_screen.dart';
import 'package:geo_economy_dashboard/features/users/view_models/users_view_model.dart';
import 'package:geo_economy_dashboard/features/users/views/widgets/avatar.dart';
import 'package:geo_economy_dashboard/features/users/views/widgets/persistant_tab_bar.dart';
import 'package:geo_economy_dashboard/features/users/views/widgets/profile_detail_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  static const String routeName = "profile";
  static const String routeURL = "/profile";
  final String username;
  final String tab;
  const UserProfileScreen({
    super.key,
    required this.username,
    required this.tab,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => UserProfileScreenState();
}

class UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  void _onGreaPressed() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(userProvider)
        .when(
          error: (error, stackTrace) => Center(child: Text(error.toString())),
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
          data: (data) => Scaffold(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            body: SafeArea(
              child: DefaultTabController(
                initialIndex: widget.tab == "likes" ? 1 : 0,
                length: 2,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverAppBar(
                      title: Text(data.name),
                      actions: [
                        IconButton(
                          onPressed: _onGreaPressed,
                          icon: const FaIcon(
                            FontAwesomeIcons.gear,
                            size: Sizes.size20,
                          ),
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Gaps.v20,
                          Avatar(
                            name: data.name,
                            hasAvatar: data.hasAvatar,
                            uid: data.uid,
                          ),
                          Gaps.v20,
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "@${data.name}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Gaps.h5,
                              FaIcon(
                                FontAwesomeIcons.solidCircleCheck,
                                size: Sizes.size16,
                                color: Colors.blue.shade500,
                              ),
                            ],
                          ),
                          Gaps.v14,
                          SizedBox(
                            //height: Sizes.size52,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const ProfileDetailCard(
                                  numberString: "97",
                                  numberLabel: "Following",
                                ),
                                VerticalDivider(
                                  width: Sizes.size32,
                                  thickness: Sizes.size1,
                                  color: Colors.grey.shade400,
                                  indent: Sizes.size14,
                                  endIndent: Sizes.size14,
                                ),
                                const ProfileDetailCard(
                                  numberString: "10.5M",
                                  numberLabel: "Followers",
                                ),
                                VerticalDivider(
                                  width: Sizes.size32,
                                  thickness: Sizes.size1,
                                  color: Colors.grey.shade400,
                                  indent: Sizes.size14,
                                  endIndent: Sizes.size14,
                                ),
                                const ProfileDetailCard(
                                  numberString: "143.7M",
                                  numberLabel: "Likes",
                                ),
                              ],
                            ),
                          ),
                          Gaps.v14,
                          FractionallySizedBox(
                            widthFactor: 0.33,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: Sizes.size12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(
                                  Sizes.size4,
                                ),
                              ),
                              child: const Text(
                                "Follow",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Gaps.v14,
                          const FractionallySizedBox(
                            widthFactor: 0.8,
                            child: Text(
                              textAlign: TextAlign.center,
                              "All highlights and where to watch live matches on FIFA+",
                              style: TextStyle(
                                fontSize: Sizes.size14,
                                height: 1.1,
                              ),
                            ),
                          ),
                          Gaps.v14,
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(FontAwesomeIcons.link, size: Sizes.size12),
                              Gaps.h5,
                              Text(
                                "https://nomadcoders.co",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: Sizes.size14,
                                ),
                              ),
                            ],
                          ),
                          Gaps.v14,
                        ],
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: PersistentTabBar(),
                    ),
                  ],
                  body: TabBarView(
                    children: [
                      const Center(child: Text("Page1")),
                      const Center(child: Text("Page2")),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
  }
}
