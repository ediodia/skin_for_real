/// Remove presentation markup without destroying Unicode words or punctuation.
String cleanAiText(String text) => text
    .replaceAll(RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false), '')
    .replaceAll(RegExp(r'<think>[\s\S]*$', caseSensitive: false), '')
    .replaceAll(RegExp(r'\*{2,3}'), '')
    .replaceAll(RegExp(r'^\s*#{1,6}\s+', multiLine: true), '')
    .replaceAll('\r\n', '\n')
    .trim();
