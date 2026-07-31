import 'package:flutter/material.dart';

class HomeQuickActions extends StatelessWidget {
  final VoidCallback onIncomePressed;
  final VoidCallback onExpensePressed;

  const HomeQuickActions({
    super.key,
    required this.onIncomePressed,
    required this.onExpensePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          backgroundColor: theme.colorScheme.secondary,
          heroTag: 'income_btn',
          onPressed: onIncomePressed,
          child: Icon(
            Icons.trending_up,
            color: theme.colorScheme.onSecondary,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          backgroundColor: theme.colorScheme.error,
          heroTag: 'expense_btn',
          onPressed: onExpensePressed,
          child: Icon(
            Icons.trending_down,
            color: theme.colorScheme.onError,
            size: 24,
          ),
        ),
      ],
    );
  }
}
