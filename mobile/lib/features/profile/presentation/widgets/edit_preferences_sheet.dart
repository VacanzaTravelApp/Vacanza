import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/theme/app_theme.dart';

import '../../data/models/user_preferences.dart';
import '../../data/profile_preference_options.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../styles/profile_sheet_styles.dart';
import 'searchable_multi_select_picker_sheet.dart';

class EditPreferencesSheet extends StatefulWidget {
  final UserPreferences initialPrefs;

  const EditPreferencesSheet({
    super.key,
    required this.initialPrefs,
  });

  @override
  State<EditPreferencesSheet> createState() => _EditPreferencesSheetState();
}

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

  static final int _stepCount = _Step.values.length;
  late final List<GlobalKey> _stepKeys;

  var _isAutoScrolling = false;
  DateTime? _lastAdvanceTime;
  static const _advanceDebounce = Duration(milliseconds: 250);
  static const _scrollDuration = Duration(milliseconds: 300);
  static const _scrollCurve = Curves.easeOut;
  static const _headerHeight = 68.0;
  static const _topInset = _headerHeight + 12.0;
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

  void _onBudgetFocusChange() {}

  // Steps grouped by card — scroll only advances within the same card.
  static const _cardGroups = [
    {_Step.travelStyle, _Step.activityLevel, _Step.tripPace},
    {_Step.favoriteCategories, _Step.cuisinePreferences, _Step.dietaryRestrictions},
    {_Step.dailyBudget, _Step.budgetCurrency},
    {_Step.accommodationType, _Step.transportPreference},
    {_Step.accessibilityNeeds, _Step.preferredLanguage, _Step.spokenLanguages},
  ];

  static bool _sameCard(_Step a, _Step b) =>
      _cardGroups.any((g) => g.contains(a) && g.contains(b));

  void _onStepCompleted(_Step step) {
    if (_isAutoScrolling) return;
    final now = DateTime.now();
    if (_lastAdvanceTime != null &&
        now.difference(_lastAdvanceTime!) < _advanceDebounce) { return; }
    _lastAdvanceTime = now;
    final index = step.index;
    if (index + 1 >= _stepCount) return;
    final next = _Step.values[index + 1];
    if (!_sameCard(step, next)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToStep(index + 1));
  }

  void _scrollToStep(int index) {
    if (!mounted) return;
    final keyIndex = index == _Step.budgetCurrency.index ? _Step.dailyBudget.index : index;
    final key = _stepKeys[keyIndex];
    final ctx = key.currentContext;
    if (ctx == null) return;
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
        final rawOffset = _scrollController.offset + (keyGlobal.dy - viewportGlobal.dy);
        final targetOffset = (rawOffset - _topInset)
            .clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.animateTo(targetOffset,
            duration: _scrollDuration, curve: _scrollCurve);
      } else {
        Scrollable.ensureVisible(ctx,
            duration: _scrollDuration, curve: _scrollCurve, alignment: _nonInputAlignment);
      }
    } else {
      Scrollable.ensureVisible(ctx,
          duration: _scrollDuration, curve: _scrollCurve, alignment: _nonInputAlignment);
    }
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _isAutoScrolling = false);
    });
  }

  Widget _wrapWithKey(_Step step, Widget child) =>
      Container(key: _stepKeys[step.index], child: child);

  UserPreferences _copyDraft(UserPreferences p) => p.copyWith(
        favoriteCategories: List.from(p.favoriteCategories),
        cuisinePreferences: List.from(p.cuisinePreferences),
        dietaryRestrictions: List.from(p.dietaryRestrictions),
        accessibilityNeeds: List.from(p.accessibilityNeeds),
        avoidCategories: List.from(p.avoidCategories),
        splurgeCategories: List.from(p.splurgeCategories),
        spokenLanguages: List.from(p.spokenLanguages),
      );

  void _updateDraft(UserPreferences Function(UserPreferences) fn) =>
      setState(() => _draft = fn(_draft));

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
        onDone: (selected) => setState(() => _draft = setter(_draft, selected)),
      ),
    ).then((_) {
      final step = onAfterCloseAdvanceStep;
      if (mounted && step != null) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _onStepCompleted(step));
      }
    });
  }

  void _save() {
    context
        .read<ProfileBloc>()
        .add(PreferencesUpdateRequested(widget.initialPrefs, _draft));
    if (mounted) Navigator.of(context).pop();
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
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTravelStyleCard(),
                  _buildInterestsCard(),
                  _buildBudgetCard(),
                  _buildStayAndTransportCard(),
                  _buildAccessibilityLanguageCard(),
                  const SizedBox(height: 4),
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
    final accent = context.mapControlAccent;
    final t = context.vacanzaTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filled = _countFilled();
    const total = 13;
    final pct = filled / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent,
                      Color.lerp(accent, Colors.black, 0.20) ?? accent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: isDark ? 0.28 : 0.34),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.tune_rounded, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Travel Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: t.textMain,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$filled of $total fields filled',
                      style: TextStyle(
                        fontSize: 12,
                        color: t.textSub.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: pct,
                      strokeWidth: 3.5,
                      backgroundColor: cs.outline.withValues(alpha: 0.12),
                      color: accent,
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '${(pct * 100).round()}%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? cs.surfaceContainerHighest : Colors.white,
                    border: Border.all(
                      color: cs.outline.withValues(alpha: isDark ? 0.30 : 0.18),
                    ),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: t.textSub,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 3,
              backgroundColor: cs.outline.withValues(alpha: 0.10),
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  int _countFilled() {
    int n = 0;
    if (_draft.travelStyle != null) n++;
    if (_draft.favoriteCategories.isNotEmpty) n++;
    if (_draft.activityLevel != null) n++;
    if (_draft.cuisinePreferences.isNotEmpty) n++;
    if (_draft.dietaryRestrictions.isNotEmpty) n++;
    if (_draft.dailyBudget != null) n++;
    if (_draft.budgetCurrency != null) n++;
    if (_draft.tripPace != null) n++;
    if (_draft.accommodationType != null) n++;
    if (_draft.transportPreference != null) n++;
    if (_draft.accessibilityNeeds.isNotEmpty) n++;
    if (_draft.preferredLanguage != null) n++;
    if (_draft.spokenLanguages.isNotEmpty) n++;
    return n;
  }

  // ── Group card builder ────────────────────────────────────────────────────

  Widget _groupCard({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? color.withValues(alpha: 0.18)
              : color.withValues(alpha: 0.14),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: color.withValues(alpha: 0.10),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        Color.lerp(color, Colors.black, 0.18) ?? color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: isDark ? 0.30 : 0.38),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: t.textMain,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: t.textSub.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: isDark
                ? color.withValues(alpha: 0.12)
                : color.withValues(alpha: 0.08),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    final t = context.vacanzaTokens;
    final accent = context.mapControlAccent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            margin: const EdgeInsets.only(right: 7),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: t.textMain.withValues(alpha: 0.72),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Group cards ───────────────────────────────────────────────────────────

  Widget _buildTravelStyleCard() {
    final accent = context.mapControlAccent;
    return _groupCard(
      icon: Icons.explore_rounded,
      color: accent,
      title: 'Travel Style',
      subtitle: 'How you like to travel',
      children: [
        _fieldLabel('Style'),
        _wrapWithKey(
          _Step.travelStyle,
          _chipGrid(
            options: optionTravelStyle,
            value: _draft.travelStyle,
            maxVisible: 6,
            isExpanded: _showMoreTravelStyle,
            onToggleMore: () =>
                setState(() => _showMoreTravelStyle = !_showMoreTravelStyle),
            onChanged: (v) {
              _updateDraft((d) => d.copyWith(travelStyle: v));
              _onStepCompleted(_Step.travelStyle);
            },
          ),
        ),
        const SizedBox(height: 12),
        _fieldLabel('Activity Level'),
        _wrapWithKey(
          _Step.activityLevel,
          _segmented(
            options: optionActivityLevel,
            value: _draft.activityLevel,
            onChanged: (v) {
              _updateDraft((d) => d.copyWith(activityLevel: v));
              _onStepCompleted(_Step.activityLevel);
            },
          ),
        ),
        const SizedBox(height: 12),
        _fieldLabel('Trip Pace'),
        _wrapWithKey(
          _Step.tripPace,
          _segmented(
            options: optionTripPace,
            value: _draft.tripPace,
            onChanged: (v) => _updateDraft((d) => d.copyWith(tripPace: v)),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsCard() {
    final accent = context.mapControlAccent;
    return _groupCard(
      icon: Icons.favorite_rounded,
      color: _accentCuisine,
      title: 'Interests & Food',
      subtitle: 'Used by AI to personalize your route',
      children: [
        _fieldLabel('Favorite Categories'),
        _wrapWithKey(
          _Step.favoriteCategories,
          _selectRow(
            placeholder: 'Select categories',
            value: _draft.favoriteCategories,
            accentColor: accent,
            onTap: () => _openPickerAndSet(
              'Favorite Categories',
              optionFavoriteCategories,
              _draft.favoriteCategories,
              accent,
              true,
              (d, sel) => d.copyWith(favoriteCategories: sel),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _fieldLabel('Cuisine Preferences'),
        _wrapWithKey(
          _Step.cuisinePreferences,
          _selectRow(
            placeholder: 'Select cuisines',
            value: _draft.cuisinePreferences,
            accentColor: _accentCuisine,
            onTap: () => _openPickerAndSet(
              'Cuisine Preferences',
              optionCuisinePreferences,
              _draft.cuisinePreferences,
              _accentCuisine,
              true,
              (d, sel) => d.copyWith(cuisinePreferences: sel),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _fieldLabelInline('Dietary Restrictions'),
            const Spacer(),
            Icon(Icons.bolt, size: 11, color: _accentDietary),
            const SizedBox(width: 3),
            Text(
              'AI filter',
              style: TextStyle(fontSize: 10, color: _accentDietary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _wrapWithKey(
          _Step.dietaryRestrictions,
          _selectRow(
            placeholder: 'Select restrictions',
            value: _draft.dietaryRestrictions,
            accentColor: _accentDietary,
            onTap: () => _openPickerAndSet(
              'Dietary Restrictions',
              optionDietaryRestrictions,
              _draft.dietaryRestrictions,
              _accentDietary,
              true,
              (d, sel) => d.copyWith(dietaryRestrictions: sel),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard() {
    return _groupCard(
      icon: Icons.account_balance_wallet_rounded,
      color: const Color(0xFF10B981),
      title: 'Daily Budget',
      subtitle: 'Per person, per day',
      children: [
        _wrapWithKey(
          _Step.dailyBudget,
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _budgetController,
                  focusNode: _budgetFocusNode,
                  keyboardType: TextInputType.number,
                  decoration: ProfileSheetStyles.inputDecoration(context, 'e.g. 150'),
                  onChanged: (s) {
                    final v = num.tryParse(s);
                    _updateDraft((d) => d.copyWith(dailyBudget: v));
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  key: ValueKey<String?>(_draft.budgetCurrency),
                  initialValue: _draft.budgetCurrency ?? 'EUR',
                  decoration: ProfileSheetStyles.inputDecoration(context, ''),
                  items: optionBudgetCurrency
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => _updateDraft((d) => d.copyWith(budgetCurrency: v)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStayAndTransportCard() {
    return _groupCard(
      icon: Icons.hotel_rounded,
      color: const Color(0xFF6366F1),
      title: 'Stay & Getting Around',
      children: [
        _fieldLabel('Accommodation'),
        _wrapWithKey(
          _Step.accommodationType,
          _chipGrid(
            options: optionAccommodationType,
            value: _draft.accommodationType,
            maxVisible: 4,
            isExpanded: _showMoreAccommodation,
            onToggleMore: () => setState(
                () => _showMoreAccommodation = !_showMoreAccommodation),
            onChanged: (v) {
              _updateDraft((d) => d.copyWith(accommodationType: v));
              _onStepCompleted(_Step.accommodationType);
            },
          ),
        ),
        const SizedBox(height: 12),
        _fieldLabel('Transport'),
        _wrapWithKey(
          _Step.transportPreference,
          _chipGrid(
            options: optionTransportPreference,
            value: _draft.transportPreference,
            maxVisible: 4,
            isExpanded: _showMoreTransport,
            onToggleMore: () =>
                setState(() => _showMoreTransport = !_showMoreTransport),
            onChanged: (v) => _updateDraft((d) => d.copyWith(transportPreference: v)),
          ),
        ),
      ],
    );
  }

  Widget _buildAccessibilityLanguageCard() {
    return _groupCard(
      icon: Icons.accessibility_new_rounded,
      color: _accentAccessibility,
      title: 'Accessibility & Language',
      children: [
        _fieldLabel('Accessibility Needs'),
        _wrapWithKey(
          _Step.accessibilityNeeds,
          _selectRow(
            placeholder: 'Select accessibility needs',
            value: _draft.accessibilityNeeds,
            accentColor: _accentAccessibility,
            onTap: () => _openPickerAndSet(
              'Accessibility Needs',
              optionAccessibilityNeeds,
              _draft.accessibilityNeeds,
              _accentAccessibility,
              false,
              (d, sel) => d.copyWith(accessibilityNeeds: sel),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _fieldLabel('Preferred Language'),
        _wrapWithKey(
          _Step.preferredLanguage,
          _languageToggle(
            options: optionLanguages,
            value: _draft.preferredLanguage,
            onChanged: (v) {
              _updateDraft((d) => d.copyWith(preferredLanguage: v));
              _onStepCompleted(_Step.preferredLanguage);
            },
          ),
        ),
        const SizedBox(height: 12),
        _fieldLabel('Spoken Languages'),
        _wrapWithKey(
          _Step.spokenLanguages,
          _selectRow(
            placeholder: 'Select languages',
            value: _draft.spokenLanguages,
            accentColor: _accentLanguage,
            onTap: () => _openPickerAndSet(
              'Spoken Languages',
              optionLanguages,
              _draft.spokenLanguages,
              _accentLanguage,
              true,
              (d, sel) => d.copyWith(spokenLanguages: sel),
            ),
          ),
        ),
      ],
    );
  }

  // ── Field widgets ─────────────────────────────────────────────────────────

  Widget _fieldLabelInline(String text) {
    final t = context.vacanzaTokens;
    final accent = context.mapControlAccent;
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          margin: const EdgeInsets.only(right: 7),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: t.textMain.withValues(alpha: 0.72),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _selectRow({
    required String placeholder,
    required List<String> value,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEmpty = value.isEmpty;
    final summary = isEmpty
        ? placeholder
        : value.length <= 3
            ? value.map(formatOptionLabel).join(', ')
            : '${value.take(3).map(formatOptionLabel).join(', ')} +${value.length - 3}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isEmpty
              ? (isDark ? cs.surfaceContainerHighest : Colors.white)
              : accentColor.withValues(alpha: isDark ? 0.10 : 0.05),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isEmpty
                ? t.cardBorder.withValues(alpha: isDark ? 0.70 : 1.0)
                : accentColor.withValues(alpha: isDark ? 0.45 : 0.55),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: isEmpty
                        ? Colors.black.withValues(alpha: 0.04)
                        : accentColor.withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            if (!isEmpty)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 9),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
            Expanded(
              child: Text(
                summary,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w600,
                  color: isEmpty
                      ? t.textSub.withValues(alpha: 0.42)
                      : t.textMain,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isEmpty
                  ? t.textSub.withValues(alpha: 0.32)
                  : accentColor.withValues(alpha: 0.75),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmented({
    required List<String> options,
    required String? value,
    required void Function(String) onChanged,
  }) {
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: options.map((o) {
        final selected = value == o;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: o == options.last ? 0 : 6,
            ),
            child: GestureDetector(
              onTap: () => onChanged(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? accent
                      : isDark
                          ? cs.surfaceContainerHighest
                          : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.25)
                        : t.cardBorder.withValues(alpha: isDark ? 0.7 : 1.0),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                ),
                child: Center(
                  child: Text(
                    formatOptionLabel(o),
                    style: TextStyle(
                      fontSize: _optionFontSize,
                      fontWeight: _optionFontWeight,
                      color: selected
                          ? Colors.white
                          : t.textSub,
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

  Widget _chipGrid({
    required List<String> options,
    required String? value,
    required void Function(String) onChanged,
    required int maxVisible,
    required bool isExpanded,
    required VoidCallback onToggleMore,
  }) {
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visible = isExpanded ? options : options.take(maxVisible).toList();
    final hasMore = options.length > maxVisible;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.hardEdge,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...visible.map((o) {
            final selected = value == o;
            return GestureDetector(
              onTap: () => onChanged(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: selected
                      ? accent
                      : isDark
                          ? cs.surfaceContainerHighest
                          : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.25)
                        : t.cardBorder.withValues(alpha: isDark ? 0.7 : 1.0),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selected) ...[
                      Icon(Icons.check_rounded,
                          size: 13, color: Colors.white),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      formatOptionLabel(o),
                      style: TextStyle(
                        fontSize: _optionFontSize,
                        fontWeight: _optionFontWeight,
                        color: selected ? Colors.white : t.textSub,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (hasMore)
            GestureDetector(
              onTap: onToggleMore,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.40),
                  ),
                ),
                child: Text(
                  isExpanded ? 'Less' : 'More...',
                  style: TextStyle(
                    fontSize: _optionFontSize,
                    fontWeight: _optionFontWeight,
                    color: accent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _languageToggle({
    required List<String> options,
    required String? value,
    required void Function(String) onChanged,
  }) {
    final t = context.vacanzaTokens;
    final cs = Theme.of(context).colorScheme;
    final accent = context.mapControlAccent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final labels = {'en': 'English', 'tr': 'Türkçe'};

    return Row(
      children: options.map((o) {
        final selected = value == o;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: o == options.last ? 0 : 8),
            child: GestureDetector(
              onTap: () => onChanged(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? accent
                      : isDark
                          ? cs.surfaceContainerHighest
                          : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.25)
                        : t.cardBorder.withValues(alpha: isDark ? 0.7 : 1.0),
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                ),
                child: Center(
                  child: Text(
                    labels[o] ?? formatOptionLabel(o),
                    style: TextStyle(
                      fontSize: _optionFontSize,
                      fontWeight: _optionFontWeight,
                      color: selected ? Colors.white : t.textSub,
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
