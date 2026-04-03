import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'profile_photo_source_sheet.dart';

/// Full-screen preview: circular frame; pencil opens an anchored menu (photo stays open).
Future<void> showProfilePhotoViewer(
  BuildContext context, {
  required Uint8List? profilePhotoBytes,
  required String? profileImageUrl,
}) {
  final bytes = profilePhotoBytes;
  final urlTrimmed = profileImageUrl?.trim();
  final hasVisual = (bytes != null && bytes.isNotEmpty) ||
      (urlTrimmed != null && urlTrimmed.isNotEmpty);

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (dialogContext) {
      return _ProfilePhotoViewerDialog(
        hostContext: context,
        bytes: bytes,
        urlTrimmed: urlTrimmed,
        hasVisual: hasVisual,
      );
    },
  );
}

class _ProfilePhotoViewerDialog extends StatefulWidget {
  const _ProfilePhotoViewerDialog({
    required this.hostContext,
    required this.bytes,
    required this.urlTrimmed,
    required this.hasVisual,
  });

  /// Ancestor context (e.g. profile screen) — [ProfileBloc] lives here.
  final BuildContext hostContext;
  final Uint8List? bytes;
  final String? urlTrimmed;
  final bool hasVisual;

  @override
  State<_ProfilePhotoViewerDialog> createState() =>
      _ProfilePhotoViewerDialogState();
}

class _ProfilePhotoViewerDialogState extends State<_ProfilePhotoViewerDialog> {
  final GlobalKey _editButtonKey = GlobalKey();

  void _closeViewerAfterSuccess() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
      }
    });
  }

  void _pickAndUpload(ImageSource source) {
    runImmediateProfilePhotoPickAndUpload(
      widget.hostContext,
      source,
      onPhotoOpSuccess: _closeViewerAfterSuccess,
    );
  }

  void _deletePhoto() {
    runImmediateProfilePhotoDelete(
      widget.hostContext,
      onPhotoOpSuccess: _closeViewerAfterSuccess,
    );
  }

  void _showEditMenuBelowPencil() {
    final buttonCtx = _editButtonKey.currentContext;
    if (buttonCtx == null) return;

    final button = buttonCtx.findRenderObject()! as RenderBox;
    final overlayState = Overlay.of(buttonCtx);
    final overlay = overlayState.context.findRenderObject()! as RenderBox;

    final topLeft =
        button.localToGlobal(Offset.zero, ancestor: overlay);
    final bottomRight = button.localToGlobal(
      Offset(button.size.width, button.size.height),
      ancestor: overlay,
    );

    const menuWidth = 232.0;
    const estimatedMenuHeight = 168.0;
    var menuLeft = topLeft.dx;
    menuLeft = menuLeft.clamp(
      8.0,
      (overlay.size.width - menuWidth - 8).clamp(8.0, double.infinity),
    );
    final menuTop = bottomRight.dy + 8;

    final position = RelativeRect.fromRect(
      Rect.fromLTWH(menuLeft, menuTop, menuWidth, estimatedMenuHeight),
      Offset.zero & overlay.size,
    );

    final showRemove = widget.hasVisual;

    showMenu<void>(
      context: buttonCtx,
      position: position,
      color: Colors.white.withValues(alpha: 0.82),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black26,
      elevation: 14,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: [
        PopupMenuItem<void>(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          onTap: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _pickAndUpload(ImageSource.camera);
            });
          },
          child: const _MenuRow(
            icon: Icons.camera_alt_rounded,
            label: 'Take photo',
            iconColor: Color(0xDE000000),
            textColor: Color(0xDE000000),
          ),
        ),
        PopupMenuItem<void>(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          onTap: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _pickAndUpload(ImageSource.gallery);
            });
          },
          child: const _MenuRow(
            icon: Icons.photo_library_rounded,
            label: 'Choose from gallery',
            iconColor: Color(0xDE000000),
            textColor: Color(0xDE000000),
          ),
        ),
        if (showRemove)
          PopupMenuItem<void>(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            onTap: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _deletePhoto();
              });
            },
            child: const _MenuRow(
              icon: Icons.delete_outline_rounded,
              label: 'Remove photo',
              iconColor: Color(0xFFE53935),
              textColor: Color(0xFFC62828),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dialogContext = context;
    final size = MediaQuery.sizeOf(dialogContext);
    final diameter = (size.shortestSide * 0.72).clamp(220.0, 360.0);
    const ring = 3.0;
    final innerD = diameter - 2 * ring;

    final bytes = widget.bytes;
    final urlTrimmed = widget.urlTrimmed;

    Widget imageBody;
    if (bytes != null && bytes.isNotEmpty) {
      imageBody = Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: innerD,
        height: innerD,
        filterQuality: FilterQuality.medium,
      );
    } else if (urlTrimmed != null && urlTrimmed.isNotEmpty) {
      imageBody = Image.network(
        urlTrimmed,
        fit: BoxFit.cover,
        width: innerD,
        height: innerD,
        filterQuality: FilterQuality.medium,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: innerD,
            height: innerD,
            child: const ColoredBox(
              color: Color(0xFF1A1A1A),
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => SizedBox(
          width: innerD,
          height: innerD,
          child: const ColoredBox(
            color: Color(0xFF1A1A1A),
            child: Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Colors.white38,
                size: 56,
              ),
            ),
          ),
        ),
      );
    } else {
      imageBody = ColoredBox(
        color: const Color(0xFF2A2A2A),
        child: Center(
          child: Icon(
            Icons.person_rounded,
            size: innerD * 0.42,
            color: Colors.white24,
          ),
        ),
      );
    }

    final circlePreview = SizedBox(
      width: diameter,
      height: diameter,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: diameter,
            height: diameter,
            padding: const EdgeInsets.all(ring),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0096FF), Color(0xFF2ECC71)],
              ),
            ),
            child: ClipOval(
              child: SizedBox(
                width: innerD,
                height: innerD,
                child: InteractiveViewer(
                  minScale: 0.85,
                  maxScale: 4,
                  boundaryMargin: EdgeInsets.zero,
                  child: SizedBox(
                    width: innerD,
                    height: innerD,
                    child: imageBody,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Material(
              key: _editButtonKey,
              color: const Color(0xFF0096FF),
              elevation: 4,
              shadowColor: Colors.black45,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _showEditMenuBelowPencil,
                child: const Padding(
                  padding: EdgeInsets.all(11),
                  child: Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(child: circlePreview),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.iconColor = Colors.white70,
    this.textColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
