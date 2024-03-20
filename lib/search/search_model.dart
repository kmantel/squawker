import 'package:flutter_triple/flutter_triple.dart';
import 'package:squawker/client/client.dart';
import 'package:squawker/user.dart';

class SearchTweetsModel extends Store<SearchStatus<TweetWithCard>> {
  SearchTweetsModel() : super(SearchStatus(items: []));

  Future<void> searchTweets(String query, bool enhanced, {bool trending = false, String? cursor}) async {
    await execute(() async {
      if (query.isEmpty) {
        return SearchStatus(items: []);
      } else {
        if (enhanced) {
          TweetStatus ts = await Twitter.searchTweetsGraphql(query, true, trending: trending, cursor: cursor);
          return SearchStatus(items: ts.chains.map((e) => e.tweets).expand((e) => e).toList(), cursorBottom: ts.cursorBottom);
        }
        else {
          TweetStatus ts = await Twitter.searchTweets(query, true, cursor: cursor, cursorType: cursor != null ? 'cursor_bottom' : null);
          return SearchStatus(items: ts.chains.map((e) => e.tweets).expand((e) => e).toList(), cursorBottom: ts.cursorBottom);
        }
      }
    });
  }
}

class SearchUsersModel extends Store<SearchStatus<UserWithExtra>> {
  SearchUsersModel() : super(SearchStatus(items: []));

  Future<void> searchUsers(String query, bool enhanced, {String? cursor}) async {
    await execute(() async {
      if (query.isEmpty) {
        return SearchStatus(items: []);
      } else {
        if (enhanced) {
          return await Twitter.searchUsersGraphql(query, limit: 100, cursor: cursor);
        }
        else {
          return await Twitter.searchUsers(query, limit: 100);
        }
      }
    });
  }
}
