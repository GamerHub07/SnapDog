/// Represents a cell in the 10x10 puzzle board.
class PuzzleCell {
  final int row;
  final int col;
  final int regionId;
  final bool isOccupied;
  final bool hasClash;
  final bool isMarkedEmpty;

  const PuzzleCell({
    required this.row,
    required this.col,
    required this.regionId,
    this.isOccupied = false,
    this.hasClash = false,
    this.isMarkedEmpty = false,
  });

  PuzzleCell copyWith({
    int? row,
    int? col,
    int? regionId,
    bool? isOccupied,
    bool? hasClash,
    bool? isMarkedEmpty,
  }) {
    return PuzzleCell(
      row: row ?? this.row,
      col: col ?? this.col,
      regionId: regionId ?? this.regionId,
      isOccupied: isOccupied ?? this.isOccupied,
      hasClash: hasClash ?? this.hasClash,
      isMarkedEmpty: isMarkedEmpty ?? this.isMarkedEmpty,
    );
  }
}
