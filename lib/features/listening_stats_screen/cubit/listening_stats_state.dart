import 'package:equatable/equatable.dart';

enum ListeningStatsStatus { initial, loading, success, failure }

class ListeningStatsState extends Equatable {
  final ListeningStatsStatus status;
  final Map<String, dynamic>? topSong;
  final int todayPlays;
  final int weeklyPlays;
  final int monthlyPlays;
  final int yearlyPlays;
  final int totalTimeStreamed;
  final double offsetY;
  final bool isDragging;
  final bool canDrag;

  const ListeningStatsState({
    this.status = ListeningStatsStatus.initial,
    this.topSong,
    this.todayPlays = 0,
    this.weeklyPlays = 0,
    this.monthlyPlays = 0,
    this.yearlyPlays = 0,
    this.totalTimeStreamed = 0,
    this.offsetY = 0,
    this.isDragging = false,
    this.canDrag = false,
  });

  ListeningStatsState copyWith({
    ListeningStatsStatus? status,
    Map<String, dynamic>? topSong,
    int? todayPlays,
    int? weeklyPlays,
    int? monthlyPlays,
    int? yearlyPlays,
    int? totalTimeStreamed,
    double? offsetY,
    bool? isDragging,
    bool? canDrag,
  }) {
    return ListeningStatsState(
      status: status ?? this.status,
      topSong: topSong ?? this.topSong,
      todayPlays: todayPlays ?? this.todayPlays,
      weeklyPlays: weeklyPlays ?? this.weeklyPlays,
      monthlyPlays: monthlyPlays ?? this.monthlyPlays,
      yearlyPlays: yearlyPlays ?? this.yearlyPlays,
      totalTimeStreamed: totalTimeStreamed ?? this.totalTimeStreamed,
      offsetY: offsetY ?? this.offsetY,
      isDragging: isDragging ?? this.isDragging,
      canDrag: canDrag ?? this.canDrag,
    );
  }

  @override
  List<Object?> get props => [
        status,
        topSong,
        todayPlays,
        weeklyPlays,
        monthlyPlays,
        yearlyPlays,
        totalTimeStreamed,
        offsetY,
        isDragging,
        canDrag,
      ];
}
