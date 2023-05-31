import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quacker/generated/l10n.dart';
import 'package:quacker/home/home_screen.dart';
import 'package:quacker/settings/_backup.dart';
import 'package:quacker/settings/_general.dart';
import 'package:quacker/settings/_home.dart';
import 'package:quacker/settings/_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  final String? initialPage;

  const SettingsScreen({Key? key, this.initialPage}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo _packageInfo = PackageInfo(appName: '', packageName: '', version: '', buildNumber: '');

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
      NavigationPage('general', (c) => L10n.of(c).general, Icons.settings_outlined),
      NavigationPage('home', (c) => L10n.of(c).home, Icons.home_outlined),
      NavigationPage('theme', (c) => L10n.of(c).theme, Icons.format_paint_outlined),
      NavigationPage('data', (c) => L10n.of(c).data, Icons.storage_rounded),
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
          SettingsGeneralFragment(appVersion: appVersion),
          const SettingsHomeFragment(),
          const SettingsThemeFragment(),
          const SettingsBackupFragment()
        ];
      },
    );
  }
}
