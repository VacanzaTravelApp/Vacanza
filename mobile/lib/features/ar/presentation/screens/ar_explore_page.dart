import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// UC1.11 — Light AR Mode shell:
/// - Fullscreen camera preview
/// - Center reticle overlay
/// - Thin permission / capability checks
class ArExplorePage extends StatefulWidget {
  const ArExplorePage({super.key});

  @override
  State<ArExplorePage> createState() => _ArExplorePageState();
}

enum _ArModeStatus {
  checking,
  cameraDenied,
  ready,
}

class _ArExplorePageState extends State<ArExplorePage> {
  CameraController? _cameraController;

  _ArModeStatus _status = _ArModeStatus.checking;

  @override
  void initState() {
    super.initState();
    _checkSupportAndPermissions();
  }

  Future<void> _checkSupportAndPermissions() async {
    final camStatus = await Permission.camera.request();
    if (!camStatus.isGranted) {
      setState(() => _status = _ArModeStatus.cameraDenied);
      return;
    }

    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _status = _ArModeStatus.ready;
      });
    } catch (_) {
      setState(() => _status = _ArModeStatus.cameraDenied);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore in AR'),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _ArModeStatus.checking:
        return const _ArStatusMessage(
          icon: Icons.hourglass_empty_rounded,
          title: 'Preparing AR Mode…',
          message: 'Checking device support and camera permission.',
        );
      case _ArModeStatus.cameraDenied:
        return const _ArStatusMessage(
          icon: Icons.camera_alt_outlined,
          title: 'Camera Permission Required',
          message:
              'Camera access is required to use AR Mode. Please enable it in system settings.',
        );
      case _ArModeStatus.ready:
        return Stack(
          children: [
            Positioned.fill(
              child: _cameraController != null &&
                      _cameraController!.value.isInitialized
                  ? CameraPreview(_cameraController!)
                  : const ColoredBox(color: Colors.black),
            ),
            const _CenterReticle(),
            // Reserved HUD area for future POI overlays / controls
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _CenterReticle extends StatelessWidget {
  const _CenterReticle();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 2,
            ),
            color: Colors.black.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArStatusMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ArStatusMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.grey.shade700),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

