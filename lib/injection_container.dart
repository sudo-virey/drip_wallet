import 'package:drip_wallet/features/auth/data/repositories/auth_repository.dart';
import 'package:drip_wallet/features/finance/finance_exports.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drip_wallet/features/auth/data/repositories/auth_repository_impl.dart';

final getIt = GetIt.instance;

Future<void> setup() async {
  // 1. Registrar Supabase (es necesario para que el repositorio funcione)
  final supabase = await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY']!,
  );
  
  // Registramos el cliente para poder inyectarlo después
  getIt.registerSingleton<SupabaseClient>(supabase.client);

  // 2. Registrar el Repositorio de Auth
  // Usamos LazySingleton para que se cree solo cuando se use por primera vez
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<SupabaseClient>()),
  );

  // 3. Registrar Finance Remote DataSource
  getIt.registerLazySingleton<FinanceRemoteDataSource>(
    () => FinanceRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );

  // 4. Registrar Finance Repository
  getIt.registerLazySingleton<FinanceRepository>(
    () => FinanceRepositoryImpl(getIt<FinanceRemoteDataSource>()),
  );

  // 5. Registrar Finance BLoC
  getIt.registerLazySingleton<FinanceBloc>(
    () => FinanceBloc(getIt<FinanceRepository>()),
  );
}