import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const androidChannel = MethodChannel('squawker/android_info');

List<String>? _supportedTextActivityList;

bool findInJSONArray(List arr, String key, String value) {
  for (var item in arr) {
    if (item[key] == value) {
      return true;
    }
  }
  return false;
}

bool isTranslatable(String? lang, String? text) {
  if (lang == null || lang == 'und') {
    return false;
  }

  if (lang != getShortSystemLocale()) {
    return true;
  }

  return false;
}

String getShortSystemLocale() {
  // TODO: Cache
  return Platform.localeName.split("_")[0];
}

Future<List<String>> getSupportedTextActivityList() async {
  if (!Platform.isAndroid) {
    return [];
  }
  if (_supportedTextActivityList != null) {
    return _supportedTextActivityList!;
  }
  _supportedTextActivityList = (await androidChannel.invokeMethod('supportedTextActivityList') as List<Object?>).map((e) => e.toString()).toList();
  /*
  print('*** supported text activities:');
  _supportedTextActivityList!.forEach((e) { print('***   $e'); });
  */
  return _supportedTextActivityList!;
}

Future<String?> processTextActivity(int index, String value, bool readonly) async {
  if (!Platform.isAndroid) {
    return null;
  }
  String? newValue = await androidChannel.invokeMethod('processTextActivity', {
    'id': index,
    'value': value,
    'readonly': readonly,
  }) as String?;
  return newValue;
}

Future requestPostNotificationsPermissions(AsyncCallback callback) async {
  if (!Platform.isAndroid) {
    callback();
    return;
  }
  androidChannel.setMethodCallHandler((MethodCall call) async {
    if (call.method == 'requestPostNotificationsPermissionsCallback') {
      bool granted = call.arguments;
      if (granted) {
        callback();
      }
    }
    return true;
  });
  await androidChannel.invokeMethod('requestPostNotificationsPermissions');
}

