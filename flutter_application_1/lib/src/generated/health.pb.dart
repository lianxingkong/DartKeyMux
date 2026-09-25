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

import 'health.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'health.pbenum.dart';

class HealthCheckRequest extends $pb.GeneratedMessage {
  factory HealthCheckRequest({
    $core.String? service,
  }) {
    final result = HealthCheckRequest._();
    if (service != null) result.service = service;
    return result;
  }

  HealthCheckRequest._();

  factory HealthCheckRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HealthCheckRequest()..mergeFromBuffer(data, registry);
  factory HealthCheckRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HealthCheckRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HealthCheckRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'grpc.health.v1'),
      createEmptyInstance: HealthCheckRequest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'service')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HealthCheckRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HealthCheckRequest copyWith(void Function(HealthCheckRequest) updates) =>
      super.copyWith((message) => updates(message as HealthCheckRequest))
          as HealthCheckRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HealthCheckRequest() / HealthCheckRequest.new instead')
  static HealthCheckRequest create() => HealthCheckRequest._();
  static $pb.GeneratedMessage $_createMessage() => HealthCheckRequest._();
  @$core.override
  HealthCheckRequest createEmptyInstance() => HealthCheckRequest._();
  @$core.pragma('dart2js:noInline')
  static HealthCheckRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HealthCheckRequest>(
          HealthCheckRequest.$_createMessage);
  static HealthCheckRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get service => $_getSZ(0);
  @$pb.TagNumber(1)
  set service($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasService() => $_has(0);
  @$pb.TagNumber(1)
  void clearService() => $_clearField(1);
}

class HealthCheckResponse extends $pb.GeneratedMessage {
  factory HealthCheckResponse({
    HealthCheckResponse_ServingStatus? status,
  }) {
    final result = HealthCheckResponse._();
    if (status != null) result.status = status;
    return result;
  }

  HealthCheckResponse._();

  factory HealthCheckResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HealthCheckResponse()..mergeFromBuffer(data, registry);
  factory HealthCheckResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HealthCheckResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HealthCheckResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'grpc.health.v1'),
      createEmptyInstance: HealthCheckResponse.$_createMessage)
    ..aE<HealthCheckResponse_ServingStatus>(1, _omitFieldNames ? '' : 'status',
        enumValues: HealthCheckResponse_ServingStatus.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HealthCheckResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HealthCheckResponse copyWith(void Function(HealthCheckResponse) updates) =>
      super.copyWith((message) => updates(message as HealthCheckResponse))
          as HealthCheckResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core
      .Deprecated('Use HealthCheckResponse() / HealthCheckResponse.new instead')
  static HealthCheckResponse create() => HealthCheckResponse._();
  static $pb.GeneratedMessage $_createMessage() => HealthCheckResponse._();
  @$core.override
  HealthCheckResponse createEmptyInstance() => HealthCheckResponse._();
  @$core.pragma('dart2js:noInline')
  static HealthCheckResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HealthCheckResponse>(
          HealthCheckResponse.$_createMessage);
  static HealthCheckResponse? _defaultInstance;

  @$pb.TagNumber(1)
  HealthCheckResponse_ServingStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(HealthCheckResponse_ServingStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
