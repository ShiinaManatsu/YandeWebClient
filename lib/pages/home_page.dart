import 'package:floating_search_bar/ui/sliver_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:yande_web/main.dart';
import 'package:yande_web/models/rx/booru_api.dart';
import 'package:yande_web/models/rx/booru_bloc.dart';
import 'package:yande_web/models/rx/update_args.dart';
import 'package:yande_web/pages/widgets/sliver_post_waterfall_widget.dart';
import 'package:yande_web/settings/app_settings.dart';

BooruBloc booruBloc;
String searchTerm = "";
double panelWidth = 1000;
PublishSubject<FetchType> homePageFetchTypeChanged =
    PublishSubject<FetchType>();

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  /// Private properties
  //static const double _leftPanelWidth = 86;
  FetchType _type = FetchType.Posts; // Current browser type
  static const Key _searchPage = Key("searchPage");
  var _onPageChange = PublishSubject<PageNavigationType>();

  @override
  void initState() {
    super.initState();
    booruBloc = BooruBloc(BooruAPI(), panelWidth);
    Observable.timer(() {}, Duration(milliseconds: 50)).listen((x) {
      print("Timer up");
      booruBloc.onUpdate
          .add(UpdateArg(fetchType: FetchType.Posts, arg: PostsArgs(page: 1)));
    });
    _onPageChange.listen((x) {
      booruBloc.onPage.add(x);
    });
    homePageFetchTypeChanged.listen((x) {
      setState(() {
        if (_type != x) {
          _type = x;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    panelWidth = MediaQuery.of(context).size.width - 10;
    booruBloc.onPanelWidth.add(MediaQuery.of(context).size.width - 10);
    print("panelWidth build");
    var _controller = new ScrollController();
    return Scaffold(
        drawer: _appDrawer(),
        body: Builder(
          builder: (context) => CustomScrollView(
            primary: false,
            controller: _controller,
            physics: BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverFloatingBar(
                automaticallyImplyLeading: false,
                //snap: false,
                pinned: true,
                backgroundColor: Color.fromARGB(240, 255, 255, 255),
                //floating: true,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: Icon(Icons.menu),
                    ),
                    IconButton(
                      onPressed: () => {
                        Navigator.pushNamed(context, searchTaggedPostsPage,
                            arguments: {"key": _searchPage})
                      },
                      icon: Icon(Icons.search),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.person),
                        ),
                        Center(
                          child: DropdownButton(
                            underline: Container(),
                            items: [
                              DropdownMenuItem(
                                child: Text("Yande.re"),
                                value: ClientType.Yande,
                              ),
                              DropdownMenuItem(
                                child: Text("Konachan"),
                                value: ClientType.Konachan,
                              )
                            ],
                            onChanged: onDropdownChanged,
                            icon: Icon(Icons.settings),
                            value: AppSettings.currentClient,
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
              SliverPostWaterfall(
                controller: _controller,
                panelWidth: panelWidth,
              ),
              _buildPageNavigator()
            ],
          ),
        ));
  }

  void onDropdownChanged(item) {
    var opt = item as ClientType;
    switch (opt) {
      case ClientType.Yande:
        booruBloc.onRefresh.add(null);
        setState(() {
          AppSettings.currentClient = ClientType.Yande;
        });
        break;
      case ClientType.Konachan:
        booruBloc.onRefresh.add(null);
        setState(() {
          AppSettings.currentClient = ClientType.Konachan;
        });
        break;
      default:
        break;
    }
    // TODO: This need a indicator
    //updadePost(FetchType.PopularRecent);
  }

  double _drawerButtonHeight = 60;
  Key _drawer = Key("drawer");

  Drawer _appDrawer() {
    return Drawer(
      key: _drawer,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              // Title
              Container(
                  margin: EdgeInsets.fromLTRB(15, 20, 0, 20),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppSettings.currentClient == ClientType.Yande
                        ? "Yande.re"
                        : "Konachan",
                    style: TextStyle(fontSize: 30),
                  )),
              // Spliter
              _spliter("Posts"),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  _buildDrawerButton(() {
                    Navigator.pop(context);
                    booruBloc.onReset.add(null);
                    booruBloc.onUpdate.add(UpdateArg(
                        fetchType: FetchType.Posts, arg: PostsArgs(page: 1)));
                  }, "Posts", FetchType.Posts),

                  _buildDrawerButton(
                      () => Navigator.pushNamed(context, searchTaggedPostsPage,
                          arguments: {"key": _searchPage}),
                      "Search",
                      FetchType.Search),

                  // Spliter popular
                  _spliter("Popular Posts"),

                  _buildDrawerButton(() {
                    Navigator.pop(context);
                    booruBloc.onUpdate.add(UpdateArg(
                        fetchType: FetchType.PopularRecent,
                        arg: PopularRecentArgs()));
                  }, "Popular posts by recent", FetchType.PopularRecent),

                  _buildDrawerButton(() {
                    Navigator.pop(context);
                    booruBloc.onUpdate.add(UpdateArg(
                        fetchType: FetchType.PopularByWeek,
                        arg: PopularByWeekArgs(time: DateTime.now())));
                  }, "Popular posts by week", FetchType.PopularByWeek),

                  _buildDrawerButton(() {
                    Navigator.pop(context);
                    booruBloc.onUpdate.add(UpdateArg(
                        fetchType: FetchType.PopularByMonth,
                        arg: PopularByMonthArgs(time: DateTime.now())));
                  }, "Popular posts by month", FetchType.PopularByMonth),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerButton(
      Function() onPressed, String text, FetchType fetchType) {
    var func = () {
      onPressed();
      setState(() {
        _type = fetchType;
      });
    };
    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 20, 0),
      height: _drawerButtonHeight,
      child: FlatButton(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(30),
                topRight: Radius.circular(30))),
        highlightColor: Colors.lightBlue[300],
        color: fetchType == _type ? Colors.lightBlue[50] : Colors.transparent,
        hoverColor: Colors.lightBlue[100],
        splashColor: Colors.lightBlue[200],
        onPressed: func,
        child: Container(alignment: Alignment.centerLeft, child: Text(text)),
      ),
    );
  }

  Widget _buildPageNavigator() {
    return StreamBuilder<int>(
        stream: booruBloc.pageState,
        initialData: 1,
        builder: (context, snapshot) {
          if (_type == FetchType.Posts || _type == FetchType.Search) {
            return SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  height: 50,
                  margin: EdgeInsets.only(top: 10),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _quadButton(
                          function: () =>
                              {_onPageChange.add(PageNavigationType.Previous)},
                          child: Icon(Icons.chevron_left)),
                      Container(
                          margin: EdgeInsets.fromLTRB(15, 0, 10, 0),
                          child: Text(snapshot.data.toString())),
                      _quadButton(
                          function: () =>
                              {_onPageChange.add(PageNavigationType.Next)},
                          child: Icon(Icons.chevron_right)),
                    ],
                  ),
                ),
              ]),
            );
          } else {
            return SliverList(delegate: SliverChildListDelegate([]));
          }
        });
  }

  AspectRatio _quadButton(
      {@required Function() function, @required Widget child}) {
    return AspectRatio(
      aspectRatio: 1,
      child: FlatButton(
        onPressed: function,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: child,
      ),
    );
  }

  Container _spliter(String text) {
    return Container(
      margin: EdgeInsets.fromLTRB(15, 5, 20, 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          Text(
            text,
            style: TextStyle(fontSize: 20),
          ),
          Flexible(
            fit: FlexFit.tight,
            child: Container(
              height: 0.5,
              margin: EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => false;
}
