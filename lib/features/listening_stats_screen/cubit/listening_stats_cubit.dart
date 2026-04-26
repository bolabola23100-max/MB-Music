import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music/core/services/listening_stats_service.dart';
import 'listening_stats_state.dart';

class ListeningStatsCubit extends Cubit<ListeningStatsState> {
  final ListeningStatsService _service = ListeningStatsService();

  ListeningStatsCubit() : super(const ListeningStatsState()) {
    loadAllStats();
  }

  Future<void> loadAllStats() async {
    emit(state.copyWith(status: ListeningStatsStatus.loading));
    try {
      final now = DateTime.now();
      final results = await Future.wait([
        _service.getTopSongAllTime(),
        _service.getPlaysForPeriod(DateTime(now.year, now.month, now.day), now.add(const Duration(days: 1))),
        _service.getPlaysForPeriod(DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1)), now.add(const Duration(days: 1))),
        _service.getPlaysForPeriod(DateTime(now.year, now.month, 1), now.add(const Duration(days: 1))),
        _service.getPlaysForPeriod(DateTime(now.year, 1, 1), now.add(const Duration(days: 1))),
      ]);

      final yearlyPlays = results[4] as int;

      emit(state.copyWith(
        status: ListeningStatsStatus.success,
        topSong: results[0] as Map<String, dynamic>?,
        todayPlays: results[1] as int,
        weeklyPlays: results[2] as int,
        monthlyPlays: results[3] as int,
        yearlyPlays: yearlyPlays,
        totalTimeStreamed: yearlyPlays * 3,
      ));
    } catch (e) {
      emit(state.copyWith(status: ListeningStatsStatus.failure));
    }
  }

  void updateDrag(double deltaDy) {
    if (state.canDrag) {
      emit(state.copyWith(
        offsetY: (state.offsetY + deltaDy).clamp(0.0, double.infinity),
      ));
    }
  }

  void setCanDrag(bool canDrag) {
    emit(state.copyWith(canDrag: canDrag, isDragging: canDrag));
  }

  void setIsDragging(bool isDragging) {
    emit(state.copyWith(isDragging: isDragging));
  }

  void resetDrag() {
    emit(state.copyWith(offsetY: 0, isDragging: false, canDrag: false));
  }
}
