import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drip_ui/drip_ui.dart';
import 'package:drip_wallet/core/theme/drip_theme_helper.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_event.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_state.dart';
import 'package:drip_wallet/features/finance/data/datasources/finance_remote_datasource.dart';
import 'package:drip_wallet/features/finance/finance_exports.dart';
import 'package:drip_wallet/features/profile/data/repositories/profile_repository.dart';
import 'package:drip_wallet/injection_container.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileRepository _profileRepo;
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _profileRepo = ProfileRepository(
      client: Supabase.instance.client,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      try {
        final data = await _profileRepo.getProfile(authState.user.id);
        if (mounted) {
          setState(() {
            _profileData = data;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          context.go('/login');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logout failed: ${state.message}')),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading || _isLoading) {
            return Scaffold(
              backgroundColor: context.dripBackground,
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            backgroundColor: context.dripBackground,
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildProfileHeader(),
                    const SizedBox(height: 40),
                    _buildFamilySection(),
                    const SizedBox(height: 32),
                    _buildLogoutButton(),
                    const SizedBox(height: 16),
                    const Text(
                      'Drip Wallet v1.0.0',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _profileData?['name'] ?? 'Usuario';
    final email = _profileData?['email'] ?? '';

    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.dripPrimary,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                backgroundColor: context.dripInputBackground,
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: context.dripPrimary,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.dripPrimary,
                  border: Border.all(color: context.dripBackground, width: 2),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (email.isNotEmpty)
          Text(
            email,
            style: TextStyle(color: context.dripHint),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: context.dripPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.dripPrimary, width: 1),
          ),
          child: Text(
            'Primary Member',
            style: TextStyle(
              color: context.dripPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.dripLabel,
          ),
        ),
      ),
    );
  }

  Widget _buildFamilySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Familia'),
        _buildInviteButton(),
      ],
    );
  }









  Widget _buildInviteButton() {
    return GestureDetector(
      onTap: _showBudgetSharingDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: context.dripPrimary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_outlined, color: context.dripPrimary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Compartir presupuesto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.dripPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBudgetSharingDialog() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final financeDatasource = getIt<FinanceRemoteDataSource>();
    Map<String, dynamic>? family;

    try {
      family = await financeDatasource.getBudgetFamilyForProfile(authState.user.id);
    } catch (_) {
      family = null;
    }

    if (!mounted) return;

    final inviteCodeController = TextEditingController();

    Future<void> _refreshFinanceData() async {
      if (!mounted) return;

      final financeBloc = context.read<FinanceBloc>();
      financeBloc.add(LoadDashboard(authState.user.id));
      financeBloc.add(
        LoadHistoryForMonth(
          profileId: authState.user.id,
          month: DateTime.now(),
        ),
      );
    }

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final inviteCode = family?['invite_code'] as String? ?? '';

            Future<void> createFamily() async {
              try {
                final created = await financeDatasource.createBudgetFamily(authState.user.id);
                family = created;
                await Clipboard.setData(ClipboardData(text: created['invite_code'] as String));
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Código creado y copiado: ${created['invite_code']}')),
                  );
                }
                setDialogState(() {});
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }

              await _refreshFinanceData();
            }

            Future<void> joinFamily() async {
              final code = inviteCodeController.text.trim();
              if (code.isEmpty) return;

              try {
                await financeDatasource.joinBudgetFamily(authState.user.id, code);
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Te uniste al presupuesto compartido')),
                  );
                }
                if (Navigator.of(dialogContext).canPop()) {
                  Navigator.pop(dialogContext);
                }
                await _refreshFinanceData();
                if (mounted) {
                  context.go('/home');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            }

            return AlertDialog(
              title: const Text('Compartir presupuesto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    family != null
                        ? 'Este es el código que debes compartir con tu familiar.'
                        : 'Crea un grupo para compartir el mismo presupuesto con un familiar.',
                  ),
                  const SizedBox(height: 16),
                  if (family != null) ...[
                    SelectableText(
                      inviteCode,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () async {
                        final code = inviteCode;
                        if (code.isEmpty) return;
                        await Clipboard.setData(ClipboardData(text: code));
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Código copiado')),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar código'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: inviteCodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Código de invitación',
                      hintText: 'ABC123',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cerrar'),
                ),
                if (family == null)
                  TextButton(
                    onPressed: createFamily,
                    child: const Text('Crear grupo'),
                  ),
                TextButton(
                  onPressed: joinFamily,
                  child: const Text('Unirme'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DripButton(
        onPressed: () {
          _showLogoutDialog();
        },
        label: 'Cerrar Sesión',
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthBloc>().add(AuthSignOutRequested());
              },
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }
}