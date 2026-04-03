import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  advancedToggle,
  tripPace,
  accommodationType,
  transportPreference,
  preferredClimate,
  accessibilityNeeds,
  avoidCategories,
  splurgeCategories,
  preferredLanguage,
  spokenLanguages,
}

class _EditPreferencesSheetState extends State<EditPreferencesSheet> {
  late UserPreferences _draft;
  var _advancedOpen = false;
  late TextEditingController _budgetController;
  late ScrollController _scrollController;
  late FocusNode _budgetFocusNode;

  static const _stepCount = 17;
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

  static const _accentBlue = Color(0xFF0096FF);
  static const _accentCuisine = Color(0xFFF4A261);
  static const _accentDietary = Color(0xFFFF6B6B);
  static const _accentAccessibility = Color(0xFF9C27B0);
  static const _accentLanguage = Color(0xFF2ECC71);

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
    // Step 7 = advancedToggle: expand Advanced then scroll to TripPace (8).
    if (index == _Step.advancedToggle.index && !_advancedOpen) {
      setState(() => _advancedOpen = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToStep(_Step.tripPace.index);
      });
      return;
    }
    if (index == _Step.advancedToggle.index) {
      _scrollToStep(_Step.tripPace.index);
      return;
    }
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
    return ProfileSheetStyles.sheetPanel(
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
                  _buildBasicsSection(),
                  _buildAdvancedSection(),
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
                'Edit Preferences',
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
      padding: const EdgeInsets.only(top: 16, bottom: 8),
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

  Widget _buildBasicsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            'BASICS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _accentBlue,
              letterSpacing: 1.2,
            ),
          ),
        ),
        _sectionLabel('Travel Style'),
        _wrapWithKey(_Step.travelStyle, _singleChips(
          options: optionTravelStyle,
          value: _draft.travelStyle,
          onChanged: (v) {
            _updateDraft((d) => d.copyWith(travelStyle: v));
            _onStepCompleted(_Step.travelStyle);
          },
        )),
        _sectionLabel('Favorite Categories'),
        _chipPreview(_draft.favoriteCategories, _accentBlue),
        _wrapWithKey(_Step.favoriteCategories, _selectRow(
          label: 'Select categories',
          value: _draft.favoriteCategories,
          accentColor: _accentBlue,
          onTap: () => _openPickerAndSet(
            'Favorite Categories',
            optionFavoriteCategories,
            _draft.favoriteCategories,
            _accentBlue,
            true,
            (d, sel) => d.copyWith(favoriteCategories: sel),
            onAfterCloseAdvanceStep: _Step.favoriteCategories,
          ),
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
        _chipPreview(_draft.cuisinePreferences, _accentCuisine),
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
                'Used by AI to filter recommendations',
                style: TextStyle(
                  fontSize: 10,
                  color: _accentBlue,
                ),
              ),
            ],
          ),
        ),
        _chipPreview(_draft.dietaryRestrictions, _accentDietary),
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
        _sectionLabel('Daily Budget'),
        _wrapWithKey(_Step.dailyBudget, Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _budgetController,
                focusNode: _budgetFocusNode,
                keyboardType: TextInputType.number,
                decoration: ProfileSheetStyles.inputDecoration('150'),
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
                decoration: ProfileSheetStyles.inputDecoration(''),
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
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        InkWell(
          onTap: () => setState(() => _advancedOpen = !_advancedOpen),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ADVANCED PREFERENCES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 1.2,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _advancedOpen ? 'Hide' : 'Show',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Icon(
                      _advancedOpen ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_advancedOpen) ...[
          _sectionLabel('Trip Pace'),
          _wrapWithKey(_Step.tripPace, _segmented(
            options: optionTripPace,
            value: _draft.tripPace,
            onChanged: (v) {
              _updateDraft((d) => d.copyWith(tripPace: v));
              _onStepCompleted(_Step.tripPace);
            },
          )),
          _sectionLabel('Accommodation Type'),
          _wrapWithKey(_Step.accommodationType, _singleChips(
            options: optionAccommodationType,
            value: _draft.accommodationType,
            onChanged: (v) {
              _updateDraft((d) => d.copyWith(accommodationType: v));
              _onStepCompleted(_Step.accommodationType);
            },
          )),
          _sectionLabel('Transport Preference'),
          _wrapWithKey(_Step.transportPreference, _singleChips(
            options: optionTransportPreference,
            value: _draft.transportPreference,
            onChanged: (v) {
              _updateDraft((d) => d.copyWith(transportPreference: v));
              _onStepCompleted(_Step.transportPreference);
            },
          )),
          _sectionLabel('Preferred Climate'),
          _wrapWithKey(_Step.preferredClimate, _singleChips(
            options: optionPreferredClimate,
            value: _draft.preferredClimate,
            onChanged: (v) {
              _updateDraft((d) => d.copyWith(preferredClimate: v));
              _onStepCompleted(_Step.preferredClimate);
            },
          )),
          _sectionLabel('Accessibility Needs'),
          _chipPreview(_draft.accessibilityNeeds, _accentAccessibility),
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
          _sectionLabel('Avoid Categories'),
          _chipPreview(_draft.avoidCategories, Colors.grey),
          _wrapWithKey(_Step.avoidCategories, _selectRow(
            label: 'Select categories to avoid',
            value: _draft.avoidCategories,
            accentColor: Colors.grey,
            onTap: () => _openPickerAndSet(
              'Avoid Categories',
              optionAvoidCategories,
              _draft.avoidCategories,
              Colors.grey,
              true,
              (d, sel) => d.copyWith(avoidCategories: sel),
              onAfterCloseAdvanceStep: _Step.avoidCategories,
            ),
          )),
          _sectionLabel('Splurge Categories'),
          _chipPreview(_draft.splurgeCategories, Colors.grey),
          _wrapWithKey(_Step.splurgeCategories, _selectRow(
            label: 'Select categories to splurge on',
            value: _draft.splurgeCategories,
            accentColor: Colors.grey,
            onTap: () => _openPickerAndSet(
              'Splurge Categories',
              optionSplurgeCategories,
              _draft.splurgeCategories,
              Colors.grey,
              true,
              (d, sel) => d.copyWith(splurgeCategories: sel),
              onAfterCloseAdvanceStep: _Step.splurgeCategories,
            ),
          )),
          _sectionLabel('Preferred Language'),
          _wrapWithKey(_Step.preferredLanguage, _singleChips(
            options: optionLanguages,
            value: _draft.preferredLanguage,
            onChanged: (v) {
              _updateDraft((d) => d.copyWith(preferredLanguage: v));
              _onStepCompleted(_Step.preferredLanguage);
            },
          )),
          _sectionLabel('Spoken Languages'),
          _chipPreview(_draft.spokenLanguages, _accentLanguage),
          _wrapWithKey(_Step.spokenLanguages, _selectRow(
            label: 'Select spoken languages',
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
      ],
    );
  }

  Widget _chipPreview(List<String> value, Color accentColor) {
    if (value.isEmpty) return const SizedBox.shrink();
    final show = value.take(3).toList();
    final extra = value.length - 3;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ...show.map(
            (v) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                formatOptionLabel(v),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (extra > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+$extra',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _selectRow({
    required String label,
    required List<String> value,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final summary = value.isEmpty
        ? 'None selected'
        : value.length <= 2
            ? value.map(formatOptionLabel).join(', ')
            : '${value.take(2).map(formatOptionLabel).join(', ')} +${value.length - 2}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        summary,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: value.isEmpty
                              ? Colors.grey.shade500
                              : accentColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _singleChips({
    required List<String> options,
    required String? value,
    required void Function(String) onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final selected = value == o;
        return GestureDetector(
          onTap: () => onChanged(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _accentBlue : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _accentBlue.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              formatOptionLabel(o),
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _segmented({
    required List<String> options,
    required String? value,
    required void Function(String) onChanged,
  }) {
    return Row(
      children: options.map((o) {
        final selected = value == o;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: selected ? _accentBlue : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => onChanged(o),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      formatOptionLabel(o),
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : Colors.grey.shade700,
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
              text: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ProfileSheetStyles.primaryButton(
              text: 'Save',
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}
