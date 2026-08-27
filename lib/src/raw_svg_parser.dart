import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../interactive_svg.dart';
import 'parsers/bounds_parser_utilities.dart';
import 'parsers/svg_parser_mixin.dart';

/// An [InteractiveParserDelegate] that works from an already-fetched SVG string.
///
/// Use this when you have already downloaded or generated the SVG content
/// elsewhere (e.g. via an HTTP call in your own code) and want to avoid a
/// second network round-trip inside the package.
///
/// Usage:
/// 1. Fetch the SVG string yourself (HTTP, asset bundle, generated, etc.).
/// 2. Pass it to [RawSvgParser] along with your [selectors].
/// 3. Hand the parser to [InteractiveSvgView] (or use the convenience
///    [InteractiveSvgView.fromString] factory).
///
/// [loadAssets] is a no-op because the content is already available; parsing
/// happens synchronously the first time [parseSvg] or [parseSvgBounds] is
/// called.
class RawSvgParser extends InteractiveParserDelegate with SvgParserMixin {
  /// Creates a [RawSvgParser] from a raw SVG [svgString].
  ///
  /// [svgString] - the full SVG XML content as a string.
  /// [selectors] - the interactive regions to extract.
  RawSvgParser({required this.svgString, this.selectors = const []}) {
    _init();
  }

  /// The raw SVG XML content.
  final String svgString;

  /// The list of selectors defining interactive regions.
  final Iterable<InteractiveSelector> selectors;

  InteractiveParseContext? _currentContext;

  void _init() {
    final document = XmlDocument.parse(svgString);
    final svg = document.findElements('svg').firstOrNull;
    _currentContext = InteractiveParseContext(root: svg, document: document);
    parseViewBox(_currentContext!, (updated) => _currentContext = updated);
  }

  @override
  bool get hasTouchableItem => selectors.any(
        (e) =>
            e.type == InteractiveType.touchable ||
            e.type == InteractiveType.boundsOnly,
      );

  /// No-op — the SVG string was provided at construction time.
  @override
  Future<void> loadAssets(BuildContext context) async {}

  @override
  RegionList parseSvg() {
    final context_ = _currentContext;
    assert(context_ != null, 'SVG string could not be parsed.');
    assert(context_!.document != null, 'SVG string could not be parsed.');
    assert(context_!.root != null, 'SVG string could not be parsed.');

    final regions = RegionList();
    final context = context_!;

    // Avoid editing the original document.
    final document = context.document!.copy();
    final root = context.root!.copy();

    for (final selector in selectors) {
      final group = selector(document);
      if (group == null) continue;
      group.remove();
      regions[selector] = convertLayerToSvg(selector, group, root);
    }
    regions[null] = SvgRegion(selector: null, svg: document.toString());
    return regions;
  }

  @override
  BoundsList parseSvgBounds(
    Size size, {
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.topLeft,
  }) {
    final context_ = _currentContext;
    assert(context_ != null, 'SVG string could not be parsed.');
    assert(context_!.document != null, 'SVG string could not be parsed.');
    assert(context_!.viewBox != null,
        'SVG is missing a viewBox attribute; bounds cannot be computed.',);

    final boundsRegions = BoundsList();
    final context = context_!;
    final document = context.document!;
    final viewBox = context.viewBox!;

    final touchableComponents = selectors.where(
      (e) =>
          e.type == InteractiveType.touchable ||
          e.type == InteractiveType.boundsOnly,
    );
    for (final selector in touchableComponents) {
      final group = selector(document);
      if (group == null) continue;
      final path = parseBoundsFromSvg(
        group,
        size: size,
        viewBox: viewBox,
        alignment: alignment,
        fit: fit,
      );
      if (path != null) {
        boundsRegions[selector] = SvgBounds(path: path, selector: selector);
      }
    }
    return boundsRegions;
  }

  /// Returns true when [svgString] or [selectors] differ from [other].
  @override
  bool isChanged(covariant InteractiveParserDelegate other) {
    if (other is! RawSvgParser) return true;
    return other.svgString != svgString ||
        !const DeepCollectionEquality().equals(other.selectors, selectors);
  }
}
