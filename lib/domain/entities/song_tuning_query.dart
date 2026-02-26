/// Query de dominio para buscar afinacion de guitarra por cancion.
class SongTuningQuery {
  const SongTuningQuery({
    required this.songName,
    this.artistName,
  });

  /// Nombre de la cancion ingresado por el usuario.
  final String songName;

  /// Artista opcional para desambiguar canciones homonimas.
  final String? artistName;

  String get normalizedSongName => songName.trim();

  String? get normalizedArtistName {
    final value = artistName?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  bool get isValid => normalizedSongName.isNotEmpty;

  SongTuningQuery copyWith({
    String? songName,
    String? artistName,
  }) {
    return SongTuningQuery(
      songName: songName ?? this.songName,
      artistName: artistName ?? this.artistName,
    );
  }

  @override
  String toString() {
    return 'SongTuningQuery(songName: $songName, artistName: $artistName)';
  }
}

