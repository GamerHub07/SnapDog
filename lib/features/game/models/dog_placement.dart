/// Represents a dog placed at a specific grid position.
class DogPlacement {
  final int row;
  final int col;

  const DogPlacement(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DogPlacement &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'DogPlacement($row, $col)';
}
