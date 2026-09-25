// This is a generated file - do not edit.
//
// Generated from health.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class HealthCheckResponse_ServingStatus extends $pb.ProtobufEnum {
  static const HealthCheckResponse_ServingStatus UNKNOWN =
      HealthCheckResponse_ServingStatus._(0, _omitEnumNames ? '' : 'UNKNOWN');
  static const HealthCheckResponse_ServingStatus SERVING =
      HealthCheckResponse_ServingStatus._(1, _omitEnumNames ? '' : 'SERVING');
  static const HealthCheckResponse_ServingStatus NOT_SERVING =
      HealthCheckResponse_ServingStatus._(
          2, _omitEnumNames ? '' : 'NOT_SERVING');
  static const HealthCheckResponse_ServingStatus SERVICE_UNKNOWN =
      HealthCheckResponse_ServingStatus._(
          3, _omitEnumNames ? '' : 'SERVICE_UNKNOWN');

  static const $core.List<HealthCheckResponse_ServingStatus> values =
      <HealthCheckResponse_ServingStatus>[
    UNKNOWN,
    SERVING,
    NOT_SERVING,
    SERVICE_UNKNOWN,
  ];

  static final $core.List<HealthCheckResponse_ServingStatus?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static HealthCheckResponse_ServingStatus? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const HealthCheckResponse_ServingStatus._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
