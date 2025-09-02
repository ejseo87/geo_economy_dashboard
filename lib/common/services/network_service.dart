import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../logger.dart';

/// 네트워크 연결 상태 관리 서비스
class NetworkService {
  static NetworkService? _instance;
  static NetworkService get instance => _instance ??= NetworkService._();
  
  NetworkService._();

  final Connectivity _connectivity = Connectivity();
  
  // 네트워크 상태 스트림
  StreamController<NetworkStatus>? _networkStatusController;
  Stream<NetworkStatus> get networkStatusStream {
    _networkStatusController ??= StreamController<NetworkStatus>.broadcast();
    return _networkStatusController!.stream;
  }

  // 연결 상태를 boolean으로 반환하는 스트림
  Stream<bool> get connectionStream {
    return networkStatusStream.map((status) => status == NetworkStatus.good || status == NetworkStatus.fair);
  }

  NetworkStatus _currentStatus = NetworkStatus.unknown;
  NetworkStatus get currentStatus => _currentStatus;

  Timer? _connectivityTimer;
  bool _isInitialized = false;

  /// 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 초기 연결 상태 확인
      await _checkConnectivity();
      
      // 연결 상태 변화 감지  
      _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
        _onConnectivityChanged([result]); // List로 래핑
      });
      
      // 주기적으로 실제 인터넷 연결 테스트
      _startPeriodicConnectivityCheck();
      
      _isInitialized = true;
      AppLogger.info('[NetworkService] Initialized with status: $_currentStatus');
    } catch (e) {
      AppLogger.error('[NetworkService] Failed to initialize: $e');
      _currentStatus = NetworkStatus.disconnected;
    }
  }

  /// 연결 상태 변화 처리
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    AppLogger.debug('[NetworkService] Connectivity changed: $results');
    _checkConnectivity();
  }

  /// 현재 연결 상태 확인
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      final hasConnection = connectivityResult == ConnectivityResult.wifi ||
          connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.ethernet;

      NetworkStatus newStatus;
      
      if (!hasConnection) {
        newStatus = NetworkStatus.disconnected;
      } else {
        // 실제 인터넷 연결 테스트
        final hasInternetAccess = await _testInternetAccess();
        if (hasInternetAccess) {
          // 연결 품질 확인
          final quality = await _testConnectionQuality();
          newStatus = quality;
        } else {
          newStatus = NetworkStatus.disconnected;
        }
      }

      _updateNetworkStatus(newStatus);
    } catch (e) {
      AppLogger.error('[NetworkService] Error checking connectivity: $e');
      _updateNetworkStatus(NetworkStatus.disconnected);
    }
  }

  /// 실제 인터넷 접근 테스트
  Future<bool> _testInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (e) {
      AppLogger.debug('[NetworkService] Internet access test failed: $e');
      return false;
    }
  }

  /// 연결 품질 테스트
  Future<NetworkStatus> _testConnectionQuality() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // 간단한 HTTP 요청으로 응답 시간 측정
      final socket = await Socket.connect('8.8.8.8', 53)
          .timeout(const Duration(seconds: 3));
      
      stopwatch.stop();
      await socket.close();
      
      final latency = stopwatch.elapsedMilliseconds;
      
      if (latency < 200) {
        return NetworkStatus.good;
      } else if (latency < 1000) {
        return NetworkStatus.fair;
      } else {
        return NetworkStatus.poor;
      }
    } catch (e) {
      AppLogger.debug('[NetworkService] Connection quality test failed: $e');
      return NetworkStatus.poor;
    }
  }

  /// 네트워크 상태 업데이트
  void _updateNetworkStatus(NetworkStatus newStatus) {
    if (_currentStatus != newStatus) {
      final previousStatus = _currentStatus;
      _currentStatus = newStatus;
      
      AppLogger.info('[NetworkService] Status changed: $previousStatus → $newStatus');
      
      // 상태 변화를 스트림에 전달
      _networkStatusController?.add(newStatus);
    }
  }

  /// 주기적 연결 확인 시작
  void _startPeriodicConnectivityCheck() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _checkConnectivity(),
    );
  }

  /// 수동으로 연결 상태 새로고침
  Future<NetworkStatus> refreshConnectivity() async {
    AppLogger.debug('[NetworkService] Manual connectivity refresh requested');
    await _checkConnectivity();
    return _currentStatus;
  }

  /// 온라인 상태 확인
  bool get isOnline => _currentStatus != NetworkStatus.disconnected && _currentStatus != NetworkStatus.unknown;

  /// 고품질 연결 상태 확인
  bool get hasGoodConnection => _currentStatus == NetworkStatus.good;

  /// 연결이 느린지 확인
  bool get isSlowConnection => _currentStatus == NetworkStatus.poor;

  /// 캐시 우선 모드 여부 결정
  bool get shouldPreferCache => !isOnline || isSlowConnection;

  /// 리소스 정리
  void dispose() {
    _connectivityTimer?.cancel();
    _networkStatusController?.close();
    _networkStatusController = null;
    _isInitialized = false;
    AppLogger.debug('[NetworkService] Disposed');
  }
}

/// 네트워크 상태 열거형
enum NetworkStatus {
  unknown('알 수 없음'),
  disconnected('연결 안됨'),
  poor('연결 상태 나쁨'),
  fair('연결 상태 보통'),
  good('연결 상태 좋음');

  const NetworkStatus(this.displayName);
  
  final String displayName;

  /// 상태에 따른 색상 (UI에서 사용)
  String get colorName {
    switch (this) {
      case NetworkStatus.good:
        return 'green';
      case NetworkStatus.fair:
        return 'orange';
      case NetworkStatus.poor:
        return 'red';
      case NetworkStatus.disconnected:
        return 'gray';
      case NetworkStatus.unknown:
        return 'gray';
    }
  }

  /// 상태 아이콘 (UI에서 사용)
  String get iconName {
    switch (this) {
      case NetworkStatus.good:
        return 'wifi';
      case NetworkStatus.fair:
        return 'wifi_2_bar';
      case NetworkStatus.poor:
        return 'wifi_1_bar';
      case NetworkStatus.disconnected:
        return 'wifi_off';
      case NetworkStatus.unknown:
        return 'wifi_find';
    }
  }
}

/// 네트워크 상태 헬퍼 확장
extension NetworkStatusExtensions on NetworkStatus {
  bool get canDownloadLargeData => this == NetworkStatus.good;
  bool get shouldUseCompression => this == NetworkStatus.poor || this == NetworkStatus.fair;
  bool get shouldShowNetworkWarning => this == NetworkStatus.poor || this == NetworkStatus.disconnected;
}