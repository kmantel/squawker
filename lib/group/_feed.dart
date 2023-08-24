import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:squawker/client.dart';
import 'package:squawker/constants.dart';
import 'package:squawker/database/entities.dart';
import 'package:squawker/database/repository.dart';
import 'package:squawker/generated/l10n.dart';
import 'package:squawker/group/group_screen.dart';
import 'package:squawker/profile/profile.dart';
import 'package:squawker/tweet/_video.dart';
import 'package:squawker/tweet/conversation.dart';
import 'package:squawker/tweet/tweet.dart';
import 'package:squawker/utils/iterables.dart';
import 'package:pref/pref.dart';
import 'package:provider/provider.dart';
import 'package:synchronized/synchronized.dart';

class SubscriptionGroupFeed extends StatefulWidget {
  final SubscriptionGroupGet group;
  final List<SubscriptionGroupFeedChunk> chunks;
  final bool includeReplies;
  final bool includeRetweets;
  final ItemScrollController? scrollController;

  const SubscriptionGroupFeed(
      {Key? key,
      required this.group,
      required this.chunks,
      required this.includeReplies,
      required this.includeRetweets,
      required this.scrollController})
      : super(key: key);

  @override
  State<SubscriptionGroupFeed> createState() => _SubscriptionGroupFeedState();
}

class _SubscriptionGroupFeedState extends State<SubscriptionGroupFeed> with WidgetsBindingObserver {

  static final log = Logger('_SubscriptionGroupFeedState');

  static final Lock _lock = Lock();

  late VisiblePositionState _visiblePositionState;
  late ItemPositionsListener _itemPositionsListener;
  bool _insertOffset = true;
  bool _keepFeedOffset = false;
  List<TweetChain> _data = [];
  bool _toScroll = false;
  Response? _errorResponse;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _visiblePositionState = VisiblePositionState();
    _itemPositionsListener = ItemPositionsListener.create();
    _itemPositionsListener.itemPositions.addListener(() { _checkFetchData(); });
    Future.delayed(Duration.zero, () {
      _checkFetchData();
    });
  }

  @override
  void dispose() {
    _updateOffset();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _updateOffset();
    }
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    _updateOffset();
    return super.didRequestAppExit();
  }

  Future<void> _checkFetchData() async {
    if (_data.isEmpty || _itemPositionsListener.itemPositions.value.first.index > 0.8 * _data.length) {
      await _lock.synchronized(() async {
        if (_data.isEmpty || _itemPositionsListener.itemPositions.value.first.index > 0.8 * _data.length) {
          BasePrefService prefs = PrefService.of(context);
          await _listTweets(_data.isEmpty, prefs);
        }
      });
    }
  }

  Future<void> _updateOffset() async {
    try {
      if (_keepFeedOffset && _visiblePositionState.initialized && _visiblePositionState.chainId != null) {
        if (kDebugMode) {
          print('*** _SubscriptionGroupFeedState._updateOffset - widget.group.id=${widget.group.id}, chainId=${_visiblePositionState.chainId}, tweetId=${_visiblePositionState.tweetId}, insert=$_insertOffset');
        }
        var repository = await Repository.writable();
        if (_insertOffset) {
          await repository.insert(tableFeedGroupPositionState, {'group_id': widget.group.id, 'chain_id': _visiblePositionState.chainId, 'tweet_id': _visiblePositionState.tweetId});
        }
        else {
          await repository.update(tableFeedGroupPositionState, {'chain_id': _visiblePositionState.chainId, 'tweet_id': _visiblePositionState.tweetId}, where: 'group_id = ?', whereArgs: [widget.group.id]);
        }
      }
    }
    catch (e, stackTrace) {
      log.warning('*** ERROR _updateOffset');
      log.warning(e);
      log.warning(stackTrace);
    }
  }

  void _resetData() {
    _visiblePositionState.initialized = false;
    _data.clear();
  }

  @override
  void didUpdateWidget(SubscriptionGroupFeed oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.includeReplies != widget.includeReplies || oldWidget.includeRetweets != widget.includeRetweets) {
      _resetData();
      _checkFetchData();
    }
  }

  String _buildSearchQuery(List<Subscription> users) {
    var query = '';
    if (!widget.includeReplies) {
      query += '-filter:replies ';
    }

    if (!widget.includeRetweets) {
      query += '-filter:retweets ';
    } else {
      query += 'include:nativeretweets ';
    }

    var remainingLength = 512 - query.length;

    for (var user in users) {
      var queryToAdd = '';
      if (user is UserSubscription) {
        queryToAdd = 'from:${user.screenName}';
      } else if (user is SearchSubscription) {
        queryToAdd = '"${user.id}"';
      }

      // If we can add this user to the query and still be less than ~512 characters, do so
      if (query.length + queryToAdd.length < remainingLength) {
        if (query.isNotEmpty) {
          query += '+OR+';
        }

        query += queryToAdd;
      } else {
        // Otherwise, add the search future and start a new one
        assert(false, 'should never reach here');
        query = queryToAdd;
      }
    }

    return query;
  }

  /// Search for our next "page" of tweets.
  ///
  /// Here, each page is actually a set of mappings, where the ID of each set is the hash of all the user IDs in that
  /// set. We store this along with the top and bottom pagination cursors, which we use to perform pagination for all
  /// sets at the same time, allowing us to create a feed made up of individual search queries.
  Future _listTweets(bool dataIsEmpty, BasePrefService prefs) async {
    try {
      List<Future<List<TweetChain>>> futures = [];

      var repository = await Repository.writable();

      _keepFeedOffset = prefs.get(optionKeepFeedOffset);
      String? positionedChainId;
      String? positionedTweetId;
      if (_keepFeedOffset) {
        var positionStateData = await repository.query(tableFeedGroupPositionState, where: 'group_id = ?', whereArgs: [widget.group.id]);
        _insertOffset = positionStateData.isEmpty;
        if (positionStateData.isNotEmpty) {
          positionedChainId = positionStateData[0]['chain_id'] as String?;
          positionedTweetId = positionStateData[0]['tweet_id'] as String?;
          if (kDebugMode) {
            print('*** _SubscriptionGroupFeedState._listTweets - repository.query - positionedChainId=$positionedChainId, positionedTweetId=$positionedTweetId');
          }
        }
      }

      _errorResponse = null;
      for (var chunk in widget.chunks) {
        var hash = chunk.hash;

        futures.add(Future(() async {
          var tweets = <TweetChain>[];

          String? searchCursor;
          String? cursorType;
          bool requestToDo = false;

          var storedChunks = await repository.query(tableFeedGroupChunk,
              where: 'group_id = ? AND hash = ?', whereArgs: [widget.group.id, hash], orderBy: 'created_at DESC');
          if (dataIsEmpty) {
            requestToDo = true;
            // Make sure we load any existing stored tweets from the chunk
            var storedChunksTweets = storedChunks
                .map((e) => jsonDecode(e['response'] as String))
                .map((e) => List.from(e))
                .expand((e) => e.map((c) => TweetChain.fromJson(c)))
                .toList();

            tweets.addAll(storedChunksTweets);

            // Use the latest chunk's top cursor to load any new tweets since the last time we checked
            var latestChunk = storedChunks.firstOrNull;
            if (latestChunk != null) {
              searchCursor = latestChunk['cursor_top'] as String;
              cursorType = 'cursor_top';
            } else {
              // Otherwise we need to perform a fresh load from scratch for this chunk
              searchCursor = null;
            }
          } else {
            // We're currently at the end of our current feed, so load the oldest chunk and use its cursor to load more
            if (storedChunks.isNotEmpty) {
              requestToDo = true;
              searchCursor = storedChunks.last['cursor_bottom'] as String;
              cursorType = 'cursor_bottom';
            }
          }

          if (requestToDo) {
            // Perform our search for the next page of results for this chunk, and add those tweets to our collection
            var query = _buildSearchQuery(chunk.users);
            TweetStatus result;
            try {
              result = await Twitter.searchTweets(query, widget.includeReplies, limit: 100,
                  cursor: searchCursor,
                  cursorType: cursorType,
                  leanerFeeds: prefs.get(optionLeanerFeeds));
            }
            catch (rsp) {
              _errorResponse = _errorResponse ?? rsp as Response;
              return [];
            }

            if (result.chains.isNotEmpty) {
              tweets.addAll(result.chains);

              // Make sure we insert the set of cursors for this latest chunk, ready for the next time we paginate
              await repository.insert(tableFeedGroupChunk, {
                'group_id': widget.group.id,
                'hash': hash,
                'cursor_top': result.cursorTop,
                'cursor_bottom': result.cursorBottom,
                'response': jsonEncode(result.chains.map((e) => e.toJson()).toList())
              });
            }
          }

          return tweets;
        }));
      }

      // Wait for all our searches to complete, then build our list of tweet conversations
      var result = (await Future.wait(futures));
      var threads = result.expand((element) => element).sorted((a, b) {
        var aCreatedAt = a.tweets[0].createdAt;
        var bCreatedAt = b.tweets[0].createdAt;

        if (aCreatedAt == null || bCreatedAt == null) {
          return 0;
        }

        return bCreatedAt.compareTo(aCreatedAt);
      }).toList();

      if (!mounted) {
        return;
      }

      if (positionedChainId != null && !_visiblePositionState.initialized) {
        int positionedChainIdx = threads.indexWhere((e) => e.id == positionedChainId);
        int positionedTweetIdx = -1;
        if (positionedChainIdx > -1 && positionedTweetId != null) {
          positionedTweetIdx = threads[positionedChainIdx].tweets.indexWhere((e) => e.idStr == positionedTweetId);
        }
        _visiblePositionState.chainIdx = positionedChainIdx > -1 ? positionedChainIdx : null;
        _visiblePositionState.tweetIdx = positionedTweetIdx > -1 ? positionedTweetIdx : null;
        if (kDebugMode) {
          print('*** _SubscriptionGroupFeedState._listTweets - setPositionIndexes - _visiblePositionState.chainIdx=${_visiblePositionState.chainIdx}, _visiblePositionState.tweetIdx=${_visiblePositionState.tweetIdx}');
        }
      }

      setState(() {
        if (dataIsEmpty) {
          _data.clear();
        }
        _data.addAll(threads);
      });

      _toScroll = false;
      if (threads.isNotEmpty && !_visiblePositionState.initialized && _visiblePositionState.chainIdx != null) {
        _toScroll = true;
      }

    } catch (e, stackTrace) {
      if (mounted) {
        // probably something to do
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    BasePrefService prefs = PrefService.of(context, listen: false);
    _keepFeedOffset = prefs.get(optionKeepFeedOffset);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_toScroll) {
        _toScroll = false;
        if (kDebugMode) {
          print('*** _SubscriptionGroupFeedState._listTweets - scrollController.jumpTo - index=${_visiblePositionState.chainIdx}, widget.group.id=${widget.group.id}');
        }
        widget.scrollController!.jumpTo(index: _visiblePositionState.chainIdx!);
      }
    });

    if (widget.chunks.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(L10n.of(context).this_group_contains_no_subscriptions),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _updateOffset();
          _resetData();
          _checkFetchData();
        },
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<TweetContextState>(
                create: (_) => TweetContextState(prefs.get(optionTweetsHideSensitive))),
            ChangeNotifierProvider<VideoContextState>(
                create: (_) => VideoContextState(prefs.get(optionMediaDefaultMute))),
          ],
          child: ScrollablePositionedList.builder(
            itemCount: _data.length,
            itemBuilder: (context, index) {
              TweetChain tc = _data[index];
              return TweetConversation(key: ValueKey(tc.id), id: tc.id, username: null, isPinned: tc.isPinned, tweets: tc.tweets, visiblePositionState: _visiblePositionState);
            },
            itemScrollController: widget.scrollController,
            itemPositionsListener: _itemPositionsListener,
            padding: const EdgeInsets.only(top: 4),
          ),
        ),
      ),
    );
  }
}
