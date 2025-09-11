import 'package:geo_economy_dashboard/features/authentication/views/login_screen.dart';
import 'package:geo_economy_dashboard/features/authentication/views/sign_up_screen.dart';
import 'package:geo_economy_dashboard/features/authentication/repos/authentication_repo.dart';
import 'package:geo_economy_dashboard/features/home/views/home_screen.dart';
import 'package:geo_economy_dashboard/features/settings/views/settings_screen.dart';
import 'package:geo_economy_dashboard/features/users/views/user_profile_screen.dart';
import 'package:geo_economy_dashboard/features/users/views/change_password_screen.dart';
import 'package:geo_economy_dashboard/features/users/view_models/user_profile_view_model.dart';
import 'package:geo_economy_dashboard/features/indicators/views/indicator_detail_screen.dart';
import 'package:geo_economy_dashboard/features/search/views/search_screen.dart';
import 'package:geo_economy_dashboard/features/favorites/views/favorites_screen.dart';
import 'package:geo_economy_dashboard/common/countries/views/country_detail_screen.dart';
import 'package:geo_economy_dashboard/features/accessibility/views/accessibility_settings_screen.dart';
import 'package:geo_economy_dashboard/features/admin/views/admin_dashboard_screen.dart';
import 'package:geo_economy_dashboard/features/worldbank/models/indicator_codes.dart';
import 'package:geo_economy_dashboard/common/countries/models/country.dart';
import 'package:geo_economy_dashboard/common/main_navigation/main_navigation_screen.dart';
import 'package:geo_economy_dashboard/features/splash/views/splash_screen.dart';
import 'package:geo_economy_dashboard/router/router_constants.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'router_provider.g.dart';

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: "/splash",
    debugLogDiagnostics: true,
    //observers: [GoRouterObserver()],
    redirect: (context, state) async {
      final isLoggedIn = ref.read(isLoggedInProvider);
      final location = state.uri.toString();
      
      print('Router redirect - Location: $location, IsLoggedIn: $isLoggedIn');
      
      // 스플래시 화면은 항상 허용
      if (location.startsWith('/splash')) {
        return null;
      }
      
      // 로그인/회원가입 화면은 항상 허용
      if (location.startsWith('/login') || location.startsWith('/signup')) {
        return null;
      }
      
      // 로그인되지 않은 상태에서 보호된 경로 접근 시 로그인 화면으로 리다이렉트
      if (!isLoggedIn) {
        if (location == '/' || 
            location.startsWith('/settings') || 
            location.startsWith('/favorites') ||
            location.startsWith('/profile') ||
            location.startsWith('/admin')) {
          return '/login';
        }
      }
      
      // 관리자 페이지 접근 시 관리자 권한 확인
      if (location.startsWith('/admin/dashboard')) {
        if (!isLoggedIn) {
          return '/login';
        }
        
        // 관리자 권한 확인
        try {
          final isAdmin = await ref.read(isAdminUserProvider.future);
          if (!isAdmin) {
            return '/'; // 관리자가 아니면 홈으로 리다이렉트
          }
        } catch (e) {
          print('Admin check error: $e');
          return '/login';
        }
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: SplashScreen.routeURL,
        name: SplashScreen.routeName,
        builder: (context, state) => const SplashScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScreen(navigationShell: navigationShell);
        },
        branches: [
          // Home Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'indicator/:indicatorCode/:countryCode',
                    name: RouteName.indicatorDetail,
                    builder: (context, state) {
                      final indicatorCodeStr = state.pathParameters['indicatorCode']!;
                      final countryCode = state.pathParameters['countryCode']!;
                      
                      // IndicatorCode enum 찾기
                      final indicatorCode = IndicatorCode.values.firstWhere(
                        (code) => code.code == indicatorCodeStr,
                        orElse: () => IndicatorCode.gdpRealGrowth, // 기본값
                      );
                      
                      // Country 객체 찾기
                      final country = OECDCountries.findByCode(countryCode) ?? 
                          Country(
                            code: countryCode,
                            name: countryCode,
                            nameKo: _getCountryName(countryCode),
                            flagEmoji: '',
                            region: 'OECD',
                          );
                      
                      return IndicatorDetailScreen(
                        indicatorCode: indicatorCode,
                        country: country,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'country/:countryCode',
                    name: CountryDetailScreen.routeName,
                    builder: (context, state) {
                      final countryCode = state.pathParameters['countryCode']!;
                      
                      // Country 객체 찾기
                      final country = OECDCountries.findByCode(countryCode) ?? 
                          Country(
                            code: countryCode,
                            name: countryCode,
                            nameKo: _getCountryName(countryCode),
                            flagEmoji: '',
                            region: 'OECD',
                          );
                      
                      return CountryDetailScreen(country: country);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Search Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                name: 'search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          // Favorites Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                name: 'favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          // Settings Branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'accessibility',
                    name: 'accessibility',
                    builder: (context, state) => const AccessibilitySettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: SignUpScreen.routeURL,
        name: SignUpScreen.routeName,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: LoginScreen.routeURL,
        name: LoginScreen.routeName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: UserProfileScreen.routeURL,
        name: UserProfileScreen.routeName,
        builder: (context, state) => const UserProfileScreen(),
      ),
      GoRoute(
        path: ChangePasswordScreen.routeURL,
        name: ChangePasswordScreen.routeName,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      // 관리자 라우트
      GoRoute(
        path: '/admin/dashboard',
        name: AdminDashboardScreen.routeName,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
}

/// 국가 코드를 한국어 이름으로 매핑
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
