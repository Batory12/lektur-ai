import 'package:flutter/material.dart';
import 'package:lekturai_front/services/profile_service.dart';
import 'package:lekturai_front/theme/colors.dart';
import 'package:lekturai_front/theme/spacing.dart';
import 'package:lekturai_front/theme/text_styles.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showDrawerIcon;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.showDrawerIcon = true,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  final ProfileService _profileService = ProfileService();
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      UserProfile? profile = await _profileService.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    final hasDrawer = scaffold?.hasDrawer ?? false;
    final bool shouldShowLeading = widget.showBackButton || (widget.showDrawerIcon && hasDrawer);
    
    return AppBar(
      automaticallyImplyLeading: shouldShowLeading,
      title: Text(
        widget.title,
        style: AppTextStyles.heading3.copyWith(color: AppColors.white),
      ),
      centerTitle: true,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
      actions: [
        // Wallet Balance
        if (!_isLoading && _userProfile != null)
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  size: 18,
                  color: AppColors.white,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${_userProfile!.balance}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: AppSpacing.sm),
        
        // User Avatar
        if (!_isLoading && _userProfile != null)
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.lg),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.white,
                child: Text(
                  _userProfile!.displayName.isNotEmpty
                      ? _userProfile!.displayName[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        
        // Loading indicator
        if (_isLoading)
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.lg),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            ),
          ),
      ],
    );
  }
}
