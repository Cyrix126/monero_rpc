/// Converts a list of relative indices to absolute indices.
///
/// The first index remains the same. Each subsequent index is the sum of the
/// previous absolute index and the next relative index.
List<int> convertRelativeToAbsolute(List<int> relativeIndices) {
  if (relativeIndices.isEmpty) {
    return [];
  }

  final absoluteIndices = <int>[];
  int runningTotal = 0;

  for (final index in relativeIndices) {
    runningTotal += index;
    absoluteIndices.add(runningTotal);
  }

  return absoluteIndices;
}
