import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/booking/presentation/widgets/search/booking_search_field_styles.dart';

import '../../data/models/user_preferences.dart';
import '../../data/profile_preference_options.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../styles/profile_sheet_styles.dart';
import 'searchable_multi_select_picker_sheet.dart';

/// Edit Preferences bottom sheet: Basics visible, Advanced collapsed by default.
/// Uses local draft; Save dispatches [PreferencesUpdateRequested] then pops once.
class EditPreferencesSheet extends StatefulWidget {
  final UserPreferences initialPrefs;

  const EditPreferencesSheet({
    super.key,
    required this.initialPrefs,
  });

  @override
  State<EditPreferencesSheet> createState() => _EditPreferencesSheetState();
}

/// Ordered steps for guided flow: Basics then Advanced.
enum _Step {
  travelStyle,
  favoriteCategories,
  activityLevel,
  cuisinePreferences,
  dietaryRestrictions,
  dailyBudget,
  budgetCurrency,
  tripPace,
  accommodationType,
  transportPreference,
  accessibilityNeeds,
  preferredLanguage,
  spokenLanguages,
}

class _EditPreferencesSheetState extends State<EditPreferencesSheet> {
  late UserPreferences _draft;
  late TextEditingController _budgetController;
  late ScrollController _scrollController;
  late FocusNode _budgetFocusNode;
  late Color _accentBlue;

  // Keep keys aligned with step enum indices.
  static final int _stepCount = _Step.values.length;
  late final List<GlobalKey> _stepKeys;

  var _isAutoScrolling = false;
  DateTime? _lastAdvanceTime;
  static const _advanceDebounce = Duration(milliseconds: 250);

  static const _scrollDuration = Duration(milliseconds: 300);
  static const _scrollCurve = Curves.easeOut;

  /// Sticky header height (drag + title row + padding). Used so scroll target sits below it.
  static const _headerHeight = 68.0;
  static const _topInset = _headerHeight + 12.0;

  /// For non-input steps: alignment ~0.15 so section heading stays visible (not 0.0 top snap).
  static const _nonInputAlignment = 0.15;

  static const _accentCuisine = Color(0xFFF4A261);
  static const _accentDietary = Color(0xFFFF6B6B);
  static const _accentAccessibility = Color(0xFF9C27B0);
  static const _accentLanguage = Color(0xFF2ECC71);

  static const _optionFontSize = 12.0;
  static const _optionFontWeight = FontWeight.w700;

  var _showMoreTravelStyle = false;
  var _showMoreAccommodation = false;
  var _showMoreTransport = false;
  var _showMoreLanguages = false;

  @override
  void initState() {
    super.initState();
    _stepKeys = List.generate(_stepCount, (_) => GlobalKey());
    _draft = _copyDraft(widget.initialPrefs);
    _budgetController = TextEditingController(
      text: widget.initialPrefs.dailyBudget?.toString() ?? '',
    );
    _scrollController = ScrollController();
    _budgetFocusNode = FocusNode();
    _budgetFocusNode.addListener(_onBudgetFocusChange);
  }

  @override
  void dispose() {
    _budgetFocusNode.removeListener(_onBudgetFocusChange);
    _budgetFocusNode.dispose();
    _scrollController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _onBudgetFocusChange() {
    if (!_budgetFocusNode.hasFocus && mounted) {
      _onStepCompleted(_Step.dailyBudget);
    }
  }

  /// Advance to the next step (scroll next field to top, optionally expand Advanced).
  void _onStepCompleted(_Step step) {
    if (_isAutoScrolling) return;
    final now = DateTime.now();
    if (_lastAdvanceTime != null &&
        now.difference(_lastAdvanceTime!) < _advanceDebounce) {
      return;
    }
    _lastAdvanceTime = now;
    final index = step.index;
    if (index + 1 >= _stepCount) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToStep(index + 1);
    });
  }

  /// Scroll so the step at [index] is at the TOP of the viewport. If step is Advanced and collapsed, expand first.
  void _scrollToStep(int index) {
    if (!mounted) return;
    // DailyBudget and BudgetCurrency share the same row (same key).
    final keyIndex = index == _Step.budgetCurrency.index
        ? _Step.dailyBudget.index
        : index;
    final key = _stepKeys[keyIndex];
    final ctx = key.currentContext;
    if (ctx == null) return;
    final alignment = _nonInputAlignment;
    _isAutoScrolling = true;

    final scrollable = Scrollable.maybeOf(ctx);
    if (scrollable != null &&
        _scrollController.hasClients &&
        key.currentContext?.findRenderObject() != null) {
      final keyBox = key.currentContext!.findRenderObject()! as RenderBox;
      final viewportBox = scrollable.context.findRenderObject() as RenderBox?;
      if (viewportBox != null) {
        final keyGlobal = keyBox.localToGlobal(Offset.zero);
        final viewportGlobal = viewportBox.localToGlobal(Offset.zero);
        final rawOffset = _scrollController.offset +
            (keyGlobal.dy - viewportGlobal.dy);
        final targetOffset = (rawOffset - _topInset)
            .clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.animateTo(
          targetOffset,
          duration: _scrollDuration,
          curve: _scrollCurve,
        );
      } else {
        Scrollable.ensureVisible(
          ctx,
          duration: _scrollDuration,
          curve: _scrollCurve,
          alignment: alignment,
        );
      }
    } else {
      Scrollable.ensureVisible(
        ctx,
        duration: _scrollDuration,
        curve: _scrollCurve,
        alignment: alignment,
      );
    }

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _isAutoScrolling = false);
    });
  }

  Widget _wrapWithKey(_Step step, Widget child) {
    return Container(key: _stepKeys[step.index], child: child);
  }

  UserPreferences _copyDraft(UserPreferences p) {
    return p.copyWith(
      favoriteCategories: List.from(p.favoriteCategories),
      cuisinePreferences: List.from(p.cuisinePreferences),
      dietaryRestrictions: List.from(p.dietaryRestrictions),
      accessibilityNeeds: List.from(p.accessibilityNeeds),
      avoidCategories: List.from(p.avoidCategories),
      splurgeCategories: List.from(p.splurgeCategories),
      spokenLanguages: List.from(p.spokenLanguages),
    );
  }

  void _updateDraft(UserPreferences Function(UserPreferences) fn) {
    setState(() => _draft = fn(_draft));
  }

  void _openPickerAndSet(
    String label,
    List<String> options,
    List<String> current,
    Color accentColor,
    bool searchable,
    UserPreferences Function(UserPreferences, List<String>) setter, {
    _Step? onAfterCloseAdvanceStep,
  }) {
    showSearchableMultiSelectPicker(
      context,
      config: SearchableMultiSelectPickerConfig(
        label: label,
        options: options,
        initialSelected: current,
        searchable: searchable,
        accentColor: accentColor,
        onDone: (selected) {
          setState(() {
            _draft = setter(_draft, selected);
          });
        },
      ),
    ).then((_) {
      final step = onAfterCloseAdvanceStep;
      if (mounted && step != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onStepCompleted(step);
        });
      }
    });
  }

  void _save() {
    context.read<ProfileBloc>().add(
          PreferencesUpdateRequested(widget.initialPrefs, _draft),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    _accentBlue = context.mapControlAccent;
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
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicsSection(_accentBlue),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
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
                'Preferences',
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

  Widget _sectionLabel(String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: cs.onSurfaceVariant.withValues(alpha: 0.92),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildBasicsSection(Color accentBlue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Travel Preferences'),
        _wrapWithKey(_Step.travelStyle, _chipSingleWithMore(
          options: optionTravelStyle,
          value: _draft.travelStyle,
          maxVisible: 5,
          isExpanded: _showMoreTravelStyle,
          onToggleMore: () => setState(() => _showMoreTravelStyle = !_showMoreTravelStyle),
          onChanged: (v) {
            _updateDraft((d) => d.copyWith(travelStyle: v));
            _onStepCompleted(_Step.travelStyle);
          },
        )),
        _sectionLabel('Favorite Categories'),
        _wrapWithKey(_Step.favoriteCategories, _selectRow(
          label: 'Select categories',
          value: _draft.favoriteCategories,
          accentColor: accentBlue,
          onTap: () => _openPickerAndSet(
            'Favorite Categories',
            optionFavoriteCategories,
            _draft.favoriteCategories,
            accentBlue,
            true,
            (d, sel) => d.copyWith(favoriteCategories: sel),
            onAfterCloseAdvanceStep: _Step.favoriteCategories,
          ),
        )),
        _sectionLabel('Daily Budget'),
        _wrapWithKey(_Step.dailyBudget, Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _budgetController,
                focusNode: _budgetFocusNode,
                keyboardType: TextInputType.number,
                decoration: ProfileSheetStyles.inputDecoration(context, '150'),
                onChanged: (s) {
                  final v = num.tryParse(s);
                  _updateDraft((d) => d.copyWith(dailyBudget: v));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey<String?>(_draft.budgetCurrency),
                initialValue: _draft.budgetCurrency ?? 'EUR',
                decoration: ProfileSheetStyles.inputDecoration(context, ''),
                items: optionBudgetCurrency
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  _updateDraft((d) => d.copyWith(budgetCurrency: v));
                  _onStepCompleted(_Step.budgetCurrency);
                },
              ),
            ),
          ],
        )),

        _sectionLabel('Activity Level'),
        _wrapWithKey(_Step.activityLevel, _segmented(
          options: optionActivityLevel,
          value: _draft.activityLevel,
          onChanged: (v) {
            _updateDraft((d) => d.copyWith(activityLevel: v));
            _onStepCompleted(_Step.activityLevel);
          },
        )),

        _sectionLabel('Cuisine Preferences'),
        _wrapWithKey(_Step.cuisinePreferences, _selectRow(
          label: 'Select cuisines',
          value: _draft.cuisinePreferences,
          accentColor: _accentCuisine,
          onTap: () => _openPickerAndSet(
            'Cuisine Preferences',
            optionCuisinePreferences,
            _draft.cuisinePreferences,
            _accentCuisine,
            true,
            (d, sel) => d.copyWith(cuisinePreferences: sel),
            onAfterCloseAdvanceStep: _Step.cuisinePreferences,
          ),
        )),
        _sectionLabel('Dietary Restrictions & Allergens'),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.bolt, size: 12, color: _accentBlue),
              const SizedBox(width: 4),
              Text(
                'Used by AI filter',
                style: TextStyle(
                  fontSize: 10,
                  color: _accentBlue,
                ),
              ),
            ],
          ),
        ),
        _wrapWithKey(_Step.dietaryRestrictions, _selectRow(
          label: 'Select dietary restrictions',
          value: _draft.dietaryRestrictions,
          accentColor: _accentDietary,
          onTap: () => _openPickerAndSet(
            'Dietary Restrictions',
            optionDietaryRestrictions,
            _draft.dietaryRestrictions,
            _accentDietary,
            true,
            (d, sel) => d.copyWith(dietaryRestrictions: sel),
            onAfterCloseAdvanceStep: _Step.dietaryRestrictions,
          ),
        )),

        _sectionLabel('Accessibility Needs'),
        _wrapWithKey(_Step.accessibilityNeeds, _selectRow(
          label: 'Select accessibility needs',
          value: _draft.accessibilityNeeds,
          accentColor: _accentAccessibility,
          onTap: () => _openPickerAndSet(
            'Accessibility Needs',
            optionAccessibilityNeeds,
            _draft.accessibilityNeeds,
            _accentAccessibility,
            false,
            (d, sel) => d.copyWith(accessibilityNeeds: sel),
            onAfterCloseAdvanceStep: _Step.accessibilityNeeds,
          ),
        )),

        _sectionLabel('Trip Pace'),
        _wrapWithKey(_Step.tripPace, _segmented(
          options: optionTripPace,
          value: _draft.tripPace,
          onChanged: (v) {
            _updateDraft((d) => d.copyWith(tripPace: v));
            _onStepCompleted(_Step.tripPace);
          },
        )),

        _sectionLabel('Accommodation'),
        _wrapWithKey(_Step.accommodationType, _chipSingleWithMore(
          options: optionAccommodationType,
          value: _draft.accommodationType,
          maxVisible: 3,
          isExpanded: _showMoreAccommodation,
          onToggleMore: () => setState(() => _showMoreAccommodation = !_showMoreAccommodation),
          onChanged: (v) {
            _updateDraft((d) => d.copyWith(accommodationType: v));
            _onStepCompleted(_Step.accommodationType);
          },
        )),

        _sectionLabel('Transport'),
        _wrapWithKey(_Step.transportPreference, _chipSingleWithMore(
          options: optionTransportPreference,
          value: _draft.transportPreference,
          maxVisible: 3,
          isExpanded: _showMoreTransport,
          onToggleMore: () => setState(() => _showMoreTransport = !_showMoreTransport),
          onChanged: (v) {
            _updateDraft((d) => d.copyWith(transportPreference: v));
            _onStepCompleted(_Step.transportPreference);
          },
        )),

        _sectionLabel('Languages'),
        _wrapWithKey(_Step.preferredLanguage, _chipSingleWithMore(
          options: optionLanguages,
          value: _draft.preferredLanguage,
          maxVisible: 7,
          isExpanded: _showMoreLanguages,
          circle: true,
          onToggleMore: () => setState(() => _showMoreLanguages = !_showMoreLanguages),
          onChanged: (v) {
            _updateDraft((d) => d.copyWith(preferredLanguage: v));
            _onStepCompleted(_Step.preferredLanguage);
          },
        )),
        _wrapWithKey(_Step.spokenLanguages, _selectRow(
          label: 'Spoken languages',
          value: _draft.spokenLanguages,
          accentColor: _accentLanguage,
          onTap: () => _openPickerAndSet(
            'Spoken Languages',
            optionLanguages,
            _draft.spokenLanguages,
            _accentLanguage,
            true,
            (d, sel) => d.copyWith(spokenLanguages: sel),
            onAfterCloseAdvanceStep: _Step.spokenLanguages,
          ),
        )),
      ],
    );
  }

  Widget _selectRow({
    required String label,
    required List<String> value,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final summary = value.isEmpty
        ? 'None selected'
        : value.length <= 2
            ? value.map(formatOptionLabel).join(', ')
            : '${value.take(2).map(formatOptionLabel).join(', ')} +${value.length - 2}';
    final borderColor = BookingSearchFieldStyles.fieldBorderInactive(context);
    final fill = BookingSearchFieldStyles.fieldFill(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: value.isEmpty ? cs.onSurfaceVariant : cs.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipSingleWithMore({
    required List<String> options,
    required String? value,
    required void Function(String) onChanged,
    required int maxVisible,
    required bool isExpanded,
    required VoidCallback onToggleMore,
    bool circle = false,
    int columns = 4,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visible = isExpanded ? options : options.take(maxVisible).toList();
    final hasMore = options.length > maxVisible;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        clipBehavior: Clip.hardEdge,
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 10.0;
            final colCount = columns.clamp(2, 6);
            final chipWidth = circle
                ? null
                : ((constraints.maxWidth - (gap * (colCount - 1))) / colCount)
                    .clamp(90.0, constraints.maxWidth);

            Widget buildChip({
              required String label,
              required bool selected,
              required VoidCallback onTap,
              bool isMore = false,
            }) {
            final borderColor = selected
                ? Colors.white.withValues(alpha: 0.35)
                : cs.outline.withValues(alpha: isDark ? 0.20 : 0.28);

            final base = GestureDetector(
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: circle ? 44 : chipWidth,
                height: circle ? 44 : 44,
                decoration: BoxDecoration(
                  color: selected ? _accentBlue : cs.surfaceContainerHighest,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(circle ? 999 : 14),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _accentBlue.withValues(alpha: 0.16),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      // Match segmented controls typography (Trip Pace / Activity Level).
                      fontSize: _optionFontSize,
                      fontWeight: _optionFontWeight,
                      letterSpacing: -0.2,
                      color: selected
                          ? Colors.white
                          : (isMore
                              ? _accentBlue
                              : cs.onSurfaceVariant.withValues(alpha: 0.72)),
                    ),
                  ),
                ),
              ),
            );

            return base;
          }

          final chips = <Widget>[
            ...visible.map((o) {
              final selected = value == o;
              return buildChip(
                label: formatOptionLabel(o),
                selected: selected,
                onTap: () => onChanged(o),
              );
            }),
            if (hasMore)
              buildChip(
                label: 'More...',
                selected: false,
                isMore: true,
                onTap: onToggleMore,
              ),
          ];

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: chips,
            );
          },
        ),
      ),
    );
  }

  // _singleChips removed; use _chipSingleWithMore/_chipSingle instead.

  Widget _segmented({
    required List<String> options,
    required String? value,
    required void Function(String) onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: options.map((o) {
        final selected = value == o;
        final borderColor = selected
            ? Colors.white.withValues(alpha: 0.35)
            : cs.outline.withValues(alpha: isDark ? 0.28 : 0.35);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: selected ? _accentBlue : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => onChanged(o),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      formatOptionLabel(o),
                      style: TextStyle(
                        fontSize: _optionFontSize,
                        fontWeight: _optionFontWeight,
                        letterSpacing: -0.2,
                        color: selected
                            ? Colors.white
                            : cs.onSurfaceVariant.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Row(
        children: [
          Expanded(
            child: ProfileSheetStyles.secondaryButton(
              context: context,
              text: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ProfileSheetStyles.primaryButton(
              context: context,
              text: 'Save',
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}
