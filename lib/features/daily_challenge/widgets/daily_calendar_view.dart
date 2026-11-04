import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/daily_challenge_record.dart';
import '../models/daily_challenge_state.dart';

class DailyCalendarView extends StatefulWidget {
  final DateTime today;
  final DailyChallengeState state;
  final void Function(DateTime date, DailyChallengeRecord record)? onSelectCompletedDate;

  const DailyCalendarView({
    super.key,
    required this.today,
    required this.state,
    this.onSelectCompletedDate,
  });

  @override
  State<DailyCalendarView> createState() => _DailyCalendarViewState();
}

class _DailyCalendarViewState extends State<DailyCalendarView> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime(widget.today.year, widget.today.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthTitle = '${monthNames[month - 1]} $year';

    // Days in current month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Weekday of 1st day (1=Mon ... 7=Sun)
    final firstWeekday = DateTime(year, month, 1).weekday; // 1..7

    final todayNormalized = DateTime(widget.today.year, widget.today.month, widget.today.day);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowWarm,
            offset: Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Month title and arrows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthTitle,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textLight),
                    onPressed: _prevMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 18,
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
                    onPressed: _nextMonth,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 18,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Day-of-week headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _WeekdayHeader('M'),
              _WeekdayHeader('T'),
              _WeekdayHeader('W'),
              _WeekdayHeader('T'),
              _WeekdayHeader('F'),
              _WeekdayHeader('S'),
              _WeekdayHeader('S'),
            ],
          ),
          const SizedBox(height: 8),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: (firstWeekday - 1) + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox.shrink();
              }

              final day = index - (firstWeekday - 1) + 1;
              final cellDate = DateTime(year, month, day);
              final isToday = cellDate == todayNormalized;
              final isFuture = cellDate.isAfter(todayNormalized);
              final isCompleted = widget.state.isCompletedOn(cellDate);

              Color bgColor;
              Color textColor = AppColors.text;
              Widget? iconWidget;
              Border? border;

              if (isCompleted) {
                bgColor = AppColors.success.withValues(alpha: 0.18);
                textColor = AppColors.success;
                iconWidget = const Icon(Icons.check_rounded, size: 12, color: AppColors.success);
                border = Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 1.5);
              } else if (isToday) {
                bgColor = AppColors.primary.withValues(alpha: 0.15);
                textColor = AppColors.primaryDark;
                border = Border.all(color: AppColors.primary, width: 2);
              } else if (isFuture) {
                bgColor = AppColors.background.withValues(alpha: 0.5);
                textColor = AppColors.textMuted.withValues(alpha: 0.4);
                iconWidget = Icon(Icons.lock_outline_rounded, size: 10, color: AppColors.textMuted.withValues(alpha: 0.3));
              } else {
                // Past missed
                bgColor = AppColors.surfaceElevated;
                textColor = AppColors.textMuted;
                iconWidget = Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.cardBorder,
                    shape: BoxShape.circle,
                  ),
                );
              }

              return InkWell(
                onTap: isCompleted
                    ? () {
                        final record = widget.state.getRecord(cellDate);
                        if (record != null && widget.onSelectCompletedDate != null) {
                          widget.onSelectCompletedDate!(cellDate, record);
                        }
                      }
                    : null,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: border,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      if (iconWidget != null) ...[
                        const SizedBox(height: 1),
                        iconWidget,
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LegendItem(
                color: AppColors.success.withValues(alpha: 0.25),
                border: Border.all(color: AppColors.success, width: 1),
                label: 'Completed',
              ),
              _LegendItem(
                color: AppColors.primary.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.primary, width: 1.5),
                label: 'Today',
              ),
              _LegendItem(
                color: AppColors.surfaceElevated,
                border: Border.all(color: AppColors.cardBorder, width: 1),
                label: 'Missed',
              ),
              _LegendItem(
                color: AppColors.background.withValues(alpha: 0.6),
                border: Border.all(color: AppColors.cardBorder, width: 1),
                label: 'Future',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String label;
  const _WeekdayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textLight,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final BoxBorder? border;
  final String label;

  const _LegendItem({
    required this.color,
    this.border,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: border,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }
}
