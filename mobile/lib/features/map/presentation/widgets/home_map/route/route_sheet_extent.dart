import 'dart:async';

import 'package:flutter/material.dart';

import 'route_sheet_constants.dart';

void collapseRouteSheetForMap(
  DraggableScrollableController? extentController,
  ScrollController? scrollController,
) {
  if (scrollController != null && scrollController.hasClients) {
    scrollController.jumpTo(0);
  }
  if (extentController == null || !extentController.isAttached) return;
  final target = kRouteSheetPeekExtent.clamp(0.11, 0.94);
  unawaited(
    extentController.animateTo(
      target,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    ),
  );
}

void expandRouteSheetFromPeek(DraggableScrollableController? c) {
  if (c == null || !c.isAttached) return;
  if (c.size > kRouteSheetPeekInteractionThreshold) return;
  unawaited(
    c.animateTo(
      kRouteSheetExpandedExtent,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    ),
  );
}
