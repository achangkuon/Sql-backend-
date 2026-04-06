import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../providers/preferences_providers.dart';
import '../../data/repositories/profile_repository.dart';

/// Profile screen for the Tasker showing avatar, stats, skills, menu, and logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final taskerDataAsync = ref.watch(taskerProfileDataProvider);
    final skillsAsync = ref.watch(taskerSkillsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'ST',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('ServiTask', style: AppTypography.bodyMD),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: AppColors.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          children: [
            // ── Profile Header ──────────────────────────────────────
            profileAsync.when(
              data: (profile) {
                if (profile == null) {
                  return const SizedBox.shrink();
                }

                final initials = _getInitials(profile.fullName);

                return Column(
                  children: [
                    const SizedBox(height: 12),

                    // Avatar circle
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          width: 3,
                        ),
                      ),
                      child: profile.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                profile.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, _) =>
                                    _buildInitialsAvatar(initials),
                              ),
                            )
                          : _buildInitialsAvatar(initials),
                    ),

                    const SizedBox(height: 12),

                    // Name
                    Text(profile.fullName, style: AppTypography.headline),
                    const SizedBox(height: 4),

                    // Email
                    Text(
                      profile.email,
                      style: AppTypography.bodySM
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),

                    const SizedBox(height: 12),

                    // Online toggle row
                    _OnlineToggle(isOnline: profile.isOnline),

                    const SizedBox(height: 12),

                    // Badges (Verified + Tier)
                    taskerDataAsync.when(
                      data: (taskerData) => _buildBadgesRow(taskerData),
                      loading: () => const SizedBox(height: 24),
                      error: (e, _) => const SizedBox.shrink(),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) =>
                  Center(child: Text('Error al cargar perfil: $e')),
            ),

            const SizedBox(height: 24),

            // ── Stats Row ───────────────────────────────────────────
            taskerDataAsync.when(
              data: (taskerData) {
                if (taskerData == null) return const SizedBox.shrink();
                return _buildStatsRow(
                  tasks: taskerData.totalTasksCompleted,
                  rating: taskerData.averageRating,
                  earnings: taskerData.totalEarnings,
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // ── Mis Habilidades ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mis Habilidades', style: AppTypography.headline),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    '+ Agregar',
                    style: AppTypography.labelSM
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            skillsAsync.when(
              data: (skills) {
                if (skills.isEmpty) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Aún no has agregado habilidades.',
                      style: AppTypography.bodySM
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  );
                }
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills
                        .map((s) => _buildSkillChip(s.name))
                        .toList(),
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 32,
                child: Center(child: LinearProgressIndicator()),
              ),
              error: (e, _) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // ── Menu Items ──────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                      Icons.folder_outlined, 'Mis documentos', false),
                  _buildMenuDivider(),
                  _buildMenuItem(
                      Icons.credit_card_outlined, 'Datos de pago', false),
                  _buildMenuDivider(),
                  _buildMenuItem(
                      Icons.notifications_none_rounded, 'Notificaciones', true),
                  _buildMenuDivider(),
                  _buildMenuItem(
                      Icons.star_outline_rounded, 'Mis reseñas', false),
                  _buildMenuDivider(),
                  _buildMenuItem(
                      Icons.shield_outlined, 'Seguridad y Ayuda', false),
                  _buildMenuDivider(),
                  _buildMenuItem(
                      Icons.help_outline_rounded, 'Ayuda', false),
                  _buildMenuDivider(),
                  _buildMenuItem(
                      Icons.settings_outlined, 'Ajustes', false),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Logout Button ───────────────────────────────────────
            GestureDetector(
              onTap: () => _confirmSignOut(context, ref),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Cerrar sesión',
                      style: AppTypography.bodyMD
                          .copyWith(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────

  /// Renders initials in the avatar placeholder.
  Widget _buildInitialsAvatar(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 26,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Verified + Tier badges row.
  Widget _buildBadgesRow(TaskerProfileData? data) {
    final isVerified = data?.verificationStatus == 'verified';
    final tier = data?.tier.toUpperCase() ?? 'NEW';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isVerified)
          _buildBadge(
            label: 'Verificado',
            color: AppColors.primary,
            icon: Icons.verified_rounded,
          ),
        if (isVerified) const SizedBox(width: 8),
        _buildBadge(
          label: tier,
          color: tier == 'PLATINUM' ? AppColors.primaryDark : AppColors.primary,
          icon: tier == 'PLATINUM' ? Icons.star_rounded : null,
        ),
      ],
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.labelSM.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  /// Horizontal stats row: Trabajos · Rating · Ganancias.
  Widget _buildStatsRow({
    required int tasks,
    required double rating,
    required double earnings,
  }) {
    // Format earnings: e.g. 15400 → $15.4k
    final String earningsLabel = earnings >= 1000
        ? '\$${(earnings / 1000).toStringAsFixed(1)}k'
        : '\$${earnings.toStringAsFixed(0)}';

    return Row(
      children: [
        Expanded(
            child: _buildStatItem(tasks.toString(), 'TRABAJOS')),
        _buildStatSeparator(),
        Expanded(
            child: _buildStatItem(rating.toStringAsFixed(1), 'RATING')),
        _buildStatSeparator(),
        Expanded(child: _buildStatItem(earningsLabel, 'GANADO')),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headline
              .copyWith(color: AppColors.onSurface, fontSize: 22),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSM
              .copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 0.8),
        ),
      ],
    );
  }

  Widget _buildStatSeparator() {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.surfaceContainerHighest,
    );
  }

  /// Skill chip with blue text on light blue background.
  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.labelSM.copyWith(color: AppColors.primary),
      ),
    );
  }

  /// Single menu row item.
  Widget _buildMenuItem(IconData icon, String label, bool hasDot) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: AppTypography.bodyMD),
          ),
          if (hasDot)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.onSurfaceVariant, size: 20),
        ],
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.surfaceContainerHigh,
    );
  }

  /// Extracts up to 2 uppercase initials from a full name.
  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  /// Shows a confirmation dialog before signing out.
  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cerrar sesión', style: AppTypography.headline),
        content: Text(
          '¿Estás seguro de que deseas cerrar la sesión?',
          style: AppTypography.bodyMD,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar',
                style: AppTypography.bodyMD
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Cerrar sesión',
                style: AppTypography.bodyMD.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }
}

// ── Online Toggle Sub-widget ───────────────────────────────────────────────

/// Reactive online status toggle connected to Supabase.
class _OnlineToggle extends ConsumerWidget {
  final bool isOnline;
  const _OnlineToggle({required this.isOnline});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-watch the online state from preferences provider if available,
    // otherwise use the profile value passed in.
    final onlineState = ref.watch(taskerOnlineStatusProvider);
    final effectiveOnline = onlineState.value ?? isOnline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          effectiveOnline ? 'EN LÍNEA' : 'FUERA DE LÍNEA',
          style: AppTypography.labelSM.copyWith(
            color: effectiveOnline ? AppColors.success : AppColors.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: effectiveOnline,
          activeThumbColor: AppColors.success,
          onChanged: (val) {
            ref
                .read(taskerOnlineStatusProvider.notifier)
                .toggleOnlineStatus(val);
          },
        ),
      ],
    );
  }
}



