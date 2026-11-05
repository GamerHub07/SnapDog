import 'dart:convert';
import '../models/dog_placement.dart';
import '../models/puzzle.dart';

/// Represents a canonical structural fingerprint of a SnapDog puzzle.
///
/// Puzzles with the same region topology and dog placements produce identical
/// canonical fingerprints, regardless of how regions were internally indexed.
class PuzzleFingerprint {
  final String hash;

  const PuzzleFingerprint(this.hash);

  /// Computes a canonical fingerprint from a [Puzzle].
  factory PuzzleFingerprint.compute(Puzzle puzzle) {
    return PuzzleFingerprint.fromGrid(puzzle.regionMap, puzzle.solution);
  }

  /// Computes a canonical fingerprint from a 10x10 [regionMap] and [solution].
  factory PuzzleFingerprint.fromGrid(List<List<int>> regionMap, List<DogPlacement> solution) {
    // 1. Canonicalize region IDs by scanning row by row (order of first appearance: 0..9)
    final idMap = <int, int>{};
    int nextId = 0;
    final buffer = StringBuffer();

    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 10; c++) {
        final rawId = regionMap[r][c];
        final canonId = idMap.putIfAbsent(rawId, () => nextId++);
        buffer.write(canonId.toRadixString(16));
      }
    }

    buffer.write(':');

    // 2. Canonicalize solution dogs sorted by row
    final sortedSolution = List<DogPlacement>.from(solution)
      ..sort((a, b) => a.row.compareTo(b.row));
    for (final p in sortedSolution) {
      buffer.write('${p.row},${p.col};');
    }

    return PuzzleFingerprint(buffer.toString());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PuzzleFingerprint && hash == other.hash;

  @override
  int get hashCode => hash.hashCode;

  @override
  String toString() => hash;
}

/// Tracks recent puzzle fingerprints to prevent duplicate layouts from appearing.
class RecentFingerprintTracker {
  final int maxCapacity;
  final List<String> _history;
  final Set<String> _lookup;

  RecentFingerprintTracker({this.maxCapacity = 50})
      : _history = [],
        _lookup = {};

  RecentFingerprintTracker.fromList(List<String> entries, {this.maxCapacity = 50})
      : _history = List.from(entries),
        _lookup = Set.from(entries);

  /// Checks if [fingerprint] was recently generated or played.
  bool contains(PuzzleFingerprint fingerprint) {
    return _lookup.contains(fingerprint.hash);
  }

  /// Checks if [puzzle]'s fingerprint was recently generated or played.
  bool containsPuzzle(Puzzle puzzle) {
    return contains(PuzzleFingerprint.compute(puzzle));
  }

  /// Records a [fingerprint] into the rolling window.
  void add(PuzzleFingerprint fingerprint) {
    if (_lookup.contains(fingerprint.hash)) return;

    if (_history.length >= maxCapacity) {
      final removed = _history.removeAt(0);
      _lookup.remove(removed);
    }
    _history.add(fingerprint.hash);
    _lookup.add(fingerprint.hash);
  }

  /// Records a [puzzle]'s fingerprint into the rolling window.
  void addPuzzle(Puzzle puzzle) {
    add(PuzzleFingerprint.compute(puzzle));
  }

  /// Serializes the recent fingerprints to a list of strings.
  List<String> toList() => List.unmodifiable(_history);

  /// Serializes to JSON string.
  String toJson() => json.encode(_history);

  /// Deserializes from JSON string.
  factory RecentFingerprintTracker.fromJson(String jsonStr, {int maxCapacity = 50}) {
    try {
      final list = (json.decode(jsonStr) as List<dynamic>).cast<String>();
      return RecentFingerprintTracker.fromList(list, maxCapacity: maxCapacity);
    } catch (_) {
      return RecentFingerprintTracker(maxCapacity: maxCapacity);
    }
  }

  /// Number of tracked fingerprints.
  int get length => _history.length;

  /// Clears the tracker history.
  void clear() {
    _history.clear();
    _lookup.clear();
  }
}
