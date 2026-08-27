import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../interactive_svg.dart';
import 'parsers/bounds_parser_utilities.dart';
import 'parsers/svg_parser_mixin.dart';

/// A [InteractiveParserDelegate] that loads an SVG from a remote URL.
///
/// Usage:
/// 1. Call [loadAssets] with a [BuildContext] to download and parse the SVG.
/// 2. Call [parseSvg] to obtain per-selector SVG fragments.
/// 3. Call [parseSvgBounds] with the rendered widget [Size] to obtain
///    path-based bounds for touchable selectors.
///
/// Throws an [Exception] when the server returns a non-200 status code.
class NetworkInteractiveParser extends InteractiveParserDelegate
    with SvgParserMixin {
  /// Creates a [NetworkInteractiveParser] for [url].
  ///
  /// [url] must point directly to an SVG file (e.g. a CDN link).
  /// [selectors] define the interactive regions to extract.
  NetworkInteractiveParser({required this.url, this.selectors = const []});

  /// The URL of the remote SVG file.
  final String url;

  /// The list of selectors defining interactive regions.
  final Iterable<InteractiveSelector> selectors;

  InteractiveParseContext? _currentContext;
  bool _lock = false;

  @override
  bool get hasTouchableItem => selectors.any(
        (e) =>
            e.type == InteractiveType.touchable ||
            e.type == InteractiveType.boundsOnly,
      );

  /// Downloads the SVG from [url] and parses its XML document.
  ///
  /// Must be awaited before calling [parseSvg] or [parseSvgBounds].
  @override
  Future<void> loadAssets(BuildContext context) async {
    if (_lock) return;
    _lock = true;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load SVG from $url: HTTP ${response.statusCode}',
        );
      }
      final document = XmlDocument.parse(response.body);
      final svg = document.findElements('svg').firstOrNull;
      _currentContext = InteractiveParseContext(root: svg, document: document);
      parseViewBox(_currentContext!, (updated) => _currentContext = updated);
    } finally {
      _lock = false;
    }
  }

  @override
  RegionList parseSvg() {
    assert(!_lock, 'Please call loadAssets first and wait until it completes.');

    final context_ = _currentContext;
    assert(context_ != null, 'Please call loadAssets first.');
    assert(context_!.document != null, 'Please call loadAssets first.');
    assert(context_!.root != null, 'Please call loadAssets first.');

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
    assert(!_lock, 'Please call loadAssets first and wait until it completes.');

    final context_ = _currentContext;
    assert(context_ != null, 'Please call loadAssets first.');
    assert(context_!.document != null, 'Please call loadAssets first.');
    assert(context_!.viewBox != null, 'Please call loadAssets first.');

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

  /// Returns true when [url] or [selectors] differ from [other].
  @override
  bool isChanged(covariant InteractiveParserDelegate other) {
    if (other is! NetworkInteractiveParser) return true;
    return other.url != url ||
        !const DeepCollectionEquality().equals(other.selectors, selectors);
  }
}
