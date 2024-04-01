import 'dart:async';

import 'package:flutter/material.dart';
import 'package:squawker/generated/l10n.dart';
import 'package:squawker/settings/_about.dart';
import 'package:squawker/settings/_account.dart';
import 'package:squawker/settings/_data.dart';
import 'package:squawker/settings/_general.dart';
import 'package:squawker/settings/_home.dart';
import 'package:squawker/settings/_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  final String? initialPage;

  const SettingsScreen({Key? key, this.initialPage}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo _packageInfo = PackageInfo(appName: '', packageName: '', version: '', buildNumber: '');
  String _legacyExportPath = '';

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      var packageInfo = await PackageInfo.fromPlatform();

      setState(() {
        _packageInfo = packageInfo;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var appVersion = 'v${_packageInfo.version}+${_packageInfo.buildNumber}';

    return Scaffold(
      appBar: AppBar(title: Text(L10n.of(context).settings)),
      body: ListView(
        children: [
          ListTile(
            title: Text(L10n.of(context).general),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsGeneralFragment()),
            ),
          ),
          ListTile(
            title: Text(L10n.of(context).account),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsAccountFragment()),
            ),
          ),
          ListTile(
            title: Text(L10n.of(context).home),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsHomeFragment()),
            ),
          ),
          ListTile(
            title: Text(L10n.of(context).theme),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsThemeFragment()),
            ),
          ),
          ListTile(
            title: Text(L10n.of(context).data),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => SettingsDataFragment(
                        legacyExportPath: _legacyExportPath,
                      )),
            ),
          ),
          ListTile(
            title: Text(L10n.of(context).about),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsAboutFragment(appVersion: appVersion)),
            ),
          ),
        ],
      ),
    );
  }
}
