import 'package:geo_economy_dashboard/features/authentication/views/login_screen.dart';
import 'package:geo_economy_dashboard/features/authentication/views/sign_up_screen.dart';
import 'package:geo_economy_dashboard/features/home/views/home_screen.dart';
import 'package:geo_economy_dashboard/features/settings/views/settings_screen.dart';
import 'package:geo_economy_dashboard/features/users/views/user_profile_screen.dart';
import 'package:geo_economy_dashboard/features/indicators/views/indicator_detail_screen.dart';
import 'package:geo_economy_dashboard/features/worldbank/models/indicator_codes.dart';
import 'package:geo_economy_dashboard/features/countries/models/country.dart';
import 'package:geo_economy_dashboard/router/router_constants.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_provider.g.dart';

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: "/home",
    debugLogDiagnostics: true,
    //observers: [GoRouterObserver()],
    redirect: (context, state) {
      return null;
    },
    routes: [
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
        path: RouteURL.home,
        name: RouteName.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: "/profile/:username",
        name: UserProfileScreen.routeName,
        builder: (context, state) {
          final username = state.pathParameters['username']!;
          final tab = state.uri.queryParameters['tab'] ?? "";
          return UserProfileScreen(username: username, tab: tab);
        },
      ),
      GoRoute(
        path: RouteURL.settings,
        name: RouteName.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteURL.indicatorDetail,
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
