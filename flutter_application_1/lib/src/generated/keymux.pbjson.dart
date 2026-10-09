// This is a generated file - do not edit.
//
// Generated from keymux.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use keyInputDescriptor instead')
const keyInput$json = {
  '1': 'keyInput',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'isRune', '3': 2, '4': 1, '5': 8, '10': 'isRune'},
    {'1': 'isPressed', '3': 3, '4': 1, '5': 8, '10': 'isPressed'},
  ],
};

/// Descriptor for `keyInput`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyInputDescriptor = $convert.base64Decode(
    'CghrZXlJbnB1dBIQCgNrZXkYASABKAlSA2tleRIWCgZpc1J1bmUYAiABKAhSBmlzUnVuZRIcCg'
    'lpc1ByZXNzZWQYAyABKAhSCWlzUHJlc3NlZA==');

@$core.Deprecated('Use keyReturnDescriptor instead')
const keyReturn$json = {
  '1': 'keyReturn',
  '2': [
    {'1': 'isAllDone', '3': 1, '4': 1, '5': 8, '10': 'isAllDone'},
    {'1': 'metaData', '3': 2, '4': 1, '5': 9, '10': 'metaData'},
  ],
};

/// Descriptor for `keyReturn`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyReturnDescriptor = $convert.base64Decode(
    'CglrZXlSZXR1cm4SHAoJaXNBbGxEb25lGAEgASgIUglpc0FsbERvbmUSGgoIbWV0YURhdGEYAi'
    'ABKAlSCG1ldGFEYXRh');

@$core.Deprecated('Use keyInputDebugDescriptor instead')
const keyInputDebug$json = {
  '1': 'keyInputDebug',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'isRune', '3': 2, '4': 1, '5': 8, '10': 'isRune'},
    {'1': 'isPressed', '3': 3, '4': 1, '5': 8, '10': 'isPressed'},
    {'1': 'timeStamp', '3': 4, '4': 1, '5': 9, '10': 'timeStamp'},
    {'1': 'metaData', '3': 5, '4': 1, '5': 9, '10': 'metaData'},
  ],
};

/// Descriptor for `keyInputDebug`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyInputDebugDescriptor = $convert.base64Decode(
    'Cg1rZXlJbnB1dERlYnVnEhAKA2tleRgBIAEoCVIDa2V5EhYKBmlzUnVuZRgCIAEoCFIGaXNSdW'
    '5lEhwKCWlzUHJlc3NlZBgDIAEoCFIJaXNQcmVzc2VkEhwKCXRpbWVTdGFtcBgEIAEoCVIJdGlt'
    'ZVN0YW1wEhoKCG1ldGFEYXRhGAUgASgJUghtZXRhRGF0YQ==');

@$core.Deprecated('Use keyReturnDebugDescriptor instead')
const keyReturnDebug$json = {
  '1': 'keyReturnDebug',
  '2': [
    {'1': 'isFinished', '3': 1, '4': 1, '5': 8, '10': 'isFinished'},
    {'1': 'key', '3': 2, '4': 1, '5': 9, '10': 'key'},
    {'1': 'timeStamp', '3': 3, '4': 1, '5': 9, '10': 'timeStamp'},
  ],
};

/// Descriptor for `keyReturnDebug`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyReturnDebugDescriptor = $convert.base64Decode(
    'Cg5rZXlSZXR1cm5EZWJ1ZxIeCgppc0ZpbmlzaGVkGAEgASgIUgppc0ZpbmlzaGVkEhAKA2tleR'
    'gCIAEoCVIDa2V5EhwKCXRpbWVTdGFtcBgDIAEoCVIJdGltZVN0YW1w');

@$core.Deprecated('Use mouseEventDescriptor instead')
const MouseEvent$json = {
  '1': 'MouseEvent',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.GoKeyMux.MouseEvent.EventType',
      '10': 'type'
    },
    {'1': 'x', '3': 2, '4': 1, '5': 5, '10': 'x'},
    {'1': 'y', '3': 3, '4': 1, '5': 5, '10': 'y'},
    {'1': 'scroll_delta', '3': 4, '4': 1, '5': 5, '10': 'scrollDelta'},
  ],
  '4': [MouseEvent_EventType$json],
};

@$core.Deprecated('Use mouseEventDescriptor instead')
const MouseEvent_EventType$json = {
  '1': 'EventType',
  '2': [
    {'1': 'UNKNOWN', '2': 0},
    {'1': 'MOVE', '2': 1},
    {'1': 'LEFT_DOWN', '2': 2},
    {'1': 'LEFT_UP', '2': 3},
    {'1': 'RIGHT_DOWN', '2': 4},
    {'1': 'RIGHT_UP', '2': 5},
    {'1': 'MIDDLE_DOWN', '2': 6},
    {'1': 'MIDDLE_UP', '2': 7},
    {'1': 'SCROLL', '2': 8},
  ],
};

/// Descriptor for `MouseEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mouseEventDescriptor = $convert.base64Decode(
    'CgpNb3VzZUV2ZW50EjIKBHR5cGUYASABKA4yHi5Hb0tleU11eC5Nb3VzZUV2ZW50LkV2ZW50VH'
    'lwZVIEdHlwZRIMCgF4GAIgASgFUgF4EgwKAXkYAyABKAVSAXkSIQoMc2Nyb2xsX2RlbHRhGAQg'
    'ASgFUgtzY3JvbGxEZWx0YSKIAQoJRXZlbnRUeXBlEgsKB1VOS05PV04QABIICgRNT1ZFEAESDQ'
    'oJTEVGVF9ET1dOEAISCwoHTEVGVF9VUBADEg4KClJJR0hUX0RPV04QBBIMCghSSUdIVF9VUBAF'
    'Eg8KC01JRERMRV9ET1dOEAYSDQoJTUlERExFX1VQEAcSCgoGU0NST0xMEAg=');

@$core.Deprecated('Use mouseReturnDescriptor instead')
const MouseReturn$json = {
  '1': 'MouseReturn',
  '2': [
    {'1': 'isAllDone', '3': 1, '4': 1, '5': 8, '10': 'isAllDone'},
    {'1': 'metaData', '3': 2, '4': 1, '5': 9, '10': 'metaData'},
  ],
};

/// Descriptor for `MouseReturn`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mouseReturnDescriptor = $convert.base64Decode(
    'CgtNb3VzZVJldHVybhIcCglpc0FsbERvbmUYASABKAhSCWlzQWxsRG9uZRIaCghtZXRhRGF0YR'
    'gCIAEoCVIIbWV0YURhdGE=');

const $core.Map<$core.String, $core.dynamic> rpcKeyServiceBase$json = {
  '1': 'rpcKeyService',
  '2': [
    {
      '1': 'keyService',
      '2': '.GoKeyMux.keyInput',
      '3': '.GoKeyMux.keyReturn',
      '5': true
    },
    {
      '1': 'keyServiceDebug',
      '2': '.GoKeyMux.keyInputDebug',
      '3': '.GoKeyMux.keyReturnDebug'
    },
    {
      '1': 'MouseService',
      '2': '.GoKeyMux.MouseEvent',
      '3': '.GoKeyMux.MouseReturn',
      '5': true
    },
  ],
};

@$core.Deprecated('Use rpcKeyServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    rpcKeyServiceBase$messageJson = {
  '.GoKeyMux.keyInput': keyInput$json,
  '.GoKeyMux.keyReturn': keyReturn$json,
  '.GoKeyMux.keyInputDebug': keyInputDebug$json,
  '.GoKeyMux.keyReturnDebug': keyReturnDebug$json,
  '.GoKeyMux.MouseEvent': MouseEvent$json,
  '.GoKeyMux.MouseReturn': MouseReturn$json,
};

/// Descriptor for `rpcKeyService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List rpcKeyServiceDescriptor = $convert.base64Decode(
    'Cg1ycGNLZXlTZXJ2aWNlEjcKCmtleVNlcnZpY2USEi5Hb0tleU11eC5rZXlJbnB1dBoTLkdvS2'
    'V5TXV4LmtleVJldHVybigBEkQKD2tleVNlcnZpY2VEZWJ1ZxIXLkdvS2V5TXV4LmtleUlucHV0'
    'RGVidWcaGC5Hb0tleU11eC5rZXlSZXR1cm5EZWJ1ZxI9CgxNb3VzZVNlcnZpY2USFC5Hb0tleU'
    '11eC5Nb3VzZUV2ZW50GhUuR29LZXlNdXguTW91c2VSZXR1cm4oAQ==');
