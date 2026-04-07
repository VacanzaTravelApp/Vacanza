import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import '../../data/models/user_profile.dart';
import '../../data/profile_profile_options.dart';
import '../../data/utils/profile_photo_pick_crop.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../styles/profile_sheet_styles.dart';
import 'profile_photo_source_sheet.dart';
import 'searchable_multi_select_picker_sheet.dart';

/// Edit Profile bottom sheet: basic info; read-only email/join date.
/// Save dispatches [ProfileUpdateRequested] and pops once (no SnackBar in sheet).
class EditProfileSheet extends StatefulWidget {
  final UserProfile initialProfile;

  const EditProfileSheet({
    super.key,
    required this.initialProfile,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late UserProfile _draft;
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _preferredNameController;

  /// User chose "Remove photo" — DELETE binary and/or clear URL on save.
  bool _userRemovedPhoto = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialProfile.copyWith();
    _firstNameController = TextEditingController(text: widget.initialProfile.firstName);
    _middleNameController = TextEditingController(text: widget.initialProfile.middleName ?? '');
    _lastNameController = TextEditingController(text: widget.initialProfile.lastName);
    _preferredNameController = TextEditingController(text: widget.initialProfile.preferredName ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _preferredNameController.dispose();
    super.dispose();
  }

  void _syncDraftFromControllers() {
    setState(() {
      _draft = _draft.copyWith(
        firstName: _firstNameController.text.trim().isEmpty ? '' : _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim().isEmpty ? null : _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty ? '' : _lastNameController.text.trim(),
        preferredName: _preferredNameController.text.trim().isEmpty ? null : _preferredNameController.text.trim(),
      );
    });
  }

  Future<void> _save() async {
    _syncDraftFromControllers();
    final bloc = context.read<ProfileBloc>();

    if (_userRemovedPhoto && widget.initialProfile.hasProfilePhoto) {
      bloc.add(const ProfilePhotoDeleteRequested());
      try {
        await bloc.stream.firstWhere((s) => s.isProfilePhotoBusy);
        await bloc.stream.firstWhere((s) => !s.isProfilePhotoBusy);
      } catch (_) {}
      if (!mounted) return;
      final err = bloc.state.profileUpdateError;
      if (err != null && err.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        bloc.add(const ProfileUpdateErrorDismissed());
        return;
      }
    }

    bloc.add(ProfileUpdateRequested(widget.initialProfile, _draft));
    if (mounted) Navigator.of(context).pop();
  }

  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  static String _formatJoinDate(DateTime d) => 'Member since ${_months[d.month - 1]} ${d.year}';

  static String _formatBirthDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

  Future<void> _pickBirthDate() async {
    DateTime? initial;
    if (_draft.birthDate != null && _draft.birthDate!.length >= 10) {
      initial = DateTime.tryParse(_draft.birthDate!);
    }
    initial ??= DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      final yyyyMmDd = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() => _draft = _draft.copyWith(birthDate: yyyyMmDd));
    }
  }

  bool get _canShowRemovePhoto {
    if (_userRemovedPhoto) return false;
    if (_draft.profileImageUrl != null && _draft.profileImageUrl!.trim().isNotEmpty) {
      return true;
    }
    if (widget.initialProfile.hasProfilePhoto) return true;
    return false;
  }

  /// After crop UI "Save", upload immediately and return to profile hub (close sheet).
  Future<void> _uploadPhotoThenCloseSheet(String path) async {
    final bloc = context.read<ProfileBloc>();
    final messenger = ScaffoldMessenger.maybeOf(context);
    bloc.add(ProfilePhotoUploadRequested(path));
    try {
      if (!bloc.state.isProfilePhotoBusy) {
        await bloc.stream.firstWhere((s) => s.isProfilePhotoBusy);
      }
      await bloc.stream.firstWhere((s) => !s.isProfilePhotoBusy);
    } catch (_) {}
    final err = bloc.state.profileUpdateError;
    if (err != null && err.isNotEmpty) {
      messenger?.showSnackBar(SnackBar(content: Text(err)));
      bloc.add(const ProfileUpdateErrorDismissed());
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _showPhotoSourceSheet() {
    showProfilePhotoSourceBottomSheet(
      context,
      showRemove: _canShowRemovePhoto,
      onPickSource: (source) async {
        final path = await pickAndCropSquareProfilePhoto(source);
        if (path != null && mounted) {
          await _uploadPhotoThenCloseSheet(path);
        }
      },
      onRemove: () async {
        if (!mounted) return;
        setState(() {
          _userRemovedPhoto = true;
          _draft = _draft.copyWith(profileImageUrl: null);
        });
      },
    );
  }

  void _openCountryPicker() {
    final current = _draft.country;
    showSearchableMultiSelectPicker(
      context,
      config: SearchableMultiSelectPickerConfig(
        label: 'Country',
        options: profileCountryOptions,
        initialSelected: current != null && current.isNotEmpty ? [current] : [],
        searchable: true,
        accentColor: context.mapControlAccent,
        onDone: (selected) {
          setState(() {
            _draft = _draft.copyWith(
              country: selected.isEmpty ? null : selected.first,
            );
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSheetStyles.sheetPanel(
      context: context,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoSection(),
                  _buildReadOnlyBlock(),
                  _buildPersonalInfoSection(),
                  _buildAdditionalInfoSection(),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    final cs = Theme.of(context).colorScheme;
    final gradientColors = context.mapControlActiveGradientColors;
    final accent = context.mapControlAccent;
    const avatarSize = 108.0;
    const ring = 3.0;
    final innerSize = avatarSize - 2 * ring;
    const cameraButtonSize = 34.0;

    Widget avatarContent;
    if (_userRemovedPhoto) {
      avatarContent = const Icon(Icons.person, size: 48, color: Color(0xFF9CA3AF));
    } else if (_draft.profileImageUrl != null && _draft.profileImageUrl!.trim().isNotEmpty) {
      avatarContent = Image.network(
        _draft.profileImageUrl!,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 48, color: Color(0xFF9CA3AF)),
      );
    } else if (widget.initialProfile.hasProfilePhoto) {
      avatarContent = BlocBuilder<ProfileBloc, ProfileState>(
        buildWhen: (a, b) => a.profilePhotoBytes != b.profilePhotoBytes,
        builder: (context, state) {
          final bytes = state.profilePhotoBytes;
          if (bytes != null && bytes.isNotEmpty) {
            return Image.memory(
              bytes,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.person, size: 48, color: Color(0xFF9CA3AF)),
            );
          }
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    } else {
      avatarContent = const Icon(Icons.person, size: 48, color: Color(0xFF9CA3AF));
    }
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 16),
      child: Center(
        child: GestureDetector(
          onTap: _showPhotoSourceSheet,
          child: Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                padding: const EdgeInsets.all(ring),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: gradientColors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.16),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: innerSize,
                    height: innerSize,
                    child: ColoredBox(
                      color: Colors.grey.shade200,
                      child: avatarContent,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: cameraButtonSize,
                  height: cameraButtonSize,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.camera_alt, color: cs.onPrimary, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyBlock() {
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    final joinFormatted = _draft.joinDate != null
        ? _formatJoinDate(_draft.joinDate!)
        : '—';
    final resolved = _draft.displayName.trim().isNotEmpty
        ? _draft.displayName.trim()
        : UserProfile.computeDisplayNameFallback(
            firstName: _draft.firstName,
            middleName: _draft.middleName,
            lastName: _draft.lastName,
            preferredName: _draft.preferredName,
          );
    final displayName = resolved.isEmpty ? '—' : resolved;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mail_outline, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _draft.email,
                      style: TextStyle(fontSize: 14, color: cs.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Read-only',
                  style: TextStyle(
                    fontSize: 9,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      joinFormatted,
                      style: TextStyle(fontSize: 14, color: cs.onSurface),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Read-only',
                  style: TextStyle(
                    fontSize: 9,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Display name',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                'Auto-computed',
                style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PERSONAL INFO',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        _sectionLabel('First name *'),
        TextField(
          controller: _firstNameController,
          decoration: _inputDecoration('First name'),
          onChanged: (_) => _syncDraftFromControllers(),
        ),
        _sectionLabel('Middle name (optional)'),
        TextField(
          controller: _middleNameController,
          decoration: _inputDecoration('Middle name'),
          onChanged: (_) => _syncDraftFromControllers(),
        ),
        _sectionLabel('Last name *'),
        TextField(
          controller: _lastNameController,
          decoration: _inputDecoration('Last name'),
          onChanged: (_) => _syncDraftFromControllers(),
        ),
        _sectionLabel('Preferred name'),
        TextField(
          controller: _preferredNameController,
          decoration: _inputDecoration('e.g. Alex'),
          onChanged: (_) => _syncDraftFromControllers(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    final cs = Theme.of(context).colorScheme;
    DateTime? birthDateTime;
    if (_draft.birthDate != null && _draft.birthDate!.length >= 10) {
      birthDateTime = DateTime.tryParse(_draft.birthDate!);
    }
    final birthDateLabel = birthDateTime != null ? _formatBirthDate(birthDateTime) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 16),
        Text(
          'ADDITIONAL INFO',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        _sectionLabel('Country'),
        InkWell(
          onTap: _openCountryPicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.public, size: 20, color: cs.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    (_draft.country != null && _draft.country!.isNotEmpty) ? _draft.country! : 'Select country',
                    style: TextStyle(
                      fontSize: 14,
                      color: (_draft.country != null && _draft.country!.isNotEmpty)
                          ? cs.onSurface
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
        _sectionLabel('Date of birth'),
        InkWell(
          onTap: _pickBirthDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: cs.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    birthDateLabel ?? 'Select date of birth',
                    style: TextStyle(
                      fontSize: 14,
                      color: birthDateLabel != null
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        _sectionLabel('Gender'),
        Row(
          children: [
            for (final g in profileGenderOptions) ...[
              if (g != profileGenderOptions.first) const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _draft = _draft.copyWith(gender: g)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _draft.gender == g
                          ? context.mapControlAccent
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      formatGenderLabel(g),
                      style: TextStyle(
                        fontSize: 12,
                        color: _draft.gender == g
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return ProfileSheetStyles.inputDecoration(context, hint);
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        buildWhen: (a, b) => a.isProfilePhotoBusy != b.isProfilePhotoBusy,
        builder: (context, state) {
          final busy = state.isProfilePhotoBusy;
          return Row(
            children: [
              Expanded(
                child: ProfileSheetStyles.secondaryButton(
                  context: context,
                  text: 'Cancel',
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ProfileSheetStyles.primaryButton(
                  context: context,
                  text: busy ? 'Saving…' : 'Save',
                  onPressed: busy ? null : _save,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
