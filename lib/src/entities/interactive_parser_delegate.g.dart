// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'interactive_parser_delegate.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InteractiveParseContextCWProxy {
  InteractiveParseContext root(XmlElement? root);

  InteractiveParseContext document(XmlDocument? document);

  InteractiveParseContext viewBox(Rect? viewBox);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `InteractiveParseContext(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// InteractiveParseContext(...).copyWith(id: 12, name: "My name")
  /// ````
  InteractiveParseContext call({
    XmlElement? root,
    XmlDocument? document,
    Rect? viewBox,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfInteractiveParseContext.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfInteractiveParseContext.copyWith.fieldName(...)`
class _$InteractiveParseContextCWProxyImpl
    implements _$InteractiveParseContextCWProxy {
  const _$InteractiveParseContextCWProxyImpl(this._value);

  final InteractiveParseContext _value;

  @override
  InteractiveParseContext root(XmlElement? root) => this(root: root);

  @override
  InteractiveParseContext document(XmlDocument? document) =>
      this(document: document);

  @override
  InteractiveParseContext viewBox(Rect? viewBox) => this(viewBox: viewBox);

  @override

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `InteractiveParseContext(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// InteractiveParseContext(...).copyWith(id: 12, name: "My name")
  /// ````
  InteractiveParseContext call({
    Object? root = const $CopyWithPlaceholder(),
    Object? document = const $CopyWithPlaceholder(),
    Object? viewBox = const $CopyWithPlaceholder(),
  }) => InteractiveParseContext(
      root: root == const $CopyWithPlaceholder()
          ? _value.root
          // ignore: cast_nullable_to_non_nullable
          : root as XmlElement?,
      document: document == const $CopyWithPlaceholder()
          ? _value.document
          // ignore: cast_nullable_to_non_nullable
          : document as XmlDocument?,
      viewBox: viewBox == const $CopyWithPlaceholder()
          ? _value.viewBox
          // ignore: cast_nullable_to_non_nullable
          : viewBox as Rect?,
    );
}

extension $InteractiveParseContextCopyWith on InteractiveParseContext {
  /// Returns a callable class that can be used as follows: `instanceOfInteractiveParseContext.copyWith(...)` or like so:`instanceOfInteractiveParseContext.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InteractiveParseContextCWProxy get copyWith =>
      _$InteractiveParseContextCWProxyImpl(this);
}
