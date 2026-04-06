import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/daily_activation_providers.dart';

// ── Geolocation provider ──────────────────────────────────────────────────────

/// Requests permission and returns the device's current [LatLng].
/// Falls back to Quito, Ecuador if location is unavailable.
final _locationProvider = FutureProvider<LatLng>((ref) async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever ||
      permission == LocationPermission.denied) {
    // Fallback: Quito, Ecuador
    return const LatLng(-0.1807, -78.4678);
  }

  try {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return LatLng(pos.latitude, pos.longitude);
  } catch (_) {
    // Fallback on timeout or unavailable GPS
    return const LatLng(-0.1807, -78.4678);
  }
});

// ── Screen ────────────────────────────────────────────────────────────────────

class WorkZoneScreen extends ConsumerStatefulWidget {
  const WorkZoneScreen({super.key});

  @override
  ConsumerState<WorkZoneScreen> createState() => _WorkZoneScreenState();
}

class _WorkZoneScreenState extends ConsumerState<WorkZoneScreen> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Animates the map to the user's position and adjusts zoom for [radiusKm].
  void _centerMapOnLocation(LatLng location, double radiusKm) {
    // Derive zoom from radius: larger radius → more zoomed out.
    // Empirically: 5 km ≈ zoom 12, 25 km ≈ zoom 10.
    final zoom = (13.5 - (radiusKm - 5) * 0.12).clamp(9.0, 14.0);
    _mapController.move(location, zoom);
  }

  @override
  Widget build(BuildContext context) {
    final radiusAsync = ref.watch(workZoneProvider);
    final locationAsync = ref.watch(_locationProvider);
    final radius = radiusAsync.asData?.value ?? 15.0;
    final isSaving = radiusAsync is AsyncLoading;

    // Determine the center: real GPS or fallback.
    final center = locationAsync.asData?.value ?? const LatLng(-0.1807, -78.4678);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.90),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Zona de trabajo',
          style: AppTypography.titleMD.copyWith(fontWeight: FontWeight.w500),
        ),
        actions: [
          // Re-center button
          if (locationAsync.hasValue)
            IconButton(
              tooltip: 'Mi ubicación',
              icon: const Icon(Icons.my_location_rounded,
                  color: AppColors.primary),
              onPressed: () => _centerMapOnLocation(center, radius),
            ),
        ],
      ),
      body: Stack(
        children: [
          // ── Real map ──────────────────────────────────────────────────────
          locationAsync.when(
            loading: () => const _MapPlaceholder(),
            error: (_, _) => _RealMap(
              center: const LatLng(-0.1807, -78.4678),
              radiusKm: radius,
              mapController: _mapController,
            ),
            data: (location) => _RealMap(
              center: location,
              radiusKm: radius,
              mapController: _mapController,
            ),
          ),

          // ── Loading overlay while fetching GPS ────────────────────────────
          if (locationAsync.isLoading)
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Text('Obteniendo ubicación…',
                          style: AppTypography.labelMD.copyWith(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),

          // ── Bottom config card ─────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PARÁMETROS',
                                style: AppTypography.labelMD.copyWith(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Radio de servicio',
                                style: AppTypography.headline
                                    .copyWith(fontSize: 20),
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                radius.toStringAsFixed(0),
                                style: AppTypography.headline.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 32,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  ' km',
                                  style: AppTypography.bodyMD
                                      .copyWith(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Slider
                      radiusAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (_) => Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor:
                                    AppColors.surfaceContainerHighest,
                                thumbColor: AppColors.primaryDark,
                                overlayColor: AppColors.primary
                                    .withValues(alpha: 0.15),
                                trackHeight: 4,
                              ),
                              child: Slider(
                                min: 5,
                                max: 25,
                                value: radius,
                                onChanged: (v) {
                                  ref
                                      .read(workZoneProvider.notifier)
                                      .setRadius(v);
                                  // Live map adjustment as user drags
                                  _centerMapOnLocation(center, v);
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('5 KM',
                                    style: AppTypography.labelMD.copyWith(
                                        fontSize: 10,
                                        color: AppColors.onSurfaceVariant)),
                                Text('25 KM',
                                    style: AppTypography.labelMD.copyWith(
                                        fontSize: 10,
                                        color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  try {
                                    await ref
                                        .read(workZoneProvider.notifier)
                                        .save();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Zona de trabajo guardada'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                      Navigator.pop(context);
                                    }
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Error al guardar zona'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : Text(
                                  'Guardar configuración',
                                  style: AppTypography.bodyLG.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Real flutter_map widget ───────────────────────────────────────────────────

class _RealMap extends StatelessWidget {
  final LatLng center;
  final double radiusKm;
  final MapController mapController;

  const _RealMap({
    required this.center,
    required this.radiusKm,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    // Derive zoom from radius for initial display
    final zoom = (13.5 - (radiusKm - 5) * 0.12).clamp(9.0, 14.0);

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        // OpenStreetMap tile layer — no API key required
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.servitask.tasker_view',
          maxZoom: 18,
        ),

        // Semi-transparent radius circle
        CircleLayer(
          circles: [
            CircleMarker(
              point: center,
              radius: radiusKm * 1000, // metres
              useRadiusInMeter: true,
              color: AppColors.primary.withValues(alpha: 0.12),
              borderColor: AppColors.primary.withValues(alpha: 0.55),
              borderStrokeWidth: 2.0,
            ),
          ],
        ),

        // User location pin
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 44,
              height: 44,
              child: _LocationPin(),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Location pin widget ───────────────────────────────────────────────────────

class _LocationPin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulse ring
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
        // Inner solid dot
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Placeholder while location loads ─────────────────────────────────────────

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE8F0E9),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}



