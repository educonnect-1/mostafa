import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/connectivity_service.dart';
import '../theme/app_theme.dart';

/// A slim, non-blocking banner shown above whatever screen is current
/// when the device has no connection at all. Never blocks interaction
/// — screens still show their own cached-nothing/error states per
/// spec §32/§33 when a specific action actually needs the network.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOfflineProvider);
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: offline
          ? Container(
              width: double.infinity,
              color: AppBrand.danger,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.wifi_off, size: 14, color: Colors.white),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      'No internet connection',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
