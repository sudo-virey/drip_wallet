// lib/features/history/presentation/pages/history_screen.dart
import 'package:drip_wallet/core/theme/drip_theme_helper.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedCategory = 'All Categories';
  String _selectedDateFilter = 'This Month';

  final List<String> _categories = [
    'All Categories',
    'Groceries',
    'Utilities',
    'Entertainment',
  ];

  final Map<String, List<Map<String, dynamic>>> _transactionsByDate = {
    'TODAY, OCT 24': [
      {
        'icon': Icons.shopping_cart,
        'iconColor': Colors.green.shade100,
        'iconColorBg': const Color(0xFF4CAF50),
        'title': 'Whole Foods Market',
        'category': 'Groceries',
        'time': '2:30 PM',
        'amount': -142.50,
        'avatar': '👩‍🦰',
      },
      {
        'icon': Icons.local_gas_station,
        'iconColor': Colors.blue.shade100,
        'iconColorBg': const Color(0xFF2196F3),
        'title': 'Shell Station',
        'category': 'Auto',
        'time': '9:15 AM',
        'amount': -45.00,
        'avatar': '👨‍💼',
      },
    ],
    'YESTERDAY, OCT 23': [
      {
        'icon': Icons.movie,
        'iconColor': Colors.red.shade100,
        'iconColorBg': const Color(0xFFF44336),
        'title': 'AMC Theatres',
        'category': 'Entertainment',
        'time': '7:45 PM',
        'amount': -32.00,
        'avatar': '👩‍🎤',
      },
      {
        'icon': Icons.wallet,
        'iconColor': Colors.green.shade100,
        'iconColorBg': const Color(0xFF4CAF50),
        'title': 'Venmo Transfer',
        'category': 'Income',
        'time': '1:00 PM',
        'amount': 50.00,
        'avatar': '👨‍🎓',
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Family Budget',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        leading: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: context.dripTheme.primaryColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.account_balance_wallet,
              color: context.dripTheme.primaryColor, size: 20),
        ),
      ),
      body: Column(
        children: [
          // Transactions Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Icon(Icons.tune, color: Colors.grey.shade700, size: 24),
                ),
              ],
            ),
          ),

          // Category Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  _categories.length,
                  (index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = category);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.dripTheme.primaryColor
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Date Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today,
                      color: Colors.grey.shade600, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDateFilter,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Transactions List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _transactionsByDate.length,
              itemBuilder: (context, dateIndex) {
                final dateKey =
                    _transactionsByDate.keys.toList()[dateIndex];
                final transactions = _transactionsByDate[dateKey]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Header
                    Text(
                      dateKey,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Transactions for this date
                    ...List.generate(
                      transactions.length,
                      (txIndex) {
                        final tx = transactions[txIndex];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.grey.shade200, width: 1),
                            ),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: tx['iconColor'] as Color,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      tx['icon'] as IconData,
                                      color: tx['iconColorBg'] as Color,
                                      size: 28,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx['title'] as String,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${tx['category']} • ${tx['time']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Amount
                                Text(
                                  tx['amount'] >= 0
                                      ? '+\$${tx['amount'].abs().toStringAsFixed(2)}'
                                      : '-\$${tx['amount'].abs().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: tx['amount'] >= 0
                                        ? Colors.green.shade600
                                        : Colors.red.shade600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Avatar
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.grey.shade300,
                                  child: Text(
                                    tx['avatar'] as String,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}