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
    {'1': 'is_finished', '3': 1, '4': 1, '5': 8, '10': 'isFinished'},
    {'1': 'key', '3': 2, '4': 1, '5': 9, '10': 'key'},
    {'1': 'timeStamp', '3': 3, '4': 1, '5': 9, '10': 'timeStamp'},
  ],
};

/// Descriptor for `keyReturnDebug`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List keyReturnDebugDescriptor = $convert.base64Decode(
    'Cg5rZXlSZXR1cm5EZWJ1ZxIfCgtpc19maW5pc2hlZBgBIAEoCFIKaXNGaW5pc2hlZBIQCgNrZX'
    'kYAiABKAlSA2tleRIcCgl0aW1lU3RhbXAYAyABKAlSCXRpbWVTdGFtcA==');
