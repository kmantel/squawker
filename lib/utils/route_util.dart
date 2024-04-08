import 'package:flutter/material.dart';
import 'package:squawker/utils/data_service.dart';

Future<dynamic> pushNamedRoute(BuildContext context, String routeName, Object? arguments) async {
  DataService().map[routeName] = arguments;
  return Navigator.pushNamed<dynamic>(context, routeName);
}

Object? getNamedRouteArguments(String routeName, {bool removeArgumentsFromSession = true}) {
  Object? args = DataService().map[routeName];
  if (removeArgumentsFromSession) {
    DataService().map.remove(routeName);
  }
  return args;
}
