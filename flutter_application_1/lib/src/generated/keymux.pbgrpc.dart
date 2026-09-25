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

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'keymux.pb.dart' as $0;

export 'keymux.pb.dart';

@$pb.GrpcServiceName('GoKeyMux.rpcKeyService')
class rpcKeyServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  rpcKeyServiceClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.keyReturn> keyService(
    $async.Stream<$0.keyInput> request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$keyService, request, options: options).single;
  }

  $grpc.ResponseFuture<$0.keyReturnDebug> keyServiceDebug(
    $0.keyInputDebug request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$keyServiceDebug, request, options: options);
  }

  // method descriptors

  static final _$keyService = $grpc.ClientMethod<$0.keyInput, $0.keyReturn>(
      '/GoKeyMux.rpcKeyService/keyService',
      ($0.keyInput value) => value.writeToBuffer(),
      $0.keyReturn.fromBuffer);
  static final _$keyServiceDebug =
      $grpc.ClientMethod<$0.keyInputDebug, $0.keyReturnDebug>(
          '/GoKeyMux.rpcKeyService/keyServiceDebug',
          ($0.keyInputDebug value) => value.writeToBuffer(),
          $0.keyReturnDebug.fromBuffer);
}

@$pb.GrpcServiceName('GoKeyMux.rpcKeyService')
abstract class rpcKeyServiceBase extends $grpc.Service {
  $core.String get $name => 'GoKeyMux.rpcKeyService';

  rpcKeyServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.keyInput, $0.keyReturn>(
        'keyService',
        keyService,
        true,
        false,
        ($core.List<$core.int> value) => $0.keyInput.fromBuffer(value),
        ($0.keyReturn value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.keyInputDebug, $0.keyReturnDebug>(
        'keyServiceDebug',
        keyServiceDebug_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.keyInputDebug.fromBuffer(value),
        ($0.keyReturnDebug value) => value.writeToBuffer()));
  }

  $async.Future<$0.keyReturn> keyService(
      $grpc.ServiceCall call, $async.Stream<$0.keyInput> request);

  $async.Future<$0.keyReturnDebug> keyServiceDebug_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.keyInputDebug> $request) async {
    return keyServiceDebug($call, await $request);
  }

  $async.Future<$0.keyReturnDebug> keyServiceDebug(
      $grpc.ServiceCall call, $0.keyInputDebug request);
}
