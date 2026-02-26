import 'package:equatable/equatable.dart';

abstract class SongTuningEvent extends Equatable {
  const SongTuningEvent();

  @override
  List<Object?> get props => const [];
}

class SongNameChanged extends SongTuningEvent {
  const SongNameChanged(this.songName);

  final String songName;

  @override
  List<Object?> get props => [songName];
}

class SongTuningSubmitted extends SongTuningEvent {
  const SongTuningSubmitted();
}

