import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:squawker/client/client_account.dart';
import 'package:squawker/database/entities.dart';
import 'package:squawker/generated/l10n.dart';

class TwitterRegularAccount {
  static final log = Logger('TwitterRegularAccount');

  static Future<String> _getLoginFlowToken(Map<String,String> headers, String accessToken, String guestToken) async {
    log.info('Posting https://api.twitter.com/1.1/onboarding/task.json?flow_name=login');
    headers.addAll({
      'Authorization': 'Bearer $accessToken',
      'X-Guest-Token': guestToken
    });
    var response = await http.post(Uri.parse('https://api.twitter.com/1.1/onboarding/task.json?flow_name=login'),
      headers: headers,
      body: json.encode({
        'flow_token': null,
        'input_flow_data': {
          'country_code': null,
          'flow_context': {
            'referrer_context': {
              'referral_details': 'utm_source=google-play&utm_medium=organic',
              'referrer_url': ''
            },
            'start_location': {
              'location': 'deeplink'
            }
          },
          'requested_variant': null,
          'target_user_id': 0
        }
      })
    );

    if (response.statusCode == 200) {
      var result = jsonDecode(response.body);
      if (response.headers.containsKey('att')) {
        headers.addAll({
          'att': response.headers['att'] as String,
          'cookie': 'att=${response.headers['att']}'
        });
      }
      if (result.containsKey('flow_token')) {
        return result['flow_token'];
      }
    }

    throw TwitterAccountException('Unable to get the login flow token. The response (${response.statusCode}) from Twitter/X was: ${response.body}');
  }

  static Future<String> _getUsernameFlowToken(Map<String,String> headers, String flowToken, String username) async {
    log.info('Posting (username) https://api.twitter.com/1.1/onboarding/task.json');
    var response = await http.post(Uri.parse('https://api.twitter.com/1.1/onboarding/task.json'),
      headers: headers,
      body: json.encode({
        'flow_token': flowToken,
        'subtask_inputs': [
          {
            'enter_text': {
              'suggestion_id': null,
              'text': username,
              'link': 'next_link'
            },
            'subtask_id': 'LoginEnterUserIdentifier'
          }
        ]
      })
    );

    if (response.statusCode == 200) {
      var result = jsonDecode(response.body);
      if (result.containsKey('flow_token')) {
        return result['flow_token'];
      }
    }

    throw TwitterAccountException('Unable to get the username flow token. The response (${response.statusCode}) from Twitter/X was: ${response.body}');
  }

  static Future<String> _getPasswordFlowToken(Map<String,String> headers, String flowToken, String password) async {
    log.info('Posting (password) https://api.twitter.com/1.1/onboarding/task.json');
    var response = await http.post(Uri.parse('https://api.twitter.com/1.1/onboarding/task.json'),
      headers: headers,
      body: json.encode({
        'flow_token': flowToken,
        'subtask_inputs': [
          {
            'enter_password': {
              'password': password,
              'link': 'next_link'
            },
            'subtask_id': 'LoginEnterPassword'
          }
        ]
      })
    );

    if (response.statusCode == 200) {
      var result = jsonDecode(response.body);
      if (result.containsKey('flow_token')) {
        return result['flow_token'];
      }
    }

    throw TwitterAccountException('Unable to get the password flow token. The response (${response.statusCode}) from Twitter/X was: ${response.body}');
  }

  static Future<Map<String,dynamic>> _getDuplicationCheckFlowToken(Map<String,String> headers, String flowToken, String? languageCode) async {
    String url = 'https://api.twitter.com/1.1/onboarding/task.json';
    if (languageCode != null) {
      url = '$url?lang=$languageCode';
    }
    log.info('Posting (duplication check) $url');
    var response = await http.post(Uri.parse(url),
      headers: headers,
      body: json.encode({
        'flow_token': flowToken,
        'subtask_inputs': [
          {
            'check_logged_in_account': {
              'link': 'AccountDuplicationCheck_false'
            },
            'subtask_id': 'AccountDuplicationCheck'
          }
        ]
      })
    );

    if (response.statusCode == 200) {
      List<String> cookies = [];
      if (headers.containsKey('cookie')) {
        String attCookie = headers['cookie'] as String;
        cookies.add(attCookie);
        headers.remove('cookie');
      }
      if (response.headers.containsKey('auth_token')) {
        cookies.add('auth_token=${response.headers['auth_token']}');
      }
      if (response.headers.containsKey('ct0')) {
        cookies.add('ct0=${response.headers['ct0']}');
      }
      if (cookies.isNotEmpty) {
        headers['cookie'] = cookies.join(';');
      }
      var result = jsonDecode(response.body);
      return result;
    }

    throw TwitterAccountException('Unable to get the duplication check flow token. The response (${response.statusCode}) from Twitter/X was: ${response.body}');
  }

  static Future<Map<String,dynamic>> _get2FAFlowToken(Map<String,String> headers, String flowToken, String code) async {
    log.info('Posting (2FA) https://api.twitter.com/1.1/onboarding/task.json');
    var response = await http.post(Uri.parse('https://api.twitter.com/1.1/onboarding/task.json'),
        headers: headers,
        body: json.encode({
          'flow_token': flowToken,
          'subtask_inputs': [
            {
              'enter_text': {
                'text': code,
                'link': 'next_link'
              },
              'subtask_id': 'LoginTwoFactorAuthChallenge'
            }
          ]
        })
    );

    if (response.statusCode == 200) {
      var result = jsonDecode(response.body);
      return result;
    }

    throw TwitterAccountException('Unable to get the 2FA flow token. The response (${response.statusCode}) from Twitter/X was: ${response.body}');
  }

  static Future<TwitterTokenEntity> createRegularTwitterToken(BuildContext? context, String? languageCode, String username, String password, String? name, String? email, String? phone) async {
    String accessToken = await TwitterAccount.getAccessToken();
    String guestToken = await TwitterAccount.getGuestToken(accessToken);
    Map<String,String> headers = TwitterAccount.initHeaders();
    String flowToken = await _getLoginFlowToken(headers, accessToken, guestToken);
    flowToken = await _getUsernameFlowToken(headers, flowToken, username);
    flowToken = await _getPasswordFlowToken(headers, flowToken, password);
    Map<String,dynamic> res = await _getDuplicationCheckFlowToken(headers, flowToken, languageCode);
    Map<String,dynamic>? openAccount;
    if (res['subtasks']?[0]?['subtask_id'] == 'LoginTwoFactorAuthChallenge') {
      if (context != null) {
        flowToken = res['flow_token'];
        Map<String,dynamic> head = res['subtasks'][0]['enter_text']['header'];
        String? code = await askForTwoFactorCode(context, head['primary_text']['text'] as String, head['secondary_text']['text'] as String);
        if (code != null) {
          res = await _get2FAFlowToken(headers, flowToken, code);
          if (res['subtasks']?[0]?['subtask_id'] == 'LoginSuccessSubtask') {
            openAccount = res['subtasks'][0]['open_account'] as Map<String,dynamic>;
          }
        }
      }
    }
    else if (res['subtasks']?[0]?['subtask_id'] == 'LoginSuccessSubtask') {
      openAccount = res['subtasks'][0]['open_account'] as Map<String,dynamic>;
    }
    if (openAccount != null) {
      TwitterTokenEntity tte = TwitterTokenEntity(
        guest: false,
        idStr: (openAccount['user'] as Map<String,dynamic>)['id_str'] as String,
        screenName: (openAccount['user'] as Map<String,dynamic>)['screen_name'] as String,
        oauthToken: openAccount['oauth_token'] as String,
        oauthTokenSecret: openAccount['oauth_token_secret'] as String,
        createdAt: DateTime.now(),
        profile: await TwitterAccount.getOrCreateProfile(username, password, name, email, phone)
      );
      await TwitterAccount.addTwitterToken(tte);

      return tte;
    }
    throw TwitterAccountException('Unable to create the regular Twitter/X token. The response from Twitter/X was: $res');
  }

  static Future<String?> askForTwoFactorCode(BuildContext context, String primaryText, String secondaryText) async {
    String? code;
    return await showDialog<String?>(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(primaryText),
            titleTextStyle: TextStyle(fontSize: Theme.of(context).textTheme.titleMedium!.fontSize, color: Theme.of(context).textTheme.titleMedium!.color, fontWeight: FontWeight.bold),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(secondaryText, style: TextStyle(fontSize: Theme.of(context).textTheme.labelMedium!.fontSize)),
                SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(contentPadding: EdgeInsets.all(5)),
                  onChanged: (value) async {
                    code = value;
                  },
                )
              ]
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                child: Text(L10n.current.cancel),
                onPressed: () {
                  Navigator.of(context).pop(null);
                },
              ),
              ElevatedButton(
                child: Text(L10n.current.ok),
                onPressed: () {
                  Navigator.of(context).pop(code);
                },
              ),
            ],
          );
        }
    );
  }
}

