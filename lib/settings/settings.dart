import 'dart:async';

import 'package:flutter/material.dart';
import 'package:squawker/generated/l10n.dart';
import 'package:squawker/home/home_screen.dart';
import 'package:squawker/settings/_about.dart';
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

    var pages = [
      NavigationPage('general', (c) => L10n.of(c).general, Icons.settings_rounded),
      NavigationPage('home', (c) => L10n.of(c).home, Icons.home_rounded),
      NavigationPage('theme', (c) => L10n.of(c).theme, Icons.format_paint_rounded),
      NavigationPage('data', (c) => L10n.of(c).data, Icons.storage_rounded),
      NavigationPage('about', (c) => L10n.of(c).about, Icons.help_rounded),
    ];

    var initialPage = pages.indexWhere((element) => element.id == widget.initialPage);
    if (initialPage == -1) {
      initialPage = 0;
    }

    return ScaffoldWithBottomNavigation(
      initialPage: initialPage,
      pages: pages,
      builder: (scrollController) {
        return [
          const SettingsGeneralFragment(),
          const SettingsHomeFragment(),
          const SettingsThemeFragment(),
          SettingsDataFragment(legacyExportPath: _legacyExportPath),
          SettingsAboutFragment(appVersion: appVersion)
        ];
      },
    );
  }
}
