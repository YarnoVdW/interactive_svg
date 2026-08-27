import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../../interactive_svg.dart';

/// Shared helpers used by both [InteractiveParser] and [NetworkInteractiveParser].
///
/// Extracts the two private methods that were duplicated verbatim in both parser
/// classes so that changes only need to be made in one place.
mixin SvgParserMixin {
  /// Parses the `viewBox` attribute from [context]'s root element and calls
  /// [onContextUpdated] with an updated context when successful.
  ///
  /// Does nothing when the root element is absent, the attribute is missing,
  /// or the value cannot be parsed as four space-separated numbers.
  void parseViewBox(
    InteractiveParseContext context,
    void Function(InteractiveParseContext updated) onContextUpdated,
  ) {
    final root = context.root;
    if (root == null) return;
    final viewBoxAttr = root.getAttribute('viewBox');
    if (viewBoxAttr == null) return;
    final parts = viewBoxAttr.split(' ').map((s) => double.tryParse(s) ?? 0).toList();
    if (parts.length == 4) {
      onContextUpdated(
        context.copyWith(
          viewBox: Rect.fromLTWH(parts[0], parts[1], parts[2], parts[3]),
        ),
      );
    }
  }

  /// Wraps [layer] inside a copy of [root] (preserving viewBox / attributes),
  /// optionally including the document-level `<defs>` element when the layer
  /// does not already define its own.
  ///
  /// Returns an [SvgRegion] whose `svg` field is the serialised XML string.
  SvgRegion convertLayerToSvg(
    InteractiveSelector selector,
    XmlNode layer,
    XmlElement root,
  ) {
    final defs = layer.getElement('defs') == null ? root.getElement('defs') : null;
    final element = XmlElement(
      root.name.copy(),
      root.attributes.map((e) => e.copy()).toList(),
      [if (defs != null) defs.copy(), layer.copy()],
      root.isSelfClosing,
    );
    return SvgRegion(selector: selector, svg: element.toString());
  }
}
