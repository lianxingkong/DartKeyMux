// This is a generated file - do not edit.
//
// Generated from keymux.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'keymux.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'keymux.pbenum.dart';

class keyInput extends $pb.GeneratedMessage {
  factory keyInput({
    $core.String? key,
    $core.bool? isRune,
    $core.bool? isPressed,
  }) {
    final result = keyInput._();
    if (key != null) result.key = key;
    if (isRune != null) result.isRune = isRune;
    if (isPressed != null) result.isPressed = isPressed;
    return result;
  }

  keyInput._();

  factory keyInput.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      keyInput()..mergeFromBuffer(data, registry);
  factory keyInput.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      keyInput()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'keyInput',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'GoKeyMux'),
      createEmptyInstance: keyInput.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOB(2, _omitFieldNames ? '' : 'isRune', protoName: 'isRune')
    ..aOB(3, _omitFieldNames ? '' : 'isPressed', protoName: 'isPressed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  keyInput clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  keyInput copyWith(void Function(keyInput) updates) =>
      super.copyWith((message) => updates(message as keyInput)) as keyInput;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use keyInput() / keyInput.new instead')
  static keyInput create() => keyInput._();
  static $pb.GeneratedMessage $_createMessage() => keyInput._();
  @$core.override
  keyInput createEmptyInstance() => keyInput._();
  @$core.pragma('dart2js:noInline')
  static keyInput getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<keyInput>(keyInput.$_createMessage);
  static keyInput? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get isRune => $_getBF(1);
  @$pb.TagNumber(2)
  set isRune($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsRune() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsRune() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get isPressed => $_getBF(2);
  @$pb.TagNumber(3)
  set isPressed($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsPressed() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsPressed() => $_clearField(3);
}

class keyReturn extends $pb.GeneratedMessage {
  factory keyReturn({
    $core.bool? isAllDone,
    $core.String? metaData,
  }) {
    final result = keyReturn._();
    if (isAllDone != null) result.isAllDone = isAllDone;
    if (metaData != null) result.metaData = metaData;
    return result;
  }

  keyReturn._();

  factory keyReturn.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      keyReturn()..mergeFromBuffer(data, registry);
  factory keyReturn.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      keyReturn()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'keyReturn',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'GoKeyMux'),
      createEmptyInstance: keyReturn.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'isAllDone', protoName: 'isAllDone')
    ..aOS(2, _omitFieldNames ? '' : 'metaData', protoName: 'metaData')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  keyReturn clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  keyReturn copyWith(void Function(keyReturn) updates) =>
      super.copyWith((message) => updates(message as keyReturn)) as keyReturn;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use keyReturn() / keyReturn.new instead')
  static keyReturn create() => keyReturn._();
  static $pb.GeneratedMessage $_createMessage() => keyReturn._();
  @$core.override
  keyReturn createEmptyInstance() => keyReturn._();
  @$core.pragma('dart2js:noInline')
  static keyReturn getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<keyReturn>(keyReturn.$_createMessage);
  static keyReturn? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get isAllDone => $_getBF(0);
  @$pb.TagNumber(1)
  set isAllDone($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIsAllDone() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsAllDone() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get metaData => $_getSZ(1);
  @$pb.TagNumber(2)
  set metaData($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMetaData() => $_has(1);
  @$pb.TagNumber(2)
  void clearMetaData() => $_clearField(2);
}

class keyInputDebug extends $pb.GeneratedMessage {
  factory keyInputDebug({
    $core.String? key,
    $core.bool? isRune,
    $core.bool? isPressed,
    $core.String? timeStamp,
    $core.String? metaData,
  }) {
    final result = keyInputDebug._();
    if (key != null) result.key = key;
    if (isRune != null) result.isRune = isRune;
    if (isPressed != null) result.isPressed = isPressed;
    if (timeStamp != null) result.timeStamp = timeStamp;
    if (metaData != null) result.metaData = metaData;
    return result;
  }

  keyInputDebug._();

  factory keyInputDebug.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      keyInputDebug()..mergeFromBuffer(data, registry);
  factory keyInputDebug.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      keyInputDebug()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'keyInputDebug',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'GoKeyMux'),
      createEmptyInstance: keyInputDebug.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..aOB(2, _omitFieldNames ? '' : 'isRune', protoName: 'isRune')
    ..aOB(3, _omitFieldNames ? '' : 'isPressed', protoName: 'isPressed')
    ..aOS(4, _omitFieldNames ? '' : 'timeStamp', protoName: 'timeStamp')
    ..aOS(5, _omitFieldNames ? '' : 'metaData', protoName: 'metaData')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  keyInputDebug clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  keyInputDebug copyWith(void Function(keyInputDebug) updates) =>
      super.copyWith((message) => updates(message as keyInputDebug))
          as keyInputDebug;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use keyInputDebug() / keyInputDebug.new instead')
  static keyInputDebug create() => keyInputDebug._();
  static $pb.GeneratedMessage $_createMessage() => keyInputDebug._();
  @$core.override
  keyInputDebug createEmptyInstance() => keyInputDebug._();
  @$core.pragma('dart2js:noInline')
  static keyInputDebug getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<keyInputDebug>(
          keyInputDebug.$_createMessage);
  static keyInputDebug? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get isRune => $_getBF(1);
  @$pb.TagNumber(2)
  set isRune($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsRune() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsRune() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get isPressed => $_getBF(2);
  @$pb.TagNumber(3)
  set isPressed($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIsPressed() => $_has(2);
  @$pb.TagNumber(3)
  void clearIsPressed() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get timeStamp => $_getSZ(3);
  @$pb.TagNumber(4)
  set timeStamp($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTimeStamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearTimeStamp() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get metaData => $_getSZ(4);
  @$pb.TagNumber(5)
  set metaData($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMetaData() => $_has(4);
  @$pb.TagNumber(5)
  void clearMetaData() => $_clearField(5);
}

class keyReturnDebug extends $pb.GeneratedMessage {
  factory keyReturnDebug({
    $core.bool? isFinished,
    $core.String? key,
    $core.String? timeStamp,
  }) {
    final result = keyReturnDebug._();
    if (isFinished != null) result.isFinished = isFinished;
    if (key != null) result.key = key;
    if (timeStamp != null) result.timeStamp = timeStamp;
    return result;
  }

  keyReturnDebug._();

  factory keyReturnDebug.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      keyReturnDebug()..mergeFromBuffer(data, registry);
  factory keyReturnDebug.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      keyReturnDebug()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'keyReturnDebug',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'GoKeyMux'),
      createEmptyInstance: keyReturnDebug.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'isFinished', protoName: 'isFinished')
    ..aOS(2, _omitFieldNames ? '' : 'key')
    ..aOS(3, _omitFieldNames ? '' : 'timeStamp', protoName: 'timeStamp')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  keyReturnDebug clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  keyReturnDebug copyWith(void Function(keyReturnDebug) updates) =>
      super.copyWith((message) => updates(message as keyReturnDebug))
          as keyReturnDebug;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use keyReturnDebug() / keyReturnDebug.new instead')
  static keyReturnDebug create() => keyReturnDebug._();
  static $pb.GeneratedMessage $_createMessage() => keyReturnDebug._();
  @$core.override
  keyReturnDebug createEmptyInstance() => keyReturnDebug._();
  @$core.pragma('dart2js:noInline')
  static keyReturnDebug getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<keyReturnDebug>(
          keyReturnDebug.$_createMessage);
  static keyReturnDebug? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get isFinished => $_getBF(0);
  @$pb.TagNumber(1)
  set isFinished($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIsFinished() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsFinished() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get key => $_getSZ(1);
  @$pb.TagNumber(2)
  set key($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get timeStamp => $_getSZ(2);
  @$pb.TagNumber(3)
  set timeStamp($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTimeStamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimeStamp() => $_clearField(3);
}

class MouseEvent extends $pb.GeneratedMessage {
  factory MouseEvent({
    MouseEvent_EventType? type,
    $core.int? x,
    $core.int? y,
    $core.int? scrollDelta,
  }) {
    final result = MouseEvent._();
    if (type != null) result.type = type;
    if (x != null) result.x = x;
    if (y != null) result.y = y;
    if (scrollDelta != null) result.scrollDelta = scrollDelta;
    return result;
  }

  MouseEvent._();

  factory MouseEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MouseEvent()..mergeFromBuffer(data, registry);
  factory MouseEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MouseEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MouseEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'GoKeyMux'),
      createEmptyInstance: MouseEvent.$_createMessage)
    ..aE<MouseEvent_EventType>(1, _omitFieldNames ? '' : 'type',
        enumValues: MouseEvent_EventType.values)
    ..aI(2, _omitFieldNames ? '' : 'x')
    ..aI(3, _omitFieldNames ? '' : 'y')
    ..aI(4, _omitFieldNames ? '' : 'scrollDelta')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MouseEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MouseEvent copyWith(void Function(MouseEvent) updates) =>
      super.copyWith((message) => updates(message as MouseEvent)) as MouseEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MouseEvent() / MouseEvent.new instead')
  static MouseEvent create() => MouseEvent._();
  static $pb.GeneratedMessage $_createMessage() => MouseEvent._();
  @$core.override
  MouseEvent createEmptyInstance() => MouseEvent._();
  @$core.pragma('dart2js:noInline')
  static MouseEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MouseEvent>(MouseEvent.$_createMessage);
  static MouseEvent? _defaultInstance;

  /// 事件类型
  @$pb.TagNumber(1)
  MouseEvent_EventType get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(MouseEvent_EventType value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  /// 仅在 type == MOVE 时有效。
  /// 表示鼠标在 X/Y 轴上的相对移动像素量（Delta）。
  /// 对于其他事件类型，此字段应被设为0
  @$pb.TagNumber(2)
  $core.int get x => $_getIZ(1);
  @$pb.TagNumber(2)
  set x($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasX() => $_has(1);
  @$pb.TagNumber(2)
  void clearX() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get y => $_getIZ(2);
  @$pb.TagNumber(3)
  set y($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasY() => $_has(2);
  @$pb.TagNumber(3)
  void clearY() => $_clearField(3);

  /// 滚轮增量
  /// 仅在 type == SCROLL 时有效。正数向上/向前，负数向下/向后。
  @$pb.TagNumber(4)
  $core.int get scrollDelta => $_getIZ(3);
  @$pb.TagNumber(4)
  set scrollDelta($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasScrollDelta() => $_has(3);
  @$pb.TagNumber(4)
  void clearScrollDelta() => $_clearField(4);
}

class MouseReturn extends $pb.GeneratedMessage {
  factory MouseReturn({
    $core.bool? isAllDone,
    $core.String? metaData,
  }) {
    final result = MouseReturn._();
    if (isAllDone != null) result.isAllDone = isAllDone;
    if (metaData != null) result.metaData = metaData;
    return result;
  }

  MouseReturn._();

  factory MouseReturn.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MouseReturn()..mergeFromBuffer(data, registry);
  factory MouseReturn.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MouseReturn()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MouseReturn',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'GoKeyMux'),
      createEmptyInstance: MouseReturn.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'isAllDone', protoName: 'isAllDone')
    ..aOS(2, _omitFieldNames ? '' : 'metaData', protoName: 'metaData')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MouseReturn clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MouseReturn copyWith(void Function(MouseReturn) updates) =>
      super.copyWith((message) => updates(message as MouseReturn))
          as MouseReturn;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MouseReturn() / MouseReturn.new instead')
  static MouseReturn create() => MouseReturn._();
  static $pb.GeneratedMessage $_createMessage() => MouseReturn._();
  @$core.override
  MouseReturn createEmptyInstance() => MouseReturn._();
  @$core.pragma('dart2js:noInline')
  static MouseReturn getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MouseReturn>(
          MouseReturn.$_createMessage);
  static MouseReturn? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get isAllDone => $_getBF(0);
  @$pb.TagNumber(1)
  set isAllDone($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasIsAllDone() => $_has(0);
  @$pb.TagNumber(1)
  void clearIsAllDone() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get metaData => $_getSZ(1);
  @$pb.TagNumber(2)
  set metaData($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMetaData() => $_has(1);
  @$pb.TagNumber(2)
  void clearMetaData() => $_clearField(2);
}

class rpcKeyServiceApi {
  final $pb.RpcClient _client;

  rpcKeyServiceApi(this._client);

  $async.Future<keyReturn> keyService(
          $pb.ClientContext? ctx, keyInput request) =>
      _client.invoke<keyReturn>(
          ctx, 'rpcKeyService', 'keyService', request, keyReturn());
  $async.Future<keyReturnDebug> keyServiceDebug(
          $pb.ClientContext? ctx, keyInputDebug request) =>
      _client.invoke<keyReturnDebug>(
          ctx, 'rpcKeyService', 'keyServiceDebug', request, keyReturnDebug());
  $async.Future<MouseReturn> mouseService(
          $pb.ClientContext? ctx, MouseEvent request) =>
      _client.invoke<MouseReturn>(
          ctx, 'rpcKeyService', 'MouseService', request, MouseReturn());
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
