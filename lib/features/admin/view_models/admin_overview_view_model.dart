import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_economy_dashboard/features/admin/services/admin_overview_service.dart';

part 'admin_overview_view_model.g.dart';

@riverpod
Future<SystemStatus> systemStatus(Ref ref) async {
  return await AdminOverviewService.instance.getSystemStatus();
}

@riverpod
Future<DataStatistics> dataStatistics(Ref ref) async {
  return await AdminOverviewService.instance.getDataStatistics();
}

@riverpod
Future<UserStatistics> userStatistics(Ref ref) async {
  return await AdminOverviewService.instance.getUserStatistics();
}

@riverpod
Future<List<RecentActivity>> recentActivity(Ref ref) async {
  return await AdminOverviewService.instance.getRecentActivity();
}

// 실시간 스트림 프로바이더
@riverpod
Stream<DataStatistics> dataStatisticsStream(Ref ref) {
  return AdminOverviewService.instance.dataStatisticsStream;
}

@riverpod
Stream<UserStatistics> userStatisticsStream(Ref ref) {
  return AdminOverviewService.instance.userStatisticsStream;
}

@riverpod
Stream<List<RecentActivity>> recentActivityStream(Ref ref) {
  return AdminOverviewService.instance.recentActivityStream;
}