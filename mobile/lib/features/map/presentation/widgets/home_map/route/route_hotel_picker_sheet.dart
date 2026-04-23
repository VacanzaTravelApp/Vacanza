import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/ai/data/api/ai_route_api_client.dart';

class RouteHotelPickerSheet extends StatefulWidget {
  final String routeId;
  final String? defaultDestination;

  const RouteHotelPickerSheet({
    super.key,
    required this.routeId,
    this.defaultDestination,
  });

  static Future<void> show(
    BuildContext context, {
    required String routeId,
    String? defaultDestination,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => RouteHotelPickerSheet(
            routeId: routeId,
            defaultDestination: defaultDestination,
          ),
    );
  }

  @override
  State<RouteHotelPickerSheet> createState() => _RouteHotelPickerSheetState();
}

class _RouteHotelPickerSheetState extends State<RouteHotelPickerSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _addressCtrl = TextEditingController(text: widget.defaultDestination ?? '');
    _nameCtrl.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      await context.read<AiRouteApiClient>().setRouteHotel(
        routeId: widget.routeId,
        hotel: RouteHotelPayload(
          hotelName: name,
          address: _addressCtrl.text.trim().isEmpty
              ? null
              : _addressCtrl.text.trim(),
          providerName: 'Manual',
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final cs = Theme.of(context).colorScheme;
    final t = context.vacanzaTokens;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = context.mapControlAccent;

    final panelColor = isLight
        ? context.lightGlassPanelColor.withValues(alpha: 0.98)
        : cs.surface.withValues(alpha: 0.98);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboard),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: isLight ? 14 : 0, sigmaY: isLight ? 14 : 0),
          child: Container(
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: isLight ? accent.withValues(alpha: 0.18) : t.cardBorder.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 34,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: t.textSub.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Add Hotel',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: t.textMain,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _saving ? null : () => Navigator.of(context).pop(),
                          child: Icon(
                            CupertinoIcons.xmark,
                            size: 22,
                            color: t.textSub,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _Field(
                      label: 'Hotel / place name *',
                      child: TextField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        enabled: !_saving,
                        decoration: InputDecoration(
                          hintText: 'e.g. Grand Hyatt Paris',
                          filled: true,
                          fillColor: isLight ? context.lightGlassFieldFill : cs.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: t.cardBorder.withValues(alpha: 0.6)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: t.cardBorder.withValues(alpha: 0.45)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: accent.withValues(alpha: 0.9), width: 1.4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _Field(
                      label: 'Address (optional)',
                      child: TextField(
                        controller: _addressCtrl,
                        enabled: !_saving,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saving ? null : _save(),
                        decoration: InputDecoration(
                          hintText: 'Search address or type manually',
                          filled: true,
                          fillColor: isLight ? context.lightGlassFieldFill : cs.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: t.cardBorder.withValues(alpha: 0.6)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: t.cardBorder.withValues(alpha: 0.45)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: accent.withValues(alpha: 0.9), width: 1.4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: accent.withValues(alpha: 0.16),
                      disabledColor: accent.withValues(alpha: 0.08),
                      onPressed: (_nameCtrl.text.trim().isEmpty || _saving)
                          ? null
                          : _save,
                      child: Text(
                        _saving ? 'Saving…' : 'Save Hotel',
                        style: TextStyle(
                          color: accent,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final Widget child;

  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = context.vacanzaTokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: t.textSub,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

