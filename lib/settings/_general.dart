import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:squawker/constants.dart';
import 'package:squawker/database/repository.dart';
import 'package:squawker/generated/l10n.dart';
import 'package:squawker/home/home_screen.dart';
import 'package:squawker/utils/iterables.dart';
import 'package:squawker/utils/misc.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pref/pref.dart';

class SettingLocale {
  final String code;
  final String name;

  SettingLocale(this.code, this.name);

  factory SettingLocale.fromLocale(Locale locale) {
    var code = locale.toLanguageTag().replaceAll('-', '_');
    var name = LocaleNamesLocalizationsDelegate.nativeLocaleNames[code] ?? code;

    return SettingLocale(code, name);
  }
}

class SettingsGeneralFragment extends StatelessWidget {
  static final log = Logger('SettingsGeneralFragment');

  const SettingsGeneralFragment({Key? key}) : super(key: key);

  PrefDialog _createShareBaseDialog(BuildContext context) {
    var prefService = PrefService.of(context);
    var mediaQuery = MediaQuery.of(context);

    final controller = TextEditingController(text: prefService.get(optionShareBaseUrl));

    return PrefDialog(
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(L10n.of(context).cancel)),
          TextButton(
              onPressed: () async {
                await prefService.set(optionShareBaseUrl, controller.text);
                Navigator.pop(context);
              },
              child: Text(L10n.of(context).save))
        ],
        title: Text(L10n.of(context).share_base_url),
        children: [
          SizedBox(
            width: mediaQuery.size.width,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'https://x.com'),
            ),
          )
        ]);
  }

  void _createTweetFontSizeDialog(BuildContext context) async {
    int? selectedFontSize = await showDialog<int>(
      context: context,
      builder: (context) => FontSizePickerDialog(initialFontSize: _getOptionTweetFontSizeValue(context)),
    );
    if (selectedFontSize != null) {
      PrefService.of(context).set<int>(optionTweetFontSize, selectedFontSize);
    }
  }

  int _getOptionTweetFontSizeValue(BuildContext context) {
    int optionTweetFontSizeValue =
        PrefService.of(context).get<int>(optionTweetFontSize) ?? DefaultTextStyle.of(context).style.fontSize!.round();
    return optionTweetFontSizeValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(L10n.current.general)),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView(children: [
          PrefDropdown(
              fullWidth: false,
              title: Text(L10n.current.language),
              subtitle: Text(L10n.current.language_subtitle),
              pref: optionLocale,
              items: [
                DropdownMenuItem(value: optionLocaleDefault, child: Text(L10n.current.system)),
                ...L10n.delegate.supportedLocales
                    .map((e) => SettingLocale.fromLocale(e))
                    .sorted((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()))
                    .map((e) => DropdownMenuItem(value: e.code, child: Text(e.name)))
              ]),
          if (getFlavor() != 'play' && getFlavor() != 'fdroid')
            PrefSwitch(
              title: Text(L10n.of(context).should_check_for_updates_label),
              pref: optionShouldCheckForUpdates,
              subtitle: Text(L10n.of(context).should_check_for_updates_description),
            ),
          PrefSwitch(
            title: Text(L10n.of(context).option_confirm_close_label),
            subtitle: Text(L10n.of(context).option_confirm_close_description),
            pref: optionConfirmClose,
          ),
          PrefDropdown(
              fullWidth: false,
              title: Text(L10n.of(context).default_tab),
              subtitle: Text(
                L10n.of(context).which_tab_is_shown_when_the_app_opens,
              ),
              pref: optionHomeInitialTab,
              items: defaultHomePages
                  .map((e) => DropdownMenuItem(value: e.id, child: Text(e.titleBuilder(context))))
                  .toList()),
          PrefDropdown(
              fullWidth: false,
              title: Text(L10n.of(context).media_size),
              subtitle: Text(
                L10n.of(context).save_bandwidth_using_smaller_images,
              ),
              pref: optionMediaSize,
              items: [
                DropdownMenuItem(
                  value: 'disabled',
                  child: Text(L10n.of(context).disabled),
                ),
                DropdownMenuItem(
                  value: 'thumb',
                  child: Text(L10n.of(context).thumbnail),
                ),
                DropdownMenuItem(
                  value: 'small',
                  child: Text(L10n.of(context).small),
                ),
                DropdownMenuItem(
                  value: 'medium',
                  child: Text(L10n.of(context).medium),
                ),
                DropdownMenuItem(
                  value: 'large',
                  child: Text(L10n.of(context).large),
                ),
              ]),
          PrefSwitch(
            pref: optionMediaDefaultMute,
            title: Text(L10n.of(context).mute_videos),
            subtitle: Text(L10n.of(context).mute_video_description),
          ),
          PrefSwitch(
            pref: optionTweetsHideSensitive,
            title: Text(L10n.of(context).hide_sensitive_tweets),
            subtitle: Text(L10n.of(context).whether_to_hide_tweets_marked_as_sensitive),
          ),
          PrefDialogButton(
            title: Text(L10n.of(context).share_base_url),
            subtitle: Text(L10n.of(context).share_base_url_description),
            dialog: _createShareBaseDialog(context),
          ),
          PrefSwitch(
            title: Text(L10n.of(context).disable_screenshots),
            subtitle: Text(L10n.of(context).disable_screenshots_hint),
            pref: optionDisableScreenshots,
          ),
          const DownloadTypeSetting(),
          PrefSwitch(
            title: Text(L10n.of(context).download_video_best_quality_label),
            pref: optionDownloadBestVideoQuality,
            subtitle: Text(L10n.of(context).download_video_best_quality_description),
          ),
          PrefSwitch(
            title: Text(L10n.of(context).activate_non_confirmation_bias_mode_label),
            pref: optionNonConfirmationBiasMode,
            subtitle: Text(L10n.of(context).activate_non_confirmation_bias_mode_description),
          ),
          PrefSwitch(
            title: Text(L10n.of(context).keep_feed_offset_label),
            subtitle: Text(L10n.of(context).keep_feed_offset_description),
            pref: optionKeepFeedOffset,
            onChange: (value) async {
              if (!value) {
                var repository = await Repository.writable();
                await repository.delete(tableFeedGroupPositionState);
              }
            },
          ),
          PrefSwitch(
            title: Text(L10n.of(context).leaner_feeds_label),
            subtitle: Text(L10n.of(context).leaner_feeds_description),
            pref: optionLeanerFeeds,
          ),
          PrefButton(
            title: Text(L10n.of(context).tweet_font_size_label),
            subtitle: Text(L10n.of(context).tweet_font_size_description),
            onTap: () => _createTweetFontSizeDialog(context),
            child: Text('${_getOptionTweetFontSizeValue(context)} px'),
          ),
        ]),
      ),
    );
  }
}

class DownloadTypeSetting extends StatefulWidget {
  const DownloadTypeSetting({Key? key}) : super(key: key);

  @override
  DownloadTypeSettingState createState() => DownloadTypeSettingState();
}

class DownloadTypeSettingState extends State<DownloadTypeSetting> {
  @override
  Widget build(BuildContext context) {
    var downloadPath = PrefService.of(context).get<String>(optionDownloadPath) ?? '';

    return Column(
      children: [
        PrefDropdown(
          onChange: (value) {
            setState(() {});
          },
          fullWidth: false,
          title: Text(L10n.current.download_handling),
          subtitle: Text(L10n.current.download_handling_description),
          pref: optionDownloadType,
          items: [
            DropdownMenuItem(value: optionDownloadTypeAsk, child: Text(L10n.current.download_handling_type_ask)),
            DropdownMenuItem(
                value: optionDownloadTypeDirectory, child: Text(L10n.current.download_handling_type_directory)),
          ],
        ),
        if (PrefService.of(context).get(optionDownloadType) == optionDownloadTypeDirectory)
          PrefButton(
            onTap: () async {
              DeviceInfoPlugin plugin = DeviceInfoPlugin();
              AndroidDeviceInfo android = await plugin.androidInfo;
              var storagePermission = android.version.sdkInt < 30
                ? await Permission.storage.request()
                : await Permission.manageExternalStorage.request();
              if (storagePermission.isGranted) {
                String? directoryPath = await FilePicker.platform.getDirectoryPath();
                if (directoryPath == null) {
                  return;
                }

                // TODO: Gross. Figure out how to re-render automatically when the preference changes
                setState(() {
                  PrefService.of(context).set(optionDownloadPath, directoryPath);
                });
              } else if (storagePermission.isPermanentlyDenied) {
                await openAppSettings();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(L10n.current.permission_not_granted),
                    action: SnackBarAction(
                      label: L10n.current.open_app_settings,
                      onPressed: openAppSettings,
                    )));
              }
            },
            title: Text(L10n.current.download_path),
            subtitle: Text(
              downloadPath.isEmpty ? L10n.current.not_set : downloadPath,
            ),
            child: Text(L10n.current.choose),
          )
      ],
    );
  }
}

class FontSizePickerDialog extends StatefulWidget {
  /// initial selection for the slider
  final int initialFontSize;

  const FontSizePickerDialog({Key? key, required this.initialFontSize}) : super(key: key);

  @override
  FontSizePickerDialogState createState() => FontSizePickerDialogState();
}

class FontSizePickerDialogState extends State<FontSizePickerDialog> {
  /// current selection of the slider
  late int tweetFontSize;

  @override
  void initState() {
    super.initState();
    tweetFontSize = widget.initialFontSize;
  }

  @override
  Widget build(BuildContext context) {
    double defaultFontSize = DefaultTextStyle.of(context).style.fontSize!;
    double minFontSize = defaultFontSize - 4;
    double maxFontSize = defaultFontSize + 8;
    return AlertDialog(
      title: Text(L10n.of(context).tweet_font_size_label),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$tweetFontSize px'),
          Slider(
            value: tweetFontSize.toDouble(),
            min: minFontSize,
            max: maxFontSize,
            divisions: ((maxFontSize - minFontSize) / 2).round(),
            label: '$tweetFontSize px',
            onChanged: (value) {
              setState(() {
                tweetFontSize = value.round();
              });
            },
          ),
        ]
      ),

      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(L10n.of(context).cancel)),
        TextButton(
            onPressed: () async {
              Navigator.pop(context, tweetFontSize);
            },
            child: Text(L10n.of(context).save)
        )
      ],
    );
  }
}
