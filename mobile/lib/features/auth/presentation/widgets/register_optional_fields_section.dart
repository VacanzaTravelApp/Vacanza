import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/data/profile_profile_options.dart';
import '../../../profile/presentation/widgets/searchable_multi_select_picker_sheet.dart';

/// Optional country, birth date, and gender for `POST /auth/register`.
class RegisterOptionalFieldsSection extends StatelessWidget {
  final String? country;
  final String? birthDateIso;
  final String? gender;

  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String?> onBirthDateChanged;
  final ValueChanged<String?> onGenderChanged;

  const RegisterOptionalFieldsSection({
    super.key,
    required this.country,
    required this.birthDateIso,
    required this.gender,
    required this.onCountryChanged,
    required this.onBirthDateChanged,
    required this.onGenderChanged,
  });

  String _birthDisplayLabel() {
    final s = birthDateIso;
    if (s == null || s.isEmpty) return '';
    final parts = s.split('-');
    if (parts.length != 3) return s;
    return '${parts[2]}.${parts[1]}.${parts[0]}';
  }

  DateTime _defaultInitialBirthDate() {
    final now = DateTime.now();
    final parsed = birthDateIso != null && birthDateIso!.isNotEmpty
        ? DateTime.tryParse(birthDateIso!)
        : null;
    if (parsed != null) return parsed;
    return DateTime(now.year - 25, now.month, now.day);
  }

  String _formatIso(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _pickBirthDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _defaultInitialBirthDate(),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      builder: (ctx, child) {
        final theme = Theme.of(ctx);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onBirthDateChanged(_formatIso(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More details (optional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 10),
        _pickerTile(
          context,
          label: 'Country',
          value: (country != null && country!.isNotEmpty) ? country : null,
          placeholder: 'Select country',
          onTap: () {
            showSearchableMultiSelectPicker(
              context,
              config: SearchableMultiSelectPickerConfig(
                label: 'Country',
                options: profileCountryOptions,
                initialSelected:
                    country != null && country!.isNotEmpty ? [country!] : [],
                searchable: true,
                accentColor: AppColors.primary,
                onDone: (selected) {
                  onCountryChanged(selected.isEmpty ? null : selected.first);
                },
              ),
            );
          },
        ),
        if (country != null && country!.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => onCountryChanged(null),
              child: Text(
                'Clear country',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          ),
        const SizedBox(height: 10),
        _pickerTile(
          context,
          label: 'Birth date',
          value: (birthDateIso != null && birthDateIso!.isNotEmpty)
              ? _birthDisplayLabel()
              : null,
          placeholder: 'Select date of birth',
          onTap: () => _pickBirthDate(context),
        ),
        if (birthDateIso != null && birthDateIso!.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => onBirthDateChanged(null),
              child: Text(
                'Clear date',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Text(
          'Gender',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in profileGenderOptions)
              ChoiceChip(
                label: Text(formatGenderLabel(g)),
                selected: gender == g,
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                onSelected: (_) {
                  onGenderChanged(gender == g ? null : g);
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _pickerTile(
    BuildContext context, {
    required String label,
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value ?? placeholder,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: value != null
                            ? const Color(0xFF111827)
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
