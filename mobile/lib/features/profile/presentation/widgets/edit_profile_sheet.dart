import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/user_profile.dart';
import '../../data/profile_profile_options.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
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

  /// Local file path from camera/gallery picker; used for preview only (no upload infra yet).
  String? _pickedLocalFilePath;

  static const _accentBlue = Color(0xFF0096FF);

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

  void _save() {
    _syncDraftFromControllers();
    // TODO: Integrate profile photo upload (e.g. Firebase Storage) and set profileImageUrl from returned URL.
    UserProfile draftToSave = _draft;
    if (_pickedLocalFilePath != null) {
      // Picked new photo but no upload: do not send profileImageUrl so backend keeps existing.
      draftToSave = _draft.copyWith(profileImageUrl: widget.initialProfile.profileImageUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo upload not available yet.')),
        );
      }
    }
    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(widget.initialProfile, draftToSave),
        );
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

  void _showPhotoSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove photo'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _pickedLocalFilePath = null;
                  _draft = _draft.copyWith(profileImageUrl: null);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source);
    if (xFile != null && mounted) {
      setState(() => _pickedLocalFilePath = xFile.path);
    }
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
        accentColor: _accentBlue,
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
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    const avatarSize = 108.0;
    const cameraButtonSize = 34.0;
    Widget avatarContent;
    if (_pickedLocalFilePath != null) {
      avatarContent = Image.file(
        File(_pickedLocalFilePath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (_draft.profileImageUrl != null && _draft.profileImageUrl!.trim().isNotEmpty) {
      avatarContent = Image.network(
        _draft.profileImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 48, color: Color(0xFF9CA3AF)),
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  color: Colors.grey.shade200,
                ),
                clipBehavior: Clip.antiAlias,
                child: avatarContent,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: cameraButtonSize,
                  height: cameraButtonSize,
                  decoration: BoxDecoration(
                    color: _accentBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyBlock() {
    final joinFormatted = _draft.joinDate != null
        ? _formatJoinDate(_draft.joinDate!)
        : '—';
    final displayName = (_draft.preferredName != null && _draft.preferredName!.trim().isNotEmpty)
        ? _draft.preferredName!.trim()
        : ([_draft.firstName, _draft.lastName].where((s) => s.isNotEmpty).join(' ').trim().isEmpty ? '—' : '${_draft.firstName} ${_draft.lastName}'.trim());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mail_outline, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(_draft.email, style: const TextStyle(fontSize: 14, color: Color(0xFF374151)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Read-only', style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(joinFormatted, style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Read-only', style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: _accentBlue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Display name', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(displayName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _accentBlue), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text('Auto-computed', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PERSONAL INFO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 1.2)),
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
        Text('ADDITIONAL INFO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        _sectionLabel('Country'),
        InkWell(
          onTap: _openCountryPicker,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.public, size: 20, color: Colors.grey.shade500),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    (_draft.country != null && _draft.country!.isNotEmpty) ? _draft.country! : 'Select country',
                    style: TextStyle(
                      fontSize: 14,
                      color: (_draft.country != null && _draft.country!.isNotEmpty) ? const Color(0xFF111827) : Colors.grey.shade500,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade500),
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
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Colors.grey.shade500),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    birthDateLabel ?? 'Select date of birth',
                    style: TextStyle(
                      fontSize: 14,
                      color: birthDateLabel != null ? const Color(0xFF111827) : Colors.grey.shade500,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade500),
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
                      color: _draft.gender == g ? _accentBlue : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      formatGenderLabel(g),
                      style: TextStyle(
                        fontSize: 12,
                        color: _draft.gender == g ? Colors.white : Colors.grey.shade700,
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
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.grey.shade700,
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0096FF), Color(0xFF00C6FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0096FF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _save,
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
