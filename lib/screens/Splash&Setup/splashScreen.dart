import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../commonWidgets/textWidget.dart';
import '../../core/di/injection.dart';
import '../../core/services/app_state_service.dart';
import '../../generated/assets.dart';
import '../../l10n/l10n.dart';
import '../../themes/font.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _textOpacity;
  late Animation<double> _logoOpacity;
  late Animation<double> _textPosition;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen();
      }
    });

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.ease),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.5, curve: Curves.easeIn),
      ),
    );

    _textPosition = Tween<double>(begin: 24.0, end: 80.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      _controller.forward();
    });
  }

  /// Check actual runtime permission status
  Future<bool> _checkRuntimePermissions() async {
    if (Platform.isIOS) {
      return true; // iOS doesn't need explicit permission for media library
    }

    // Check actual runtime permission status
    final storageGranted = await Permission.storage.isGranted;
    final audioGranted = await Permission.audio.isGranted;

    return storageGranted || audioGranted;
  }

  /// Determines the next screen based on app state
  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    // For iOS devices, skip permission and sync screens and go directly to dashboard
    if (Platform.isIOS) {
      if (mounted) context.go('/dashboard');
      return;
    }

    // Android-specific navigation flow
    final appStateService = locator<AppStateService>();

    // Check if sync has been completed
    // final syncCompleted = await appStateService.isSyncCompleted();
    // if (syncCompleted) {
    //   if (mounted) context.go('/dashboard');
    //   return;
    // }

    // Verify actual runtime permissions (not just stored flag)
    final hasRuntimePermission = await _checkRuntimePermissions();

    // Check stored permission flag
    final permissionGranted = await appStateService.isPermissionGranted();

    // If stored flag says granted but runtime permission is not actually granted,
    // reset the flag and go to permission screen
    if (permissionGranted && !hasRuntimePermission) {
      await appStateService.setPermissionGranted(false);
      if (mounted) context.go('/permission');
      return;
    }

    // If runtime permission is actually granted, proceed to sync
    if (hasRuntimePermission) {
      // Update stored flag if it's not set
      if (!permissionGranted) {
        await appStateService.setPermissionGranted(true);
      }
      // Permission granted but sync not completed, go to sync
      if (mounted) context.go('/sync');
      return;
    }

    // No permission yet, go to permission screen
    if (mounted) context.go('/permission');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return SizedBox(
              height: 400.h,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      alignment: Alignment.center,
                      scale: _logoScale.value,
                      child: Image.asset(
                        Assets.pngLogo,
                        height: 113.h,
                        width: 113.w,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: _textPosition.value,
                    child: Opacity(
                      opacity: _textOpacity.value,
                      child: Texts(
                        S.of(context).musicPlayer,
                        fontSize: 24.sp,
                        fontFamily: AppFonts.manrope,
                        fontWeight: AppFontWeights.semiBold,
                        color: Colors.black87,
                      ),
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
}
