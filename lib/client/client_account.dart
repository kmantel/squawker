import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_triple/flutter_triple.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squawker/client/client_guest_account.dart';
import 'package:squawker/client/client_regular_account.dart';
import 'package:squawker/utils/iterables.dart';
import 'package:squawker/database/entities.dart';
import 'package:squawker/database/repository.dart';
import 'package:squawker/utils/crypto_util.dart';
import 'package:squawker/utils/misc.dart';
import 'package:synchronized/synchronized.dart';

class TwitterAccount {
  static final log = Logger('TwitterAccount');

  static TwitterTokenEntity? _currentTwitterToken;
  static final List<TwitterProfileEntity> _twitterProfileLst = [];
  static final List<TwitterTokenEntity> _twitterTokenLst = [];
  static final Map<String,List<Map<String,int>>> _rateLimits = {};
  static final List<TwitterTokenEntity> _twitterTokenToDeleteLst = [];

  static BuildContext? _currentContext;
  static String? _currentLanguageCode;

  static void setCurrentContext(BuildContext currentContext) {
    _currentContext = currentContext;
    _currentLanguageCode = Localizations.localeOf(currentContext).languageCode;
  }

  static int nbrGuestAccounts() {
    return _twitterTokenLst.where((e) => e.guest).length;
  }

  static List<TwitterTokenEntity> getRegularAccountsTokens() {
    return _twitterTokenLst.where((e) => !e.guest).toList();
  }

  // this must be executed only once at the start of the application
  static Future<void> loadAllTwitterTokensAndRateLimits() async {
    var repository = await Repository.writable();

    // load the Twitter/X token list, sorted by creation ascending
    var twitterProfilesDbData = await repository.query(tableTwitterProfile);
    _twitterProfileLst.clear();
    for (int i = 0; i < twitterProfilesDbData.length; i++) {
      TwitterProfileEntity tpe = TwitterProfileEntity(
        username: twitterProfilesDbData[i]['username'] as String,
        password: twitterProfilesDbData[i]['password'] as String,
        createdAt: DateTime.parse(twitterProfilesDbData[i]['created_at'] as String),
        name: twitterProfilesDbData[i]['name'] as String?,
        email: twitterProfilesDbData[i]['email'] as String?,
        phone: twitterProfilesDbData[i]['phone'] as String?
      );
      _twitterProfileLst.add(tpe);
    }
    var twitterTokensDbData = await repository.query(tableTwitterToken);
    _twitterTokenLst.clear();
    for (int i = 0; i < twitterTokensDbData.length; i++) {
      TwitterTokenEntity tte = TwitterTokenEntity(
        guest: twitterTokensDbData[i]['guest'] == 1,
        idStr: twitterTokensDbData[i]['id_str'] as String,
        screenName: twitterTokensDbData[i]['screen_name'] as String,
        oauthToken: twitterTokensDbData[i]['oauth_token'] as String,
        oauthTokenSecret: twitterTokensDbData[i]['oauth_token_secret'] as String,
        createdAt: DateTime.parse(twitterTokensDbData[i]['created_at'] as String)
      );
      if (!tte.guest) {
        TwitterProfileEntity? twitterProfile = _twitterProfileLst.firstWhereOrNull((e) => e.username == tte.screenName);
        if (twitterProfile != null) {
          tte.profile = twitterProfile;
        }
      }
      _twitterTokenLst.add(tte);
    }
    if (_twitterTokenLst.isNotEmpty) {
      _twitterTokenLst.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // delete records from the rate_limits table that are not valid anymore (if applicable)
      List<String> oauthTokenLst = _twitterTokenLst.map((e) => e.oauthToken).toList();
      await repository.delete(tableRateLimits, where: 'oauth_token IS NOT NULL AND oauth_token NOT IN (${List.filled(oauthTokenLst.length, '?').join(',')})', whereArgs: oauthTokenLst);
    }

    // load the rate limits
    var rateLimitsDbData = await repository.query(tableRateLimits);
    _rateLimits.clear();
    List<String> oauthTokenFoundLst = [];
    for (int i = 0; i < rateLimitsDbData.length; i++) {
      String oauthToken = (rateLimitsDbData[i]['oauth_token'] ?? '') as String;
      oauthTokenFoundLst.add(oauthToken);
      String remainingData = rateLimitsDbData[i]['remaining'] as String;
      String resetData = rateLimitsDbData[i]['reset'] as String;
      Map<String,dynamic> jRateLimitRemaining = json.decode(remainingData);
      Map<String,int> rateLimitRemaining = jRateLimitRemaining.entries.fold({}, (prev, elm) {
        prev[elm.key] = elm.value;
        return prev;
      });
      Map<String,dynamic> jRateLimitReset = json.decode(resetData);
      Map<String,int> rateLimitReset = jRateLimitReset.entries.fold({}, (prev, elm) {
        prev[elm.key] = elm.value;
        return prev;
      });
      List<Map<String,int>> lst = [];
      lst.add(rateLimitRemaining);
      lst.add(rateLimitReset);
      _rateLimits[oauthToken] = lst;
    }
    // if there are accounts without their rate limits, initialize them
    for (int i = 0; i < _twitterTokenLst.length; i++) {
      String oauthToken = _twitterTokenLst[i].oauthToken;
      if (!oauthTokenFoundLst.contains(oauthToken)) {
        _rateLimits[oauthToken] = [{},{}];
        await repository.insert(tableRateLimits, {'remaining': json.encode({}), 'reset': json.encode({}), 'oauth_token': oauthToken});
      }
    }
    // if there is the rate limits block associated with the "null" oauthToken (after migration from 3.5.4)
    // associate it with a available non-null oauthToken, then delete the block
    if (_rateLimits.keys.contains('')) {
      MapEntry<String,List<Map<String,int>>>? merl = _rateLimits.entries.firstWhereOrNull((e) => e.key != '' && e.value[0].isEmpty);
      if (merl != null) {
        _rateLimits[merl.key] = _rateLimits[''] as List<Map<String,int>>;
        _rateLimits.remove('');
        await repository.delete(tableRateLimits, where: 'oauth_token IS NULL');
      }
    }
  }

  static Future<void> initTwitterToken(String uriPath, int total) async {
    // first try to create a guest Twitter/X token if it's been at least 24 hours since the last creation
    // possibly will be removed in future versions
    TwitterAccountException? lastGuestAccountExc;
    DateTime? lastGuestTwitterTokenCreationAttempted = await _getLastGuestTwitterTokenCreationAttempted();
    if (lastGuestTwitterTokenCreationAttempted == null || DateTime.now().difference(lastGuestTwitterTokenCreationAttempted).inHours >= 24) {
      try {
        await _setLastGuestTwitterTokenCreationAttempted();
        await TwitterGuestAccount.createGuestTwitterToken();
      }
      on TwitterAccountException catch (_, ex) {
        log.warning('*** Try to create a guest Twitter/X token after 24 hours with error: ${_.toString()}');
        lastGuestAccountExc = _;
      }
    }

    // possibly renew the tokens associated to the regular Twitter/X accounts
    await _renewProfilesTokens();

    // delete Twitter/X tokens marked for deletion
    await deleteTwitterTokensMarkedForDeletion();

    // now find the first Twitter/X token that is available or at least with the minimum waiting time
    Map<String,dynamic>? twitterTokenInfo = await getNextTwitterTokenInfo(uriPath, total);
    if (twitterTokenInfo == null) {
      if (lastGuestAccountExc != null) {
        throw lastGuestAccountExc;
      }
      else {
        throw TwitterAccountException('There is a problem getting a Twitter/X token.');
      }
    }
    else if (twitterTokenInfo['twitterToken'] != null) {
      _currentTwitterToken = twitterTokenInfo['twitterToken'];
    }
    else if (twitterTokenInfo['minRateLimitReset'] != 0) {
      Map<String,dynamic> di = TwitterAccount.delayInfo(twitterTokenInfo['minRateLimitReset']);
      throw RateLimitException('The request $uriPath has reached its limit. Please wait ${di['minutesStr']}.', longDelay: di['longDelay']);
    }
    else {
      throw RateLimitException('There is a problem getting a Twitter/X token.');
    }
  }

  // renew the regular Twitter/X account tokens after 30 days
  static Future<void> _renewProfilesTokens() async {
    for (int i = 0; i < _twitterProfileLst.length; i++) {
      TwitterProfileEntity tpe = _twitterProfileLst[i];
      TwitterTokenEntity? tte = _twitterTokenLst.firstWhereOrNull((e) => e.profile != null && e.profile!.username == tpe.username);
      if (tte != null) {
        if (DateTime.now().difference(tte.createdAt).inDays >= 30) {
          TwitterTokenEntity newTte = await TwitterRegularAccount.createRegularTwitterToken(_currentContext, _currentLanguageCode, tpe.username, tpe.password, tpe.name, tpe.email, tpe.phone);
          addTwitterToken(newTte);
          markTwitterTokenForDeletion(tte);
        }
      }
    }
  }

  static Future<DateTime?> _getLastGuestTwitterTokenCreationAttempted() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? lastGuestAccountsCreationAttemptedLst = prefs.getStringList('lastGuestAccountsCreationsAttempted');
    if (lastGuestAccountsCreationAttemptedLst == null) {
      return null;
    }
    String? publicIP = await getPublicIP();
    if (publicIP == null) {
      return null;
    }
    String? ipLastGuestAccountsCreationAttemptedStr = lastGuestAccountsCreationAttemptedLst.firstWhereOrNull((e) => e.startsWith('$publicIP='));
    if (ipLastGuestAccountsCreationAttemptedStr == null) {
      return null;
    }
    String lastGuestAccountsCreationAttemptedStr = ipLastGuestAccountsCreationAttemptedStr.substring('$publicIP='.length);
    return DateTime.parse(lastGuestAccountsCreationAttemptedStr);
  }

  static Future<void> _setLastGuestTwitterTokenCreationAttempted() async {
    String? publicIP = await getPublicIP();
    if (publicIP == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    List<String> lastGuestAccountsCreationAttemptedLst = prefs.getStringList('lastGuestAccountsCreationsAttempted') ?? [];
    int idx = lastGuestAccountsCreationAttemptedLst.indexWhere((e) => e.startsWith('$publicIP='));
    if (idx != -1) {
      lastGuestAccountsCreationAttemptedLst.removeAt(idx);
    }
    String ipLastGuestAccountsCreationAttemptedStr = '$publicIP=${DateTime.now().toIso8601String()}';
    lastGuestAccountsCreationAttemptedLst.add(ipLastGuestAccountsCreationAttemptedStr);
    prefs.setStringList('lastGuestAccountsCreationsAttempted', lastGuestAccountsCreationAttemptedLst);
  }

  static Future<void> updateRateValues(String uriPath, int remaining, int reset) async {
    if (_currentTwitterToken == null) {
      // this should not happens
      return;
    }
    String oauthToken = _currentTwitterToken!.oauthToken;
    if (_rateLimits[oauthToken] == null) {
      // this should not happens
      return;
    }
    List<Map<String,int>> rateLimitsToken = _rateLimits[oauthToken]!;
    Map<String,int> rateLimitRemaining = rateLimitsToken[0];
    Map<String,int> rateLimitReset = rateLimitsToken[1];
    rateLimitRemaining[uriPath] = remaining;
    rateLimitReset[uriPath] = reset;
    var repository = await Repository.writable();
    await repository.update(tableRateLimits, {'remaining': json.encode(rateLimitRemaining), 'reset': json.encode(rateLimitReset)}, where: 'oauth_token = ?', whereArgs: [ oauthToken ]);
  }

  static Future<Map<String,dynamic>?> getNextTwitterTokenInfo(String uriPath, int total) async {
    final prefs = await SharedPreferences.getInstance();
    String? lastTwitterOauthToken = prefs.getString('lastTwitterOauthToken');
    int startIndex = lastTwitterOauthToken == null ? 0 : _twitterTokenLst.indexWhere((e) => e.oauthToken == lastTwitterOauthToken);
    if (startIndex == -1) {
      startIndex = 0;
    }
    int minRateLimitReset = double.maxFinite.round();
    bool minResetSet = false;
    int idx = startIndex;
    int cnt = 0;
    while (cnt < _twitterTokenLst.length) {
      TwitterTokenEntity twitterToken = _twitterTokenLst[idx];
      String oauthToken = twitterToken.oauthToken;
      int? rateLimitRemaining = _rateLimits[oauthToken]![0][uriPath];
      int? rateLimitReset = _rateLimits[oauthToken]![1][uriPath];
      if (rateLimitReset != null && rateLimitReset < minRateLimitReset) {
        minRateLimitReset = rateLimitReset;
        minResetSet = true;
      }
      if (rateLimitRemaining == null || rateLimitRemaining >= total) {
        prefs.setString('lastTwitterOauthToken', twitterToken.oauthToken);
        return {
          'twitterToken': twitterToken,
          'minRateLimitReset': null
        };
      }
      idx++;
      if (idx == _twitterTokenLst.length) {
        idx = 0;
      }
    }
    if (minResetSet) {
      return {
        'twitterToken': null,
        'minRateLimitReset': minResetSet
      };
    }
    else {
      return null;
    }
  }

  static void markCurrentTwitterTokenForDeletion() {
    markTwitterTokenForDeletion(_currentTwitterToken);
  }

  static void markTwitterTokenForDeletion(TwitterTokenEntity? twitterToken) {
    if (twitterToken == null) {
      // should not happens
      return;
    }
    String oauthToken = twitterToken.oauthToken;
    if (_twitterTokenToDeleteLst.firstWhereOrNull((e) => e.oauthToken == oauthToken) == null) {
      _twitterTokenToDeleteLst.add(twitterToken);
    }
  }

  static Future<void> deleteTwitterTokensMarkedForDeletion() async {
    if (_twitterTokenToDeleteLst.isEmpty) {
      return;
    }
    log.info('Deleting expired twitter tokens');

    List<String> tokenOauthToDeleteLst = _twitterTokenLst.where((tt) => _twitterTokenToDeleteLst.firstWhereOrNull((ttd) => ttd.oauthToken == tt.oauthToken) != null).map((e) => e.oauthToken).toList();
    List<String> rateOauthToDeleteLst = _rateLimits.keys.where((key) => _twitterTokenToDeleteLst.firstWhereOrNull((ttd) => ttd.oauthToken == key) != null).toList();

    if (tokenOauthToDeleteLst.isNotEmpty) {
      _twitterTokenLst.removeWhere((tt) => _twitterTokenToDeleteLst.firstWhereOrNull((ttd) => ttd.oauthToken == tt.oauthToken) != null);
    }
    if (rateOauthToDeleteLst.isNotEmpty) {
      _rateLimits.removeWhere((key, value) => _twitterTokenToDeleteLst.firstWhereOrNull((ttd) => ttd.oauthToken == key) != null);
    }

    // this must be executed last. make sure that there are no more active regular token associated with a profile to delete it.
    List<String> profileUsernameToDeleteLst = _twitterProfileLst.where((tp) => _twitterTokenLst.firstWhereOrNull((tt) => !tt.guest && tt.profile!.username == tp.username) == null).map((e) => e.username).toList();
    if (profileUsernameToDeleteLst.isNotEmpty) {
      _twitterProfileLst.removeWhere((tp) => _twitterTokenLst.firstWhereOrNull((tt) => !tt.guest && tt.profile!.username == tp.username) == null);
    }

    var database = await Repository.writable();

    if (tokenOauthToDeleteLst.isNotEmpty) {
      await database.delete(tableRateLimits, where: 'oauth_token IN (${List.filled(tokenOauthToDeleteLst.length, '?').join(',')})', whereArgs: tokenOauthToDeleteLst);
    }
    if (rateOauthToDeleteLst.isNotEmpty) {
      await database.delete(tableTwitterToken, where: "oauth_token IN (${List.filled(rateOauthToDeleteLst.length, '?').join(',')}) ", whereArgs: rateOauthToDeleteLst);
    }
    if (profileUsernameToDeleteLst.isNotEmpty) {
      await database.delete(tableTwitterProfile, where: "username IN (${List.filled(profileUsernameToDeleteLst.length, '?').join(',')}) ", whereArgs: profileUsernameToDeleteLst);
    }

    _twitterTokenToDeleteLst.clear();
  }

  static Future<void> addTwitterToken(TwitterTokenEntity twitterToken) async {
    _twitterTokenLst.add(twitterToken);
    String oauthToken = twitterToken.oauthToken;
    _rateLimits[oauthToken] = [{},{}];

    var repository = await Repository.writable();
    Map<String,dynamic> ttm = twitterToken.toMap();
    ttm.remove('profile');
    var ret = await repository.insert(tableTwitterToken, ttm);
    await repository.insert(tableRateLimits, {'remaining': json.encode({}), 'reset': json.encode({}), 'oauth_token': oauthToken});
  }

  static Future<TwitterProfileEntity> getOrCreateProfile(String username, String password, String? name, String? email, String? phone) async {
    TwitterProfileEntity? tpe = _twitterProfileLst.firstWhereOrNull((e) => e.username == username);
    if (tpe != null) {
      return tpe;
    }
    tpe = TwitterProfileEntity(
      username: username,
      password: password,
      createdAt: DateTime.now(),
      name: name,
      email: email,
      phone: phone
    );
    _twitterProfileLst.add(tpe);

    var repository = await Repository.writable();
    await repository.insert(tableTwitterProfile, tpe.toMap());

    return tpe;
  }

  static Future<TwitterTokenEntity> createRegularTwitterToken(String username, String password, String? name, String? email, String? phone) async {
    TwitterTokenEntity? oldTte = _twitterTokenLst.firstWhereOrNull((e) => !e.guest && e.screenName == username);
    TwitterTokenEntity newTte = await TwitterRegularAccount.createRegularTwitterToken(_currentContext, _currentLanguageCode, username, password, name, email, phone);
    if (oldTte != null) {
      markTwitterTokenForDeletion(oldTte);
      await deleteTwitterTokensMarkedForDeletion();
    }
    return newTte;
  }

  static Future<String> getAccessToken() async {
    String oauthConsumerKeySecret = base64.encode(utf8.encode('$oauthConsumerKey:$oauthConsumerSecret'));

    log.info('Posting https://api.twitter.com/oauth2/token');
    var response = await http.post(Uri.parse('https://api.twitter.com/oauth2/token'),
        headers: {
          'Authorization': 'Basic $oauthConsumerKeySecret',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: {
          'grant_type': 'client_credentials'
        }
    );

    if (response.statusCode == 200) {
      var result = jsonDecode(response.body);
      if (result.containsKey('access_token')) {
        return result['access_token'];
      }
    }

    throw TwitterAccountException('Unable to get the access token. The response (${response.statusCode}) from Twitter/X was: ${response.body}');
  }

  static Future<String> getGuestToken(String accessToken) async {
    log.info('Posting https://api.twitter.com/1.1/guest/activate.json');
    var response = await http.post(Uri.parse('https://api.twitter.com/1.1/guest/activate.json'),
        headers: {
          'Authorization': 'Bearer $accessToken'
        }
    );

    if (response.statusCode == 200) {
      var result = jsonDecode(response.body);
      if (result.containsKey('guest_token')) {
        return result['guest_token'];
      }
    }

    throw TwitterAccountException('Unable to get the guest token. The response (${response.statusCode}) from Twitter/X was: ${response.body}');
  }

  static Map<String,String> initHeaders() {
    return {
      'Content-Type': 'application/json',
      'User-Agent': 'TwitterAndroid/10.10.0 (29950000-r-0) ONEPLUS+A3010/9 (OnePlus;ONEPLUS+A3010;OnePlus;OnePlus3;0;;1;2016)',
      'X-Twitter-API-Version': '5',
      'X-Twitter-Client': 'TwitterAndroid',
      'X-Twitter-Client-Version': '10.10.0',
      'OS-Version': '28',
      'System-User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 9; ONEPLUS A3010 Build/PKQ1.181203.001)',
      'X-Twitter-Active-User': 'yes',
    };
  }

  static Future<String> _getSignOauth(Uri uri, String method) async {
    if (_currentTwitterToken == null) {
      throw TwitterAccountException('There is a problem getting a Twitter/X token.');
    }
    Map<String,String> params = Map<String,String>.from(uri.queryParameters);
    params['oauth_version'] = '1.0';
    params['oauth_signature_method'] = 'HMAC-SHA1';
    params['oauth_consumer_key'] = oauthConsumerKey;
    params['oauth_token'] = _currentTwitterToken!.oauthToken;
    params['oauth_nonce'] =  nonce();
    params['oauth_timestamp'] = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
    String methodUp = method.toUpperCase();
    String link = Uri.encodeComponent('${uri.origin}${uri.path}');
    String paramsToSign = params.keys.sorted((a, b) => a.compareTo(b)).map((e) => '$e=${Uri.encodeComponent(params[e]!)}').join('&').replaceAll('+', '%20').replaceAll('%', '%25').replaceAll('=', '%3D').replaceAll('&', '%26');
    String toSign = '$methodUp&$link&$paramsToSign';
    //print('paramsToSign=$paramsToSign');
    //print('toSign=$toSign');
    String signature = Uri.encodeComponent(await hmacSHA1('$oauthConsumerSecret&${_currentTwitterToken!.oauthTokenSecret}', toSign));
    return 'OAuth realm="http://api.twitter.com/", oauth_version="1.0", oauth_token="${params["oauth_token"]}", oauth_nonce="${params["oauth_nonce"]}", oauth_timestamp="${params["oauth_timestamp"]}", oauth_signature="$signature", oauth_consumer_key="${params["oauth_consumer_key"]}", oauth_signature_method="HMAC-SHA1"';
  }

  static Future<http.Response> _doFetch(Uri uri, RateFetchContext fetchContext, {Map<String, String>? headers}) async {
    try {
      String authorization = await _getSignOauth(uri, 'GET');
      var response = await http.get(uri, headers: {
        ...?headers,
        'Connection': 'Keep-Alive',
        'Authorization': authorization,
        'Content-Type': 'application/json',
        'X-Twitter-Active-User': 'yes',
        'Authority': 'api.twitter.com',
        'Accept-Encoding': 'gzip',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept': '*/*',
        'DNT': '1',
        'User-Agent': 'TwitterAndroid/10.10.0 (29950000-r-0) ONEPLUS+A3010/9 (OnePlus;ONEPLUS+A3010;OnePlus;OnePlus3;0;;1;2016)',
        'X-Twitter-API-Version': '5',
        'X-Twitter-Client': 'TwitterAndroid',
        'X-Twitter-Client-Version': '10.10.0',
        'OS-Version': '28',
        'System-User-Agent': 'Dalvik/2.1.0 (Linux; U; Android 9; ONEPLUS A3010 Build/PKQ1.181203.001)',
      });

      await fetchContext.fetchWithResponse(response);

      return response;
    }
    catch (err) {
      log.severe('_doFetch - The request ${uri.path} has an error: ${err.toString()}');
      await fetchContext.fetchNoResponse();
      rethrow;
    }
  }

  static Future<http.Response> fetch(Uri uri, {Map<String, String>? headers, RateFetchContext? fetchContext}) async {
    if (fetchContext == null) {
      fetchContext = RateFetchContext(uri.path, 1);
      await fetchContext.init();
    }

    http.Response rsp = await _doFetch(uri, fetchContext, headers: headers);

    return rsp;
  }

  static Map<String,dynamic> delayInfo(int targetDateTime) {
    Duration d = DateTime.fromMillisecondsSinceEpoch(targetDateTime).difference(DateTime.now());
    String minutesStr;
    if (!d.isNegative) {
      if (d.inMinutes > 59) {
        int minutes = d.inMinutes % 60;
        minutesStr = minutes > 1 ? '$minutes minutes' : '1 minute';
        minutesStr = d.inHours > 1 ? '${d.inHours} hours, $minutesStr' : '1 hour, $minutesStr';
      }
      else {
        minutesStr = d.inMinutes > 1 ? '${d.inMinutes} minutes' : '1 minute';
      }
    }
    else {
      d = const Duration(minutes: 1);
      minutesStr = '1 minute';
    }
    return {
      'minutesStr': minutesStr,
      'longDelay': d.inMinutes > 30
    };
  }

}

class RateLimitException implements Exception {
  final String message;
  final bool longDelay;

  RateLimitException(this.message, {this.longDelay = false});

  @override
  String toString() {
    return message;
  }
}

class TwitterAccountException implements Exception {
  final String message;

  TwitterAccountException(this.message);

  @override
  String toString() {
    return message;
  }
}

class ExceptionResponse extends http.Response {
  final Exception exception;

  ExceptionResponse(this.exception) : super(exception.toString(), 500);

  @override
  String toString() {
    return exception.toString();
  }
}

class RateFetchContext {
  String uriPath;
  int total;
  int counter = 0;
  List<int?> remainingLst = [];
  List<int?> resetLst = [];
  Lock lock = Lock();

  RateFetchContext(this.uriPath, this.total);

  Future<void> init() async {
    await TwitterAccount.initTwitterToken(uriPath, total);
  }

  Future<void> fetchNoResponse() async {
    await lock.synchronized(() async {
      if (counter == total) {
        return;
      }
      counter++;
      remainingLst.add(null);
      resetLst.add(null);
      await _checkTotal();
    });
  }

  Future<void> fetchWithResponse(http.Response response) async {
    await lock.synchronized(() async {
      if (counter == total) {
        return;
      }
      counter++;
      var headerRateLimitRemaining = response.headers['x-rate-limit-remaining'];
      var headerRateLimitReset = response.headers['x-rate-limit-reset'];
      TwitterAccount.log.info('*** headerRateLimitRemaining=$headerRateLimitRemaining, headerRateLimitReset=$headerRateLimitReset');
      if (response.statusCode == 401 && response.body.contains('Invalid or expired token')) {
        remainingLst.add(-2);
        resetLst.add(0);
      }
      else if (headerRateLimitRemaining == null || headerRateLimitReset == null) {
        TwitterAccount.log.info('The request $uriPath has no rate limits.');
        remainingLst.add(null);
        resetLst.add(null);
      }
      else if (response.statusCode == 429 && response.body.contains('Rate limit exceeded')) {
        // Twitter/X API documentation specify a 24 hours waiting time, but I experimented a 12 hours embargo.
        remainingLst.add(-1);
        resetLst.add(DateTime.now().add(const Duration(hours: 12)).millisecondsSinceEpoch);
      }
      else {
        int remaining = int.parse(headerRateLimitRemaining);
        int reset = int.parse(headerRateLimitReset) * 1000;
        remainingLst.add(remaining);
        resetLst.add(reset);
      }
      await _checkTotal();
    });
  }

  Future<void> _checkTotal() async {
    if (counter < total) {
      return;
    }
    int minRemaining = double.maxFinite.round();
    int minReset = -1;
    for (int i = 0; i < remainingLst.length; i++) {
      if (remainingLst[i] != null && remainingLst[i]! < minRemaining) {
        minRemaining = remainingLst[i]!;
        minReset = resetLst[i]!;
      }
    }
    if (minReset == -1) {
      return;
    }
    if (minRemaining == -2) {
      TwitterAccount.markCurrentTwitterTokenForDeletion();
    }
    await TwitterAccount.updateRateValues(uriPath, minRemaining, minReset);
    if (minRemaining <= -1) {
      // this should not happened but just in case, check if there is another guest account that is NOT with an embargo
      Map<String,dynamic>? twitterTokenInfoTmp = await TwitterAccount.getNextTwitterTokenInfo(uriPath, total);
      if (twitterTokenInfoTmp == null) {
        throw RateLimitException('There is a problem getting an account Twitter/X token.');
      }
      else {
        if (twitterTokenInfoTmp['twitterToken'] != null) {
          throw RateLimitException('The request $uriPath has reached its limit. Please wait 1 minute.');
        }
        else if (twitterTokenInfoTmp['minRateLimitReset'] != 0) {
          Map<String,dynamic> di = TwitterAccount.delayInfo(twitterTokenInfoTmp['minRateLimitReset']);
          throw RateLimitException('The request $uriPath has reached its limit. Please wait ${di['minutesStr']}.', longDelay: di['longDelay']);
        }
        else {
          throw RateLimitException('There is a problem getting a Twitter/X token.');
        }
      }
    }
  }

}

class TwitterTokensModel extends Store<List<TwitterTokenEntity>> {
  static final log = Logger('TwitterTokensModel');

  TwitterTokensModel() : super([]);

  Future<void> reloadTokens() async {
    log.info('Reload twitter tokens');

    await execute(() async {
      var database = await Repository.readOnly();

      List<TwitterProfileEntity> profileLst = (await database.query(tableTwitterProfile)).map((e) => TwitterProfileEntity.fromMap(e)).toList();
      List<TwitterTokenEntity> tokenLst = (await database.query(tableTwitterToken)).map((t) {
        TwitterTokenEntity tte = TwitterTokenEntity.fromMap(t);
        tte.profile = tte.guest ? null : profileLst.firstWhereOrNull((p) => p.username == tte.screenName);
        return tte;
      }).toList();
      return tokenLst;
    });
  }
}
