import 'package:flutter/material.dart';

class HomeMonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final List<String> months;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const HomeMonthSelector({
    super.key,
    required this.selectedMonth,
    required this.months,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthYear = '${months[selectedMonth.month - 1]} ${selectedMonth.year}';
    final isCurrentMonth =
        selectedMonth.year == DateTime.now().year && selectedMonth.month == DateTime.now().month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: theme.scaffoldBackgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onPrevious,
                child: Icon(
                  Icons.chevron_left,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                monthYear,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: 0.3,
                ),
              ),
              if (isCurrentMonth)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Mes actual',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onNext,
                child: Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
