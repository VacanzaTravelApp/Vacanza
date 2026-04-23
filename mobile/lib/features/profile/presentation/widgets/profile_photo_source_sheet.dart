import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/utils/profile_photo_pick_crop.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../styles/profile_sheet_styles.dart';

/// Pick, crop, upload; show SnackBar on failure.
/// [onPhotoOpSuccess] runs after a successful upload (e.g. close full-screen viewer).
///
/// Does not bail on [context].mounted after returning from the native picker/cropper:
/// iOS can report the tree below as not mounted while still valid for [read].
Future<void> runImmediateProfilePhotoPickAndUpload(
  BuildContext context,
  ImageSource source, {
  VoidCallback? onPhotoOpSuccess,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ProfileBloc bloc;
  try {
    bloc = context.read<ProfileBloc>();
  } catch (_) {
    return;
  }

  final path = await pickAndCropSquareProfilePhoto(source);
  if (path == null) return;

  bloc.add(ProfilePhotoUploadRequested(path));

  try {
    if (!bloc.state.isProfilePhotoBusy) {
      await bloc.stream.firstWhere((s) => s.isProfilePhotoBusy);
    }
    await bloc.stream.firstWhere((s) => !s.isProfilePhotoBusy);
  } catch (_) {}

  final err = bloc.state.profileUpdateError;
  if (err != null && err.isNotEmpty) {
    if (context.mounted) {
      messenger?.showSnackBar(SnackBar(content: Text(err)));
    }
    bloc.add(const ProfileUpdateErrorDismissed());
    return;
  }
  onPhotoOpSuccess?.call();
}

/// Delete server photo; show SnackBar on failure.
/// [onPhotoOpSuccess] runs after a successful delete (e.g. close full-screen viewer).
Future<void> runImmediateProfilePhotoDelete(
  BuildContext context, {
  VoidCallback? onPhotoOpSuccess,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ProfileBloc bloc;
  try {
    bloc = context.read<ProfileBloc>();
  } catch (_) {
    return;
  }

  bloc.add(const ProfilePhotoDeleteRequested());

  try {
    if (!bloc.state.isProfilePhotoBusy) {
      await bloc.stream.firstWhere((s) => s.isProfilePhotoBusy);
    }
    await bloc.stream.firstWhere((s) => !s.isProfilePhotoBusy);
  } catch (_) {}

  final err = bloc.state.profileUpdateError;
  if (err != null && err.isNotEmpty) {
    if (context.mounted) {
      messenger?.showSnackBar(SnackBar(content: Text(err)));
    }
    bloc.add(const ProfileUpdateErrorDismissed());
    return;
  }
  onPhotoOpSuccess?.call();
}

/// Camera / gallery / remove — shared UI for Edit Profile (deferred save) and
/// full-screen viewer (immediate upload/delete).
Future<void> showProfilePhotoSourceBottomSheet(
  BuildContext context, {
  required bool showRemove,
  required Future<void> Function(ImageSource source) onPickSource,
  required Future<void> Function() onRemove,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ProfileSheetStyles.sheetPanel(
      context: ctx,
      topRadius: 20,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () async {
                Navigator.pop(ctx);
                await onPickSource(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                await onPickSource(ImageSource.gallery);
              },
            ),
            if (showRemove)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove photo'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await onRemove();
                },
              ),
          ],
        ),
      ),
    ),
  );
}

/// Picks + crops, then uploads via [ProfileBloc]. Used after full-screen preview.
Future<void> showProfilePhotoImmediateActions(
  BuildContext context, {
  required bool showRemove,
}) async {
  await showProfilePhotoSourceBottomSheet(
    context,
    showRemove: showRemove,
    onPickSource: (source) => runImmediateProfilePhotoPickAndUpload(context, source),
    onRemove: () => runImmediateProfilePhotoDelete(context),
  );
}
