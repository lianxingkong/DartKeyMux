// This is a generated file - do not edit.
//
// Generated from keymux.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class MouseEvent_EventType extends $pb.ProtobufEnum {
  static const MouseEvent_EventType UNKNOWN =
      MouseEvent_EventType._(0, _omitEnumNames ? '' : 'UNKNOWN');
  static const MouseEvent_EventType MOVE =
      MouseEvent_EventType._(1, _omitEnumNames ? '' : 'MOVE');
  static const MouseEvent_EventType LEFT_DOWN =
      MouseEvent_EventType._(2, _omitEnumNames ? '' : 'LEFT_DOWN');
  static const MouseEvent_EventType LEFT_UP =
      MouseEvent_EventType._(3, _omitEnumNames ? '' : 'LEFT_UP');
  static const MouseEvent_EventType RIGHT_DOWN =
      MouseEvent_EventType._(4, _omitEnumNames ? '' : 'RIGHT_DOWN');
  static const MouseEvent_EventType RIGHT_UP =
      MouseEvent_EventType._(5, _omitEnumNames ? '' : 'RIGHT_UP');
  static const MouseEvent_EventType MIDDLE_DOWN =
      MouseEvent_EventType._(6, _omitEnumNames ? '' : 'MIDDLE_DOWN');
  static const MouseEvent_EventType MIDDLE_UP =
      MouseEvent_EventType._(7, _omitEnumNames ? '' : 'MIDDLE_UP');
  static const MouseEvent_EventType SCROLL =
      MouseEvent_EventType._(8, _omitEnumNames ? '' : 'SCROLL');

  static const $core.List<MouseEvent_EventType> values = <MouseEvent_EventType>[
    UNKNOWN,
    MOVE,
    LEFT_DOWN,
    LEFT_UP,
    RIGHT_DOWN,
    RIGHT_UP,
    MIDDLE_DOWN,
    MIDDLE_UP,
    SCROLL,
  ];

  static final $core.List<MouseEvent_EventType?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 8);
  static MouseEvent_EventType? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const MouseEvent_EventType._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
