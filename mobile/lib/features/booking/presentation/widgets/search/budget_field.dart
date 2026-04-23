import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile/core/theme/app_theme.dart';

import '../../../data/models/booking_currency.dart';
import 'booking_field_scroll_padding.dart';
import 'booking_search_field_styles.dart';

/// Budget input with currency symbol prefix and compact currency selector (TASK-9).
class BudgetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? helperText;
  final String currencyCode;
  final ValueChanged<String> onCurrencyChanged;

  const BudgetField({
    super.key,
    required this.controller,
    required this.currencyCode,
    required this.onCurrencyChanged,
    this.label = 'Budget (Optional)',
    this.helperText,
  });

  static String? _symbolFor(String code) {
    switch (code) {
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'TRY':
        return '₺';
      case 'JPY':
        return '¥';
      case 'CHF':
        return 'Fr';
      case 'AUD':
        return r'A$';
      case 'CAD':
        return r'C$';
      default:
        return null;
    }
  }

  static const _fieldHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    final code = BookingCurrencies.normalize(currencyCode);
    final symbol = _symbolFor(code);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(label, style: BookingSearchFieldStyles.fieldLabel(context)),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: SizedBox(
                height: _fieldHeight,
                child: TextFormField(
                  controller: controller,
                  scrollPadding: bookingFieldScrollPadding(context),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: '120',
                    hintStyle: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                    prefixIcon: symbol != null
                        ? Padding(
                            padding: const EdgeInsets.only(left: 10, right: 2),
                            child: Align(
                              widthFactor: 1,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                symbol,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(left: 10, right: 2),
                            child: Icon(
                              Icons.payments_outlined,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 0,
                    ),
                    filled: true,
                    fillColor: BookingSearchFieldStyles.fieldFill(context),
                    isDense: true,
                    contentPadding: const EdgeInsets.only(
                      left: 4,
                      right: 10,
                      top: 14,
                      bottom: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: BookingSearchFieldStyles.fieldBorderInactive(
                          context,
                        ),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: BookingSearchFieldStyles.fieldBorderInactive(
                          context,
                        ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: accent,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _CompactCurrencyPicker(
              value: code,
              onChanged: onCurrencyChanged,
            ),
          ],
        ),
        if (helperText != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              helperText!,
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  /// Parses the budget text. Returns null for empty, zero, or invalid values.
  static double? parse(String text) {
    if (text.trim().isEmpty) return null;
    final value = double.tryParse(text.trim());
    if (value == null || value <= 0) return null;
    return value;
  }
}

class _CompactCurrencyPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _CompactCurrencyPicker({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final normalized = BookingCurrencies.normalize(value);
    return SizedBox(
      height: BudgetField._fieldHeight,
      child: Material(
        color: BookingSearchFieldStyles.fieldFill(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.only(left: 8, right: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BookingSearchFieldStyles.fieldBorderInactive(context),
            ),
          ),
          child: DropdownButton<String>(
            key: ValueKey<String>('budget_ccy_$normalized'),
            value: normalized,
            underline: const SizedBox.shrink(),
            isDense: true,
            isExpanded: false,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
            style: BookingSearchFieldStyles.dropdownValue(context),
            selectedItemBuilder: (context) => BookingCurrencies.codes
                .map(
                  (c) => Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      c,
                      style: BookingSearchFieldStyles.dropdownValue(context),
                    ),
                  ),
                )
                .toList(),
            items: BookingCurrencies.codes
                .map(
                  (c) => DropdownMenuItem<String>(
                    value: c,
                    child: Text(
                      c,
                      style: BookingSearchFieldStyles.dropdownMenuItem(context),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}
