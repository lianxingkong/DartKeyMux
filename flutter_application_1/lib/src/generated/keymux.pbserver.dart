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

import 'keymux.pb.dart' as $0;
import 'keymux.pbjson.dart';

export 'keymux.pb.dart';

abstract class rpcKeyServiceBase extends $pb.GeneratedService {
  $async.Future<$0.keyReturn> keyService(
      $pb.ServerContext ctx, $0.keyInput request);
  $async.Future<$0.keyReturnDebug> keyServiceDebug(
      $pb.ServerContext ctx, $0.keyInputDebug request);
  $async.Future<$0.MouseReturn> mouseService(
      $pb.ServerContext ctx, $0.MouseEvent request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'keyService':
        return $0.keyInput();
      case 'keyServiceDebug':
        return $0.keyInputDebug();
      case 'MouseService':
        return $0.MouseEvent();
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx,
      $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'keyService':
        return keyService(ctx, request as $0.keyInput);
      case 'keyServiceDebug':
        return keyServiceDebug(ctx, request as $0.keyInputDebug);
      case 'MouseService':
        return mouseService(ctx, request as $0.MouseEvent);
      default:
        throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => rpcKeyServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
      get $messageJson => rpcKeyServiceBase$messageJson;
}
