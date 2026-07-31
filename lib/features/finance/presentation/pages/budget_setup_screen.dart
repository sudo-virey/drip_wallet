import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_state.dart';
import 'package:drip_wallet/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:drip_wallet/features/finance/presentation/bloc/finance_event.dart';
import 'package:drip_wallet/features/finance/presentation/bloc/finance_state.dart';
import 'package:drip_ui/drip_ui.dart';

class BudgetSetupScreen extends StatefulWidget {
  final DateTime? initialMonth;

  const BudgetSetupScreen({
    super.key,
    this.initialMonth,
  });

  @override
  State<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen> {
  late DateTime _selectedMonth;
  late DripFormController _formController;
  double _budgetLimit = 0;
  bool _isEditingPastMonth = false;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialMonth ?? DateTime.now();
    _formController = DripFormController();
    _checkIfPastMonth();
  }

  @override
  void dispose() {
    _formController.dispose();
    super.dispose();
  }

  void _checkIfPastMonth() {
    final now = DateTime.now();
    final isCurrentOrFuture = _selectedMonth.year > now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month >= now.month);
    setState(() {
      _isEditingPastMonth = !isCurrentOrFuture;
    });
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _checkIfPastMonth();
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      _checkIfPastMonth();
    });
  }

  void _saveBudget() {
    final budgetText = _formController.getTextController('budget_limit').text;
    _budgetLimit = double.tryParse(budgetText) ?? 0;

    if (_budgetLimit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un límite de gasto válido')),
      );
      return;
    }

    if (_isEditingPastMonth) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pueden editar presupuestos de meses pasados')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<FinanceBloc>().add(
        SetMonthlyBudget(
          profileId: authState.user.id,
          monthYear: _selectedMonth,
          budgetLimit: _budgetLimit,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dripTheme = Theme.of(context).extension<DripThemeExtension>() ?? DripThemeExtension.light();
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Configurar Presupuesto',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: BlocListener<FinanceBloc, FinanceState>(
        listener: (context, state) {
          if (state is BudgetSet) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.pop(context);
          } else if (state is FinanceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }
        },
        child: BlocBuilder<FinanceBloc, FinanceState>(
          builder: (context, state) {
            final isLoading = state is FinanceLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthSelector(context, dripTheme),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'Límite de Gasto'),
                  const SizedBox(height: 12),
                  DripTextField(
                    id: 'budget_limit',
                    controller: _formController,
                    hintText: '0.00',
                    label: 'Presupuesto de Gasto',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 32),
                  if (_isEditingPastMonth) _buildWarning(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: DripButton(
                      onPressed: (_isEditingPastMonth || isLoading) ? () {} : _saveBudget,
                      label: isLoading ? 'Guardando...' : 'Guardar Presupuesto',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, DripThemeExtension dripTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dripTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousMonth,
              ),
              Text(
                '${_monthName(_selectedMonth.month)} ${_selectedMonth.year}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
              ),
            ],
          ),
          if (_isEditingPastMonth)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Este mes ya pasó',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        border: Border.all(color: Theme.of(context).colorScheme.tertiary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Theme.of(context).colorScheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No se pueden editar presupuestos de meses pasados',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return months[month - 1];
  }
}
