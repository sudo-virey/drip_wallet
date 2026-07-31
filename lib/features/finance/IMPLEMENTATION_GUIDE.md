/// # Finance Module - Clean Architecture Implementation
///
/// Esta carpeta contiene la implementación completa del módulo de Finanzas
/// siguiendo Clean Architecture con manejo de errores usando Either<Failure, T>.
///
/// ## Estructura de Carpetas
///
/// ```
/// finance/
/// ├── domain/                          # Capa de Dominio (Lógica de negocio)
/// │   ├── entities/
/// │   │   └── dashboard_entity.dart     # Entidades del negocio
/// │   └── repositories/
/// │       └── finance_repository.dart   # Interfaz del repositorio
/// │
/// ├── data/                            # Capa de Datos
/// │   ├── datasources/
/// │   │   └── finance_remote_datasource.dart  # Conexión a Supabase
/// │   ├── models/
/// │   │   └── dashboard_model.dart     # Modelos (extienden entidades)
/// │   └── repositories/
/// │       └── finance_repository_impl.dart    # Implementación del repositorio
/// │
/// ├── presentation/                    # Capa de Presentación
/// │   └── bloc/
/// │       ├── finance_bloc.dart        # BLoC principal
/// │       ├── finance_event.dart       # Eventos
/// │       └── finance_state.dart       # Estados
/// │
/// └── finance_exports.dart             # Exportaciones centralizadas
/// ```
///
/// ## Cómo Usar
///
/// ### 1. Registrar en Injection Container
///
/// ```dart
/// // lib/injection_container.dart
/// import 'package:drip_wallet/features/finance/finance_exports.dart';
///
/// final getIt = GetIt.instance;
///
/// Future<void> setupServiceLocator() async {
///   // ... otros servicios ...
///
///   // Finance Remote DataSource
///   getIt.registerSingleton<FinanceRemoteDataSource>(
///     FinanceRemoteDataSourceImpl(getIt<SupabaseClient>()),
///   );
///
///   // Finance Repository
///   getIt.registerSingleton<FinanceRepository>(
///     FinanceRepositoryImpl(getIt<FinanceRemoteDataSource>()),
///   );
///
///   // Finance BLoC
///   getIt.registerSingleton<FinanceBloc>(
///     FinanceBloc(getIt<FinanceRepository>()),
///   );
/// }
/// ```
///
/// ### 2. Usar en una Pantalla
///
/// ```dart
/// class HomeScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return BlocListener<AuthBloc, AuthState>(
///       listener: (context, authState) {
///         if (authState is Authenticated) {
///           // Cargar dashboard cuando el usuario inicia sesión
///           context.read<FinanceBloc>().add(
///             LoadDashboard(authState.user.id),
///           );
///         }
///       },
///       child: BlocBuilder<FinanceBloc, FinanceState>(
///         builder: (context, state) {
///           if (state is FinanceLoading) {
///             return const Center(child: CircularProgressIndicator());
///           } else if (state is DashboardLoaded) {
///             return Column(
///               children: [
///                 Text('Balance: \$${state.dashboard.balance}'),
///                 Text('Gastos: \$${state.dashboard.totalExpense}'),
///                 // ... resto de la UI
///               ],
///             );
///           } else if (state is FinanceError) {
///             return Center(child: Text('Error: ${state.message}'));
///           }
///           return const SizedBox.shrink();
///         },
///       ),
///     );
///   }
/// }
/// ```
///
/// ### 3. Agregar una Transacción
///
/// ```dart
/// // Desde un modal o formulario
/// context.read<FinanceBloc>().add(
///   AddTransaction(
///     profileId: userId,
///     transactionData: {
///       'title': 'Compra de groceries',
///       'category': 'Food',
///       'amount': 45.99,
///       'type': 'expense',
///       'date': DateTime.now(),
///       'description': 'Compra en el supermercado',
///     },
///   ),
/// );
/// ```
///
/// ## Manejo de Errores
///
/// Todos los métodos retornan `Either<Failure, T>`:
/// - **Left(Failure)**: Error en la operación
/// - **Right(T)**: Operación exitosa con los datos
///
/// ```dart
/// // El BLoC automáticamente maneja los errores:
/// result.fold(
///   (failure) => emit(FinanceError(failure.message)),  // Error
///   (data) => emit(DashboardLoaded(data)),              // Éxito
/// );
/// ```
///
/// ## Entidades Principales
///
/// ### DashboardEntity
/// ```dart
/// - totalIncome: double      // Total de ingresos
/// - totalExpense: double     // Total de gastos
/// - balance: double          // Balance = ingresos - gastos
/// - budgetLimit: double      // Límite de presupuesto
/// - recentTransactions: List<TransactionEntity>
/// ```
///
/// ### TransactionEntity
/// ```dart
/// - id: String
/// - title: String            // Título de la transacción
/// - category: String         // Categoría (Food, Transit, etc.)
/// - amount: double           // Monto
/// - date: DateTime           // Fecha
/// - type: String             // 'income' o 'expense'
/// - description: String?     // Descripción opcional
/// ```
///
/// ## Eventos del BLoC
///
/// 1. **LoadDashboard(profileId)**
///    - Carga el dashboard del usuario
///    - Emite: FinanceLoading → DashboardLoaded o FinanceError
///
/// 2. **AddTransaction(profileId, transactionData)**
///    - Agrega una nueva transacción
///    - Emite: FinanceLoading → TransactionAdded → DashboardLoaded
///
/// 3. **RefreshDashboard(profileId)**
///    - Refresca los datos del dashboard
///    - Útil después de agregar una transacción
///
/// ## Ejemplo Completo: Home Screen
///
/// ```dart
/// class HomeScreenState extends State<HomeScreen> {
///   @override
///   void initState() {
///     super.initState();
///     final authBloc = context.read<AuthBloc>();
///     if (authBloc.state is Authenticated) {
///       final userId = (authBloc.state as Authenticated).user.id;
///       context.read<FinanceBloc>().add(LoadDashboard(userId));
///     }
///   }
///
///   void _showAddExpenseModal() {
///     showModalBottomSheet(
///       context: context,
///       builder: (context) => NewExpenseModal(
///         onSave: (transactionData) {
///           final authState = context.read<AuthBloc>().state;
///           if (authState is Authenticated) {
///             context.read<FinanceBloc>().add(
///               AddTransaction(
///                 profileId: authState.user.id,
///                 transactionData: transactionData,
///               ),
///             );
///           }
///         },
///       ),
///     );
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: const Text('Family Budget')),
///       body: BlocBuilder<FinanceBloc, FinanceState>(
///         builder: (context, state) {
///           if (state is FinanceLoading) {
///             return const Center(child: CircularProgressIndicator());
///           } else if (state is DashboardLoaded) {
///             final dashboard = state.dashboard;
///             return Column(
///               children: [
///                 // Balance Card
///                 BalanceCard(dashboard: dashboard),
///                 // Recent Transactions
///                 RecentTransactionsList(
///                   transactions: dashboard.recentTransactions,
///                 ),
///               ],
///             );
///           } else if (state is FinanceError) {
///             return Center(
///               child: Text('Error: ${state.message}'),
///             );
///           }
///           return const SizedBox.shrink();
///         },
///       ),
///       floatingActionButton: FloatingActionButton(
///         onPressed: _showAddExpenseModal,
///         child: const Icon(Icons.add),
///       ),
///     );
///   }
/// }
/// ```
///
/// ## Cambios Necesarios en Supabase
///
/// Asegúrate de que tu base de datos tenga estas tablas:
///
/// ```sql
/// -- Tabla de dashboards
/// CREATE TABLE dashboards (
///   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
///   user_id UUID NOT NULL REFERENCES auth.users(id),
///   total_income DECIMAL(12, 2) DEFAULT 0,
///   total_expense DECIMAL(12, 2) DEFAULT 0,
///   balance DECIMAL(12, 2) DEFAULT 0,
///   budget_limit DECIMAL(12, 2) DEFAULT 5000,
///   created_at TIMESTAMP DEFAULT NOW(),
///   updated_at TIMESTAMP DEFAULT NOW(),
///   UNIQUE(user_id)
/// );
///
/// -- Tabla de transacciones
/// CREATE TABLE transactions (
///   id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
///   user_id UUID NOT NULL REFERENCES auth.users(id),
///   title VARCHAR(255) NOT NULL,
///   category VARCHAR(50) NOT NULL,
///   amount DECIMAL(12, 2) NOT NULL,
///   type VARCHAR(10) NOT NULL CHECK (type IN ('income', 'expense')),
///   description TEXT,
///   date TIMESTAMP NOT NULL,
///   created_at TIMESTAMP DEFAULT NOW()
/// );
///
/// -- Índices para mejor rendimiento
/// CREATE INDEX idx_transactions_user_id ON transactions(user_id);
/// CREATE INDEX idx_transactions_date ON transactions(date DESC);
/// ```
