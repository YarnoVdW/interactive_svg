import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:interactive_svg/interactive_svg.dart';
import 'package:xml/xml.dart';

import 'parsers/bounds_parser_utilities.dart';

class NetworkInteractiveParser extends InteractiveParserDelegate {
  NetworkInteractiveParser({required this.url, this.selectors = const []});

  final String url;
  final Iterable<InteractiveSelector> selectors;

  InteractiveParseContext? _currentContext;
  bool _lock = false;

  @override
  bool get hasTouchableItem => selectors.any(
        (e) =>
            e.type == InteractiveType.touchable ||
            e.type == InteractiveType.boundsOnly,
      );

  @override
  Future<void> loadAssets(BuildContext context) async {
    if (_lock) return;
    _lock = true;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to load SVG from $url: ${response.statusCode}');
      }
      final svgString = response.body;

      final document = XmlDocument.parse(svgString);
      final svg = document.findElements('svg').firstOrNull;
      _currentContext = InteractiveParseContext(root: svg, document: document);
      _parseViewBox(_currentContext!);
    } finally {
      _lock = false;
    }
  }

  void _parseViewBox(InteractiveParseContext context) {
    if (context.root == null) {
      return;
    }
    final viewBox = context.root!.getAttribute('viewBox');
    if (viewBox == null) {
      return;
    }
    // Parse viewBox to get dimensions
    final viewBoxParts =
        viewBox.split(' ').map((s) => double.tryParse(s) ?? 0).toList();
    if (viewBoxParts.length == 4) {
      final rect = Rect.fromLTWH(
        viewBoxParts[0],
        viewBoxParts[1],
        viewBoxParts[2],
        viewBoxParts[3],
      );
      _currentContext = context.copyWith(viewBox: rect);
    }
  }

  @override
  bool isChanged(covariant InteractiveParserDelegate other) {
    if (other is! NetworkInteractiveParser) return true;
    return other.url != url ||
        !const DeepCollectionEquality().equals(other.selectors, selectors);
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
      if (group == null) {
        continue;
      }
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

  @override
  RegionList parseSvg() {
    assert(!_lock, 'Please call loadAssets first and wait until it completes.');

    final context_ = _currentContext;
    assert(context_ != null, 'Please call loadAssets first.');
    assert(context_!.document != null, 'Please call loadAssets first.');
    assert(context_!.root != null, 'Please call loadAssets first.');

    final regions = RegionList();
    final context = context_!;

    /// Avoid editing on the original document
    final document = context.document!.copy();
    final root = context.root!.copy();

    for (final selector in selectors) {
      final group = selector(document);
      if (group == null) {
        continue;
      }
      group.remove();
      final region = _convertLayerToSvg(selector, group, root);
      regions[selector] = region;
    }
    regions[null] = SvgRegion(selector: null, svg: document.toString());
    return regions;
  }

  SvgRegion _convertLayerToSvg(
    InteractiveSelector selector,
    XmlNode layer,
    XmlElement root,
  ) {
    final defs =
        layer.getElement('defs') == null ? root.getElement('defs') : null;
    final element = XmlElement(
      root.name.copy(),
      root.attributes.map((e) => e.copy()).toList(),
      [if (defs != null) defs.copy(), layer.copy()],
      root.isSelfClosing,
    );
    return SvgRegion(selector: selector, svg: element.toString());
  }
}
