import 'package:drip_wallet/features/home/presentation/pages/recurring_expenses_screen.dart';
import 'package:drip_wallet/features/home/presentation/pages/recurring_income_screen.dart';
import 'package:drip_wallet/features/finance/data/datasources/finance_remote_datasource.dart';
import 'package:drip_wallet/features/finance/finance_exports.dart';
import 'package:drip_wallet/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class HomeRecurringTransactionsSection extends StatelessWidget {
  final DateTime selectedMonth;

  const HomeRecurringTransactionsSection({
    super.key,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    final user = supabase.Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getIt<FinanceRemoteDataSource>().getRecurringTransactionsForMonth(
        user.id,
        selectedMonth,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final recurringList = snapshot.data ?? [];
        double expenseTotal = 0.0;
        double incomeTotal = 0.0;

        for (var item in recurringList) {
          final amount = (item['amount'] as num).toDouble();
          if (item['type'] == 'expense') {
            expenseTotal += amount;
          } else {
            incomeTotal += amount;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transacciones Regulares',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => RecurringExpensesScreen(
                            selectedMonth: selectedMonth,
                          ),
                        ),
                      );
                    },
                    child: _SummaryCard(
                      icon: Icons.trending_down,
                      title: 'Gastos Fijos',
                      amount: expenseTotal,
                      backgroundColor: Theme.of(context).colorScheme.errorContainer,
                      foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                      iconColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => RecurringIncomeScreen(
                            selectedMonth: selectedMonth,
                          ),
                        ),
                      );
                    },
                    child: _SummaryCard(
                      icon: Icons.trending_up,
                      title: 'Ingresos Fijos',
                      amount: incomeTotal,
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                      iconColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final double amount;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color iconColor;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.amount,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: foregroundColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '\$${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: foregroundColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
