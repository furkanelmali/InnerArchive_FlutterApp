import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/enums/media_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../media/models/media_item.dart';
import '../../media/providers/media_provider.dart';
import '../../media/providers/stats_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/screens/collection_type_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _picker = ImagePicker();

  Future<void> _pickAvatar() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (xFile == null) return;
    await ref.read(profileProvider.notifier).uploadAvatar(File(xFile.path));
  }

  void _editField(String label, String? current, ValueChanged<String> onSave) {
    final controller = TextEditingController(text: current ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Edit $label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: label == 'Bio' ? 3 : 1,
          decoration: InputDecoration(hintText: 'Enter $label'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final stats = ref.watch(statsProvider);
    final itemsAsync = ref.watch(mediaProvider);
    final allItems = itemsAsync.asData?.value ?? [];
    final theme = Theme.of(context);

    // Get current user for provider info
    final currentUser = Supabase.instance.client.auth.currentUser;
    final provider = currentUser?.appMetadata['provider'] as String? ?? 'email';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(20),
        children: [
          // Section 1: Identity
          profileAsync.when(
            loading: () => _shimmer(height: 100),
            error: (_, _) => const SizedBox.shrink(),
            data: (profile) {
              if (profile == null) return const SizedBox.shrink();
              return _IdentityCard(
                profile: profile,
                provider: provider,
                email: currentUser?.email,
                onAvatarTap: _pickAvatar,
                onNameTap: () => _editField(
                  'Display Name',
                  profile.displayName,
                  (v) => ref
                      .read(profileProvider.notifier)
                      .updateProfile(displayName: v),
                ),
                onBioTap: () => _editField(
                  'Bio',
                  profile.bio,
                  (v) => ref
                      .read(profileProvider.notifier)
                      .updateProfile(bio: v),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Section 1.5: Quick stats
          _QuickStats(stats: stats),

          const SizedBox(height: 28),

          // Section 2: Media type collection
          Text('My Collection', style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 16),

          ...MediaType.values.map((type) {
            final ofType = allItems.where((e) => e.type == type).toList();
            return _CollectionTypeCard(
              type: type,
              items: ofType,
            );
          }),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _shimmer({double height = 80}) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceLight,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Identity card
// ─────────────────────────────────────────────────

class _IdentityCard extends StatelessWidget {
  final dynamic profile;
  final String provider;
  final String? email;
  final VoidCallback onAvatarTap;
  final VoidCallback onNameTap;
  final VoidCallback onBioTap;

  const _IdentityCard({
    required this.profile,
    required this.provider,
    this.email,
    required this.onAvatarTap,
    required this.onNameTap,
    required this.onBioTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary,
                  backgroundImage: profile.avatarUrl != null
                      ? CachedNetworkImageProvider(profile.avatarUrl!)
                      : null,
                  child: profile.avatarUrl == null
                      ? const Icon(Icons.person, color: Colors.white, size: 28)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.background, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onNameTap,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.displayName ?? profile.username,
                          style: theme.textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit,
                          size: 14, color: AppColors.textTertiary),
                    ],
                  ),
                ),
                Row(
                  children: [
                     Icon(
                      provider == 'google' ? Icons.g_mobiledata 
                      : provider == 'apple' ? Icons.apple 
                      : Icons.email_outlined,
                      size: 14,
                      color: AppColors.textTertiary,
                     ),
                     const SizedBox(width: 4),
                     Text(
                        email ?? '@${profile.username}',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                  ],
                ),
                GestureDetector(
                  onTap: onBioTap,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      profile.bio != null && profile.bio!.isNotEmpty
                          ? profile.bio!
                          : '+ Add bio',
                      style: TextStyle(
                        color: profile.bio != null && profile.bio!.isNotEmpty
                            ? AppColors.textSecondary
                            : AppColors.primary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Quick stats row
// ─────────────────────────────────────────────────

class _QuickStats extends StatelessWidget {
  final MediaStats stats;
  const _QuickStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(theme, '${stats.totalItems}', 'Total'),
          _stat(theme, '${stats.completedCount}', 'Done'),
          _stat(theme, '${stats.inProgressCount}', 'Active'),
          _stat(theme,
              stats.averageRating > 0
                  ? stats.averageRating.toStringAsFixed(1)
                  : '—',
              'Avg'),
        ],
      ),
    );
  }

  Widget _stat(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.primaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
// Collection type card — shows top 5 posters + navigates
// ─────────────────────────────────────────────────

class _CollectionTypeCard extends StatelessWidget {
  final MediaType type;
  final List<MediaItem> items;
  const _CollectionTypeCard({required this.type, required this.items});

  IconData _typeIcon(MediaType t) {
    switch (t) {
      case MediaType.movie:
        return Icons.movie_outlined;
      case MediaType.tv:
        return Icons.tv_outlined;
      case MediaType.anime:
        return Icons.animation_outlined;
      case MediaType.book:
        return Icons.menu_book_outlined;
      case MediaType.game:
        return Icons.sports_esports_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CollectionTypeScreen(type: type),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_typeIcon(type),
                    size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Text(
                  type.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${items.length}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textTertiary),
              ],
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.take(6).length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        child: item.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: item.imageUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => Container(
                                    color: AppColors.surfaceLight),
                                errorWidget: (_, _, _) => Container(
                                    color: AppColors.surfaceLight),
                              )
                            : Container(
                                color: AppColors.surfaceLight,
                                child: const Icon(Icons.image_outlined,
                                    size: 20, color: AppColors.textTertiary),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
