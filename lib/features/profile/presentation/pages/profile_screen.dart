import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drip_ui/drip_ui.dart';
import 'package:drip_wallet/core/theme/drip_theme_helper.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_event.dart';
import 'package:drip_wallet/features/auth/presentation/bloc/auth_state.dart';
import 'package:drip_wallet/features/profile/data/repositories/profile_repository.dart';
import 'package:go_router/go_router.dart';
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
  bool _notificationsEnabled = true;
  bool _lightModeEnabled = false;

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
                    _buildAccountSection(),
                    const SizedBox(height: 24),
                    _buildFamilySection(),
                    const SizedBox(height: 24),
                    _buildAppSettingsSection(),
                    const SizedBox(height: 24),
                    _buildSupportSection(),
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

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Cuenta'),
        _buildMenuOption('Información Personal', Icons.person_outline),
        const SizedBox(height: 12),
        _buildMenuOption('Seguridad', Icons.shield_outlined),
        const SizedBox(height: 12),
        _buildMenuOption('Cuentas Bancarias Vinculadas', Icons.account_balance_outlined),
      ],
    );
  }

  Widget _buildFamilySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Familia'),
        _buildMenuOption('Miembros de la Familia', Icons.people_outline),
        const SizedBox(height: 12),
        _buildInviteButton(),
        const SizedBox(height: 12),
        _buildMenuOption('Límites de Presupuesto', Icons.trending_up_outlined),
      ],
    );
  }

  Widget _buildAppSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Configuración de la Aplicación'),
        _buildToggleOption(
          'Notificaciones',
          Icons.notifications_outlined,
          _notificationsEnabled,
          (value) {
            setState(() => _notificationsEnabled = value);
          },
        ),
        const SizedBox(height: 12),
        _buildToggleOption(
          'Modo Claro',
          Icons.light_mode_outlined,
          _lightModeEnabled,
          (value) {
            setState(() => _lightModeEnabled = value);
          },
        ),
        const SizedBox(height: 12),
        _buildMenuOption('Moneda', Icons.attach_money_outlined, showValue: 'USD (\\\$)'),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Soporte'),
        _buildMenuOption('Centro de Ayuda', Icons.help_outline),
        const SizedBox(height: 12),
        _buildMenuOption('Política de Privacidad', Icons.privacy_tip_outlined),
      ],
    );
  }

  Widget _buildMenuOption(
    String title,
    IconData icon, {
    String? showValue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.dripInputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.dripInputBackground,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.dripPrimary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          if (showValue != null)
            Text(
              showValue,
              style: TextStyle(
                fontSize: 14,
                color: context.dripHint,
              ),
            ),
          if (showValue == null)
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: context.dripHint,
            ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.dripInputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.dripInputBackground,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.dripPrimary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: context.dripPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildInviteButton() {
    return GestureDetector(
      onTap: () {},
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
              'Invitar a la Familia',
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