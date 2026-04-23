import 'package:flutter/material.dart';

import 'route_bottom_sheet_panel.dart';
import 'route_sheet_constants.dart';

/// Resizable route panel: pairs with [RouteBottomSheet] via [DraggableScrollableSheet].
class DraggableRouteBottomSheet extends StatefulWidget {
  final VoidCallback onClose;
  final bool initialEvents;

  const DraggableRouteBottomSheet({
    super.key,
    required this.onClose,
    this.initialEvents = false,
  });

  @override
  State<DraggableRouteBottomSheet> createState() =>
      _DraggableRouteBottomSheetState();
}

class _DraggableRouteBottomSheetState extends State<DraggableRouteBottomSheet> {
  final DraggableScrollableController _dragExtent =
      DraggableScrollableController();

  @override
  void dispose() {
    _dragExtent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _dragExtent,
      expand: true,
      initialChildSize: kRouteSheetExpandedExtent,
      minChildSize: 0.10,
      maxChildSize: 0.96,
      snap: false,
      builder: (context, scrollController) {
        return RouteBottomSheet(
          scrollController: scrollController,
          sheetExtentController: _dragExtent,
          initialEvents: widget.initialEvents,
          onClose: widget.onClose,
        );
      },
    );
  }
}
