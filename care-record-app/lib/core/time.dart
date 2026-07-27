/// Caregiving shift bucket for a timestamp (matches whiteboard-ocr-bot's 早/晚/大夜).
String shiftOfDay(DateTime t) {
  final h = t.hour;
  if (h >= 6 && h < 14) return '早';
  if (h >= 14 && h < 22) return '晚';
  return '大夜';
}
