import 'package:flutter/material.dart';
import 'package:yande_web/models/booru_posts.dart';
import 'package:yande_web/models/yande/post.dart';
import 'package:yande_web/extensions/list_extension.dart';
import 'package:yande_web/pages/home_page.dart';
import 'package:yande_web/settings/app_settings.dart';
import 'post_preview.dart';

class SliverPostWaterfall extends StatefulWidget {
  // The width this widght will take
  @required
  final double panelWidth;
  final ScrollController controller;

  SliverPostWaterfall({this.panelWidth, this.controller, Key key})
      : super(key: key);

  @override
  _SliverPostWaterfallState createState() => _SliverPostWaterfallState();
}

class _SliverPostWaterfallState extends State<SliverPostWaterfall> {
  ScrollController _controller;
  bool isFinishedFetch = true;
  List<Post> posts = List<Post>();
  List<List<Post>> fixedPosts = List<List<Post>>();
  FetchType currentFetchType = FetchType.Posts;
  BooruPosts _booruPosts;
  DateTime _dateTime = DateTime.now();
  int page = 1;

  _SliverPostWaterfallState() {
    updadePost = _updateCall;
    _booruPosts = new BooruPosts();
  }

  _setDateTime(DateTime dateTime) {
    _dateTime = dateTime;
    _fetchByType(currentFetchType);
  }

  _updateCall(FetchType fetchType) {
    if (fetchType == currentFetchType) {
      return;
    } else {
      setState(() {
        _dateTime = DateTime.now();
        fixedPosts.clear();
        currentFetchType = fetchType;
        page = 1;
        _fetchByType(fetchType);
      });
    }
  }

  _fetchByType(FetchType t) {
    isFinishedFetch = false;
    switch (t) {
      case FetchType.Posts:
        _booruPosts.fetchPosts().then((value) {
          setState(() {
            posts.addAll(value.where((o) => !posts.contains(o)));
            fixedPosts.addAllPost(posts, widget.panelWidth - 10);
            isFinishedFetch = true;
          });
        });
        break;
      case FetchType.PopularRecent:
        _booruPosts.fetchPopularRecent().then((value) {
          setState(() {
            posts.addAll(value.where((o) => !posts.contains(o)));
            fixedPosts.addAllPost(posts, widget.panelWidth - 10);
            isFinishedFetch = true;
          });
        });
        break;
      case FetchType.PopularByWeek:
        _booruPosts
            .fetchPopularByWeek(
                day: _dateTime.day,
                month: _dateTime.month,
                year: _dateTime.year)
            .then((value) {
          setState(() {
            fixedPosts.clear();
            posts.addAll(value.where((o) => !posts.contains(o)));
            fixedPosts.addAllPost(posts, widget.panelWidth - 10);
            isFinishedFetch = true;
          });
        });
        break;
      case FetchType.PopularByMonth:
        _booruPosts
            .fetchPopularByMonth(month: _dateTime.month, year: _dateTime.year)
            .then((value) {
          setState(() {
            fixedPosts.clear();
            posts.addAll(value.where((o) => !posts.contains(o)));
            fixedPosts.addAllPost(posts, widget.panelWidth - 10);
            isFinishedFetch = true;
          });
        });
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([_buildSliver()]),
    );
  }

  Widget _buildSliver() {
    if (fixedPosts.length == 0) {
      return Center(child: Text("Loading"));
    } else {
      return _buildWidght();
    }
  }

  Widget _datePicker() {
    if (currentFetchType == FetchType.PopularByWeek ||
        currentFetchType == FetchType.PopularByMonth) {
      return Container(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            FlatButton(
              child: Icon(Icons.arrow_back),
              onPressed: () {},
            ),
            FlatButton(
              child:
                  Text("${_dateTime.month} ${_dateTime.day} ${_dateTime.year}"),
              onPressed: () {
                showDatePicker(
                        firstDate: AppSettings.currentClient == ClientType.Yande
                            ? AppSettings.yandeFirstday
                            : AppSettings.konachanFirstday,
                        lastDate: DateTime(DateTime.now().year,
                            DateTime.now().month, DateTime.now().day + 1),
                        context: context,
                        initialDate: DateTime.now())
                    .then((x) {
                  if (x != null) _setDateTime(x);
                });
              },
            ),
            FlatButton(
              child: Icon(Icons.arrow_forward),
              onPressed: () {},
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  // Page content
  Container _buildWidght() {
    var s = Container(
      child: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 40, 0, 0),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[]..addAll(_buildPostPreview()),
            )),
      ),
    );
    return s;
  }

  _scrollListener() {
    // Reach the bottom
    if (_controller.offset >= _controller.position.maxScrollExtent - 800 &&
        !_controller.position.outOfRange) {
      print('Reach the bottom');

      if (isFinishedFetch && currentFetchType == FetchType.Posts) {
        isFinishedFetch = false;
        page++;
        _booruPosts.fetchPosts(page: page).then((value) {
          setState(() {
            posts.addAll(value.where((o) => !posts.contains(o)));
            fixedPosts.addAllPost(posts, widget.panelWidth - 10);
            isFinishedFetch = true;
          });
        });
      }
    }
    // //  Reach the top
    // if (_controller.offset <= _controller.position.minScrollExtent &&
    //     !_controller.position.outOfRange) {
    // }
  }

  _buildPostPreview() {
    var list = new List<PostPreview>();
    fixedPosts.forEach((x) {
      x.forEach((f) {
        list.add(PostPreview(
          post: f,
        ));
      });
    });
    return list;
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(_scrollListener);
    isFinishedFetch = false;
    _booruPosts.fetchPosts().then((value) {
      setState(() {
        posts.addAll(value);
        fixedPosts.addAllPost(posts, widget.panelWidth - 15);
        isFinishedFetch = true;
      });
    });
  }
}
