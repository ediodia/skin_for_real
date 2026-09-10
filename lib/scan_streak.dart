/// Counts consecutive local calendar days, independently of DST day lengths.
int nextScanStreak(int current, String? lastDay, DateTime completedAt) {
  final today =
      DateTime.utc(completedAt.year, completedAt.month, completedAt.day);
  final previous = DateTime.tryParse(lastDay ?? '');
  if (previous == null) return 1;
  final day = DateTime.utc(previous.year, previous.month, previous.day);
  final gap = today.difference(day).inDays;
  if (gap <= 0) return current;
  return gap == 1 ? current + 1 : 1;
}
