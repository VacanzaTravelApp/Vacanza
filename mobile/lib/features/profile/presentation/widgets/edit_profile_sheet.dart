import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  late TextEditingController _profileImageUrlController;

  static const _accentBlue = Color(0xFF0096FF);

  @override
  void initState() {
    super.initState();
    _draft = widget.initialProfile.copyWith();
    _firstNameController = TextEditingController(text: widget.initialProfile.firstName);
    _middleNameController = TextEditingController(text: widget.initialProfile.middleName ?? '');
    _lastNameController = TextEditingController(text: widget.initialProfile.lastName);
    _preferredNameController = TextEditingController(text: widget.initialProfile.preferredName ?? '');
    _profileImageUrlController = TextEditingController(text: widget.initialProfile.profileImageUrl ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _preferredNameController.dispose();
    _profileImageUrlController.dispose();
    super.dispose();
  }

  void _syncDraftFromControllers() {
    setState(() {
      _draft = _draft.copyWith(
        firstName: _firstNameController.text.trim().isEmpty ? '' : _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim().isEmpty ? null : _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim().isEmpty ? '' : _lastNameController.text.trim(),
        preferredName: _preferredNameController.text.trim().isEmpty ? null : _preferredNameController.text.trim(),
        profileImageUrl: _profileImageUrlController.text.trim().isEmpty ? null : _profileImageUrlController.text.trim(),
      );
    });
  }

  void _save() {
    _syncDraftFromControllers();
    context.read<ProfileBloc>().add(
          ProfileUpdateRequested(widget.initialProfile, _draft),
        );
    if (mounted) Navigator.of(context).pop();
  }

  static String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _readOnlySection(),
                  _displayNameHint(),
                  _editableSection(),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
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

  Widget _readOnlySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Email'),
        Text(
          _draft.email,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        _sectionLabel('Join date'),
        Text(
          _draft.joinDate != null ? _formatDate(_draft.joinDate!) : '—',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _displayNameHint() {
    final display = _draft.displayNameFallback;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        'Display name: $display',
        style: TextStyle(
          fontSize: 11,
          fontStyle: FontStyle.italic,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _editableSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('First name'),
        TextField(
          controller: _firstNameController,
          decoration: _inputDecoration('First name'),
          onChanged: (_) => _syncDraftFromControllers(),
        ),
        _sectionLabel('Middle name'),
        TextField(
          controller: _middleNameController,
          decoration: _inputDecoration('Middle name (optional)'),
          onChanged: (_) => _syncDraftFromControllers(),
        ),
        _sectionLabel('Last name'),
        TextField(
          controller: _lastNameController,
          decoration: _inputDecoration('Last name'),
          onChanged: (_) => _syncDraftFromControllers(),
        ),
        _sectionLabel('Preferred name'),
        TextField(
          controller: _preferredNameController,
          decoration: _inputDecoration('Preferred name (optional)'),
          onChanged: (_) => _syncDraftFromControllers(),
        ),
        _sectionLabel('Country'),
        InkWell(
          onTap: _openCountryPicker,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    (_draft.country != null && _draft.country!.isNotEmpty)
                        ? _draft.country!
                        : 'Select country',
                    style: TextStyle(
                      fontSize: 14,
                      color: (_draft.country != null && _draft.country!.isNotEmpty)
                          ? const Color(0xFF111827)
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
        _sectionLabel('Birth date'),
        InkWell(
          onTap: _pickBirthDate,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _draft.birthDate != null && _draft.birthDate!.isNotEmpty
                        ? _draft.birthDate!
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 14,
                      color: _draft.birthDate != null && _draft.birthDate!.isNotEmpty
                          ? const Color(0xFF111827)
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
        _sectionLabel('Gender'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: profileGenderOptions.map((g) {
            final selected = _draft.gender == g;
            return GestureDetector(
              onTap: () => setState(() => _draft = _draft.copyWith(gender: g)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _accentBlue : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  formatGenderLabel(g),
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        _sectionLabel('Profile image URL'),
        TextField(
          controller: _profileImageUrlController,
          decoration: _inputDecoration('https://…'),
          keyboardType: TextInputType.url,
          onChanged: (_) => _syncDraftFromControllers(),
        ),
      ],
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
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: _accentBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
