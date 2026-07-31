import 'package:flutter/material.dart';
import 'package:drip_wallet/core/utils/icon_converter.dart';

/// Botón selector de tipo de transacción (Gasto/Ingreso)
class TransactionTypeButton extends StatelessWidget {
  final String type; // 'expense' o 'income'
  final String selectedType;
  final VoidCallback onTap;
  final String label;

  const TransactionTypeButton({
    super.key,
    required this.type,
    required this.selectedType,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedType == type;
    final isExpense = type == 'expense';
    final theme = Theme.of(context);
    final expenseColor = theme.colorScheme.error;
    final incomeColor = theme.colorScheme.secondary;
    final backgroundColor = theme.colorScheme.surfaceVariant;
    final foregroundColor = theme.colorScheme.onSurface;
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isExpense ? expenseColor : incomeColor)
                : backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isExpense ? Icons.trending_down : Icons.trending_up,
                color: isSelected ? Colors.white : foregroundColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : foregroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Input de monto centrado con $ símbolo
class AmountInput extends StatelessWidget {
  final TextEditingController controller;
  final ThemeData theme;

  const AmountInput({
    super.key,
    required this.controller,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            'MONTO',
            style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '\$',
                style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              ),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Grid de categorías con selección
class CategoryGrid extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String selectedCategory;
  final String transactionType; // 'expense' o 'income'
  final Function(String) onCategorySelected;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.transactionType,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseColor = theme.colorScheme.error;
    final incomeColor = theme.colorScheme.secondary;
    final surfaceColor = theme.colorScheme.surfaceContainerHighest;
    final borderColor = theme.colorScheme.outlineVariant;
    final textColor = theme.colorScheme.onSurface;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = selectedCategory == category['name'];
        final isIncome = transactionType == 'income';
        final selectedColor = isIncome ? incomeColor : expenseColor;

        return GestureDetector(
          onTap: () => onCategorySelected(category['name'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? selectedColor
                  : surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? selectedColor
                    : borderColor,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  stringToIconData(category['icon'] as String? ?? 'category'),
                  size: 28,
                  color: isSelected ? Colors.white : textColor,
                ),
                const SizedBox(height: 8),
                Text(
                  category['name'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Selector de fecha
class DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;
  final ThemeData theme;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              style: theme.textTheme.bodyMedium,
            ),
            Icon(
              Icons.calendar_today,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón de guardar con color dinámico
class StyledSaveButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final String transactionType; // 'expense' o 'income'
  final ThemeData theme;

  const StyledSaveButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.transactionType,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transactionType == 'income';
    final colorScheme = theme.colorScheme;
    final buttonColor = isIncome ? colorScheme.secondary : colorScheme.error;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}

/// Campo de descripción reutilizable
class DescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const DescriptionField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
    );
  }
}

/// Sección label con título
class FormSectionLabel extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const FormSectionLabel({
    super.key,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

/// Header modal reutilizable
class ModalHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;
  final VoidCallback onClose;

  const ModalHeader({
    super.key,
    required this.title,
    required this.theme,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Icon(
              Icons.close,
              size: 28,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
