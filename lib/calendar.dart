import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class SkinProgressCalendar extends StatefulWidget {
  const SkinProgressCalendar({super.key});

  @override
  State<SkinProgressCalendar> createState() => _SkinProgressCalendarState();
}

class _SkinProgressCalendarState extends State<SkinProgressCalendar> with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, Map<String, dynamic>> _entries = {};
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;
  final ScrollController _scrollController = ScrollController();

  final Map<String, Color> _typeColors = {
    'Acne-prone': Color(0xFFFF6B6B),
    'Oily': Color(0xFFFFD93D),
    'Dry': Color(0xFF6BCB77),
    'Combination/Normal': Color(0xFF4D96FF),
  };

  final Map<String, IconData> _typeIcons = {
    'Acne-prone': Icons.warning_amber_rounded,
    'Oily': Icons.water_drop_rounded,
    'Dry': Icons.wb_sunny_rounded,
    'Combination/Normal': Icons.balance_rounded,
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _loadLogs();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('log_'));
    final Map<String, Map<String, dynamic>> data = {};

    for (final key in keys) {
      final date = key.replaceFirst('log_', '');
      final raw = prefs.getString(key);
      if (raw != null) {
        try {
          data[date] = jsonDecode(raw);
        } catch (_) {
          data[date] = {'type': 'Unknown', 'tips': 'N/A'};
        }
      }
    }

    setState(() => _entries = data);
    _fadeController.forward();
  }

  Future<void> _clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = prefs.getKeys()
        .where((k) => k.startsWith('log_') || k.startsWith('progress_'))
        .toList();
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
    setState(() => _entries = {});
  }

  String _cleanText(String text) {
    return text
        .replaceAll('**', '')
        .replaceAll('###', '')
        .replaceAll('##', '')
        .replaceAll('#', '')
        .replaceAll(RegExp(r'[^\x00-\x7F\n\r\t ]'), '');
  }

  Color _getTypeColor(String? type) => _typeColors[type] ?? const Color(0xFF4D96FF);
  IconData _getTypeIcon(String? type) => _typeIcons[type] ?? Icons.face_rounded;

  void _showEntryDetails(DateTime day) {
    final todayStr = day.toIso8601String().split('T')[0];
    final current = _entries[todayStr];

    if (current == null) {
      _showModernPopup(todayStr, null);
      return;
    }

    final prevDay = day.subtract(const Duration(days: 1)).toIso8601String().split('T')[0];
    final prev = _entries[prevDay];

    String comparison = 'No previous day data for comparison.';
    if (prev != null && prev['type'] != null) {
      final prevType = prev['type'];
      final currentType = current['type'];
      if (prevType != currentType) {
        comparison = 'Skin type changed from $prevType to $currentType.';
      } else {
        comparison = 'Consistent with the previous day ($currentType).';
      }
    }

    _showModernPopup(todayStr, current, comparison: comparison);
  }

  void _showModernPopup(String date, Map<String, dynamic>? entry, {String? comparison}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final type = entry?['type'] as String?;
        final color = _getTypeColor(type);
        final isDesktop = MediaQuery.of(context).size.width > 600;

        final inner = Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1e1e2e) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      children: [
                        Text(date, style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        if (type != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getTypeIcon(type), size: 14, color: color),
                                const SizedBox(width: 6),
                                Text(type, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (entry == null)
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No log for this day', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                          ],
                        ),
                      )
                    else ...[
                      if (entry['color'] != null)
                        _PopupCard(
                          title: 'Skin Tone',
                          content: entry['color'].toString(),
                          icon: Icons.palette_rounded,
                          color: Colors.purple,
                          isDark: isDark,
                        ),
                      const SizedBox(height: 12),
                      if (entry['tips'] != null)
                        _PopupCard(
                          title: 'Recommendations',
                          content: _cleanText(entry['tips'].toString()),
                          icon: Icons.auto_awesome_rounded,
                          color: Colors.deepPurple,
                          isDark: isDark,
                        ),
                      const SizedBox(height: 12),
                      if (comparison != null)
                        _PopupCard(
                          title: 'Comparison',
                          content: comparison,
                          icon: Icons.trending_up_rounded,
                          color: Colors.teal,
                          isDark: isDark,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );

        if (isDesktop) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            child: inner,
          );
        }

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.95,
          minChildSize: 0.3,
          expand: false,
          snap: true,
          snapSizes: const [0.6, 0.95],
          builder: (_, __) => inner,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1a1a2e) : const Color(0xFFF8F4FF),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white12 : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
                              ),
                              child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Skin Progress', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.deepPurple.shade800)),
                                Text('Tap a day to see your log', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: const Text('Clear All Logs?', style: TextStyle(fontWeight: FontWeight.bold)),
                                  content: const Text('This will permanently delete all your skin tracking data.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _clearLogs();
                                      },
                                      child: const Text('Clear', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _typeColors.entries.map((e) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: e.value.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 8, height: 8, decoration: BoxDecoration(color: e.value, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Text(e.key, style: TextStyle(fontSize: 11, color: e.value, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF16213e) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.deepPurple.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
                      ),
                      child: TableCalendar(
                        focusedDay: _focusedDay,
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selected, focused) {
                          setState(() {
                            _selectedDay = selected;
                            _focusedDay = focused;
                          });
                          _showEntryDetails(selected);
                        },
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            final dateStr = day.toIso8601String().split('T')[0];
                            final entry = _entries[dateStr];
                            if (entry != null) {
                              final color = _getTypeColor(entry['type'] as String?);
                              return Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text('${day.day}', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                              );
                            }
                            return null;
                          },
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.deepPurple.shade800),
                          leftChevronIcon: Icon(Icons.chevron_left_rounded, color: isDark ? Colors.white54 : Colors.deepPurple),
                          rightChevronIcon: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white54 : Colors.deepPurple),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
                          weekendStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: false,
                          todayDecoration: BoxDecoration(color: Colors.deepPurple.withValues(alpha: 0.3), shape: BoxShape.circle),
                          selectedDecoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
                          defaultTextStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                          weekendTextStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _StatCard(label: 'Days Logged', value: '${_entries.length}', color: Colors.deepPurple, isDark: isDark),
                          const SizedBox(width: 12),
                          _StatCard(
                            label: 'Most Common',
                            value: _entries.isEmpty ? 'N/A' : (_entries.values
                                .map((e) => e['type'] as String? ?? '')
                                .fold<Map<String, int>>({}, (map, t) {
                                  map[t] = (map[t] ?? 0) + 1;
                                  return map;
                                })
                                .entries
                                .reduce((a, b) => a.value > b.value ? a : b)
                                .key),
                            color: Colors.indigo,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PopupCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _PopupCard({required this.title, required this.content, required this.icon, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(content, style: TextStyle(fontSize: 13, height: 1.6, color: isDark ? Colors.white70 : Colors.black87)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCard({required this.label, required this.value, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16213e) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.deepPurple.withValues(alpha: 0.06), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}