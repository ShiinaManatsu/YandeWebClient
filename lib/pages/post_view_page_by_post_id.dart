import 'dart:io' show Platform;
import 'dart:math';
import 'package:auto_route/auto_route.dart';
import "package:booru_app/main.dart";
import 'package:booru_app/models/rx/update_args.dart';
import 'package:booru_app/pages/post_view_page.dart';
import 'package:booru_app/pages/setting_page.dart';
import "package:booru_app/pages/widgets/per_platform_method.dart";
import 'package:cached_network_image/cached_network_image.dart';
import "package:esys_flutter_share/esys_flutter_share.dart";
import "package:flutter/foundation.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import "package:photo_view/photo_view.dart";
import "package:photo_view/photo_view_gallery.dart";
import "package:sliding_up_panel/sliding_up_panel.dart";
import "package:url_launcher/url_launcher.dart";
import "package:booru_app/models/rx/booru_api.dart";
import "package:booru_app/models/yande/comment.dart";
import "package:booru_app/models/yande/post.dart";
import "package:booru_app/models/yande/tags.dart";
import "package:booru_app/pages/home_page.dart";
import "package:booru_app/settings/app_settings.dart";
import "package:expandable/expandable.dart";
import "package:booru_app/models/rx/task_bloc.dart";
import "package:http/http.dart" as http;

class PostViewPageByPostID extends StatefulWidget {
  final String postID;

  PostViewPageByPostID({@required this.postID});

  @override
  _PostViewPageByPostIDState createState() => _PostViewPageByPostIDState();
}

class _PostViewPageByPostIDState extends State<PostViewPageByPostID>
    with TickerProviderStateMixin {
  List<Comment> _comments = List<Comment>();
  int buttonCount = 3;
  double barHeight = 64;
  double panelHandlerWidth = 192; // Hover area
  double commentsPanelWidth = 300;
  PhotoViewController _galleryController = PhotoViewController();

  bool _showPanel = true;

  /// Gallery page index
  Post _post;

  // Top-Right panel usage

  double _panelStartOffset;
  double _panelOffset;
  double _panelContentOffset;
  double _offset;
  bool _isPanelOpen = false;
  bool _isContentPanelOpen = false;

  // Top-Right panel usage

  // Post Tags
  List<TagWrapper> _tags = List<TagWrapper>();

  List<Tag> _selectedTags = List<Tag>();

  @override
  void initState() {
    super.initState();
    // Hover panel usage
    _panelStartOffset = -(barHeight * 3 + commentsPanelWidth);
    _panelOffset = _panelStartOffset + barHeight * 3;
    _panelContentOffset = _panelOffset + commentsPanelWidth;
    _offset = _panelStartOffset;

    BooruAPI.fetchSpecficPost(id: widget.postID).then((value) {
      if (mounted) {
        setState(() {
          _post = value.first;
          // Statistics.append(StatisticsItem(
          //     postEntry: EnumToString.parse(PostEntry.Link), post: _post));

          _post.tags.split(" ").forEach((x) async {
            var res = await TagDataBase.searchTags(x);
            var t = res.firstWhere((f) => f.content == x);
            if (mounted) {
              setState(() {
                _tags.add(TagWrapper(t));
              });
            }
          });

          BooruAPI.fetchPostsComments(postID: _post.id).then((x) {
            if (x != null) {
              if (mounted) {
                setState(() {
                  _comments = x;
                });
              }
            }
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).primaryColorBrightness));
    return Scaffold(
      body: MediaQuery.of(context).size.aspectRatio >= 3 / 4
          ? Stack(children: <Widget>[
              _buildGallery(),
              _buildTopRightPanel(MediaQuery.of(context).size.height),
            ])
          : TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 200),
              curve: Curves.ease,
              tween: Tween<double>(
                  begin: _showPanel ? 60 : 0, end: _showPanel ? 60 : 0),
              builder: (context, value, child) => SlidingUpPanel(
                backdropColor: Colors.black,
                backdropOpacity: 0.5,
                color: Theme.of(context).backgroundColor.withOpacity(0.8),
                minHeight: value,
                maxHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
                parallaxEnabled: true,
                backdropEnabled: true,
                // When coollapsed
                panelBuilder: (sc) => _buildContentPanel(sc),
                body: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showPanel = !_showPanel;
                    });
                  },
                  child: _buildGallery(),
                ),
              ),
            ),
    );
  }

  Widget _buildTopRightPanel(double height) {
    bool isLeaving = false;
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.ease,
      right: _offset,
      child: Container(
        alignment: Alignment.centerLeft,
        height: height,
        child: Row(
          children: <Widget>[
            // Left
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Container(
                  child: MouseRegion(
                    onEnter: (x) {
                      if (!_isPanelOpen && !_isContentPanelOpen) {
                        setState(() {
                          _offset = _panelOffset;
                        });
                        _isPanelOpen = true;
                        isLeaving = false;
                      }
                    },
                    onExit: (x) {
                      if (_isPanelOpen && !_isContentPanelOpen) {
                        setState(() {
                          _offset = _panelStartOffset;
                        });
                        _isPanelOpen = false;
                      }
                    },
                    child: Row(
                      children: <Widget>[
                        // Handle hover (hover area)
                        Container(
                          height: barHeight,
                          width: panelHandlerWidth,
                        ),
                        //Basic function button group
                        Container(
                          clipBehavior: Clip.antiAlias,
                          width: buttonCount * barHeight,
                          alignment: Alignment.center,
                          height: barHeight,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(32.0)),
                              color: Colors.white70),
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(32.0))),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  _buildQuadIconButton(
                                      () => Navigator.pop(context),
                                      Icon(Icons.arrow_back)),
                                  _buildQuadIconButton(() async {
                                    if (kIsWeb) {
                                      _launchURL(_post.fileUrl);
                                      return;
                                    } else {
                                      var status =
                                          await Permission.storage.status;
                                      if (status == PermissionStatus.granted)
                                        taskBloc.addDownload.add(_post);
                                      else
                                        Permission.storage.request();
                                    }
                                  }, Icon(Icons.file_download)),
                                  _buildQuadIconButton(() {
                                    accountOperation.add(() =>
                                        BooruAPI.votePost(
                                            postID: _post.id,
                                            type: VoteType.Favorite));
                                  }, Icon(Icons.favorite_border)),
                                ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content handler
                Container(
                  height: MediaQuery.of(context).size.height - barHeight - 10,
                  child: MouseRegion(
                    onEnter: (x) {
                      if (!_isContentPanelOpen && !isLeaving) {
                        setState(() {
                          _offset = _panelContentOffset;
                        });
                        _isContentPanelOpen = true;
                      }
                    },
                    child: Container(
                      width: 100,
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(color: Colors.white70),
              child: MouseRegion(
                onExit: (x) {
                  if (_isContentPanelOpen) {
                    setState(() {
                      _offset = _panelStartOffset;
                    });
                    isLeaving = true;
                    _isContentPanelOpen = false;
                  }
                },
                child: Container(
                  width: commentsPanelWidth,
                  alignment: Alignment.topCenter,
                  child: _buildContentPanel(ScrollController()),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  AspectRatio _buildQuadIconButton(Function onPressed, Widget child) {
    return AspectRatio(
      aspectRatio: 1,
      child: FlatButton(onPressed: onPressed, child: child),
    );
  }

  Widget _buildContentPanel(ScrollController sc) {
    var buttonGroup = Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
      (kIsWeb || Platform.isWindows)
          ? _buildQuadIconButton(
              () => ExtendedNavigator.root.pop(),
              Icon(Icons.arrow_back,
                  color: Theme.of(context).textTheme.button.color))
          : Container(),
      _buildQuadIconButton(
          () => accountOperation.add(() =>
              BooruAPI.votePost(postID: _post.id, type: VoteType.Favorite)),
          Icon(Icons.favorite_border,
              color: Theme.of(context).textTheme.button.color)),
      _buildQuadIconButton(() async {
        var status = await Permission.storage.status;
        if (status == PermissionStatus.granted)
          taskBloc.addDownload.add(_post);
        else
          Permission.storage.request();
      },
          Icon(Icons.file_download,
              color: Theme.of(context).textTheme.button.color)),
      _buildQuadIconButton(
          () => _galleryController.rotation -= pi / 2,
          Icon(Icons.rotate_90_degrees_ccw,
              color: Theme.of(context).textTheme.button.color)),
      (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
          ? _buildQuadIconButton(
              () async => await Share.file("${_post.id}", "${_post.id}.png",
                  (await http.get(_post.jpegUrl)).bodyBytes, "image/png",
                  text: "${language.content.shareTo} ..."),
              Icon(Icons.share,
                  color: Theme.of(context).textTheme.button.color))
          : Container(),
      (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
          ? _buildQuadIconButton(
              () => Share.text(
                  "${_post.id}",
                  "https://yande.re/post/show/${_post.id}",
                  "text/plain;charset=UTF-8"),
              Icon(Icons.link, color: Theme.of(context).textTheme.button.color))
          : Container(),
    ]);

    var topBar = PerPlatform(
      windows: Container(
          color: Theme.of(context).backgroundColor,
          alignment: Alignment.centerLeft,
          height: barHeight,
          child: buttonGroup),
      android: Container(
          color: Theme.of(context).backgroundColor,
          alignment: Alignment.centerLeft,
          height: barHeight,
          child: Stack(
            children: <Widget>[
              StreamBuilder<List<DownloadTask>>(
                stream: taskBloc.tasks,
                builder: (context, snapshot) {
                  var task = snapshot.data == null || snapshot.data?.length == 0
                      ? null
                      : snapshot.data.where((x) => x.post == _post)?.first;
                  return task == null
                      ? Container()
                      : Container(
                          alignment: Alignment.topCenter,
                          height: 60,
                          child: TweenAnimationBuilder(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.ease,
                            tween: Tween<double>(begin: 0, end: task.progress),
                            builder: (context, double value, child) =>
                                LinearProgressIndicator(
                              value: value,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color.lerp(
                                      Colors.blueAccent,
                                      Colors.pinkAccent,
                                      task == null ? 0 : task.progress)),
                            ),
                          ),
                        );
                },
              ),
              buttonGroup,
            ],
          )),
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).backgroundColor,
        boxShadow: [
          BoxShadow(
            offset: Offset(-1, 0),
            color: Colors.black45,
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          // Top bar
          topBar,
          // Content
          Flexible(
            child: SingleChildScrollView(
              controller: sc,
              physics: BouncingScrollPhysics(),
              child: Container(
                padding: EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    //------------------
                    _buildDoubleWidgetRow(
                      Text(
                        "${language.content.id}",
                        style: TextStyle(fontSize: 20),
                      ),
                      Text(
                        "${_post.id}",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),

                    _buildDoubleWidgetRow(
                      Text(
                        "${language.content.size}",
                        style: TextStyle(fontSize: 20),
                      ),
                      Text("${_post.width}x${_post.height}"),
                    ),

                    _buildDoubleWidgetRow(
                      Text(
                        "${language.content.fileSize}",
                        style: TextStyle(fontSize: 20),
                      ),
                      Text(_post.fileSize < 1024 * 1024
                          ? (_post.fileSize / 1024).toStringAsFixed(3) + " KB"
                          : (_post.fileSize / 1024 / 1024).toStringAsFixed(3) +
                              " MB"),
                    ),

                    _buildDoubleWidgetRow(
                      Text(
                        "${language.content.author}",
                        style: TextStyle(fontSize: 20),
                      ),
                      GestureDetector(
                        child: Row(
                          children: <Widget>[
                            CircleAvatar(
                              backgroundImage: kIsWeb || Platform.isWindows
                                  ? NetworkImage(
                                      "${AppSettings.currentBaseUrl}/data/avatars/${_post.creatorId}.jpg")
                                  : CachedNetworkImageProvider(
                                      "${AppSettings.currentBaseUrl}/data/avatars/${_post.creatorId}.jpg"),
                            ),
                            Container(
                              margin: EdgeInsets.only(left: 10),
                              child: Text("${_post.author}"),
                            ),
                          ],
                        ),
                        onTap: () {
                          searchTerm = "user:${_post.author}";
                          homePageFetchTypeChanged.add(FetchType.Search);
                          booruBloc.onReset.add(null);
                          booruBloc.onUpdate.add(
                            UpdateArg(
                              fetchType: FetchType.Search,
                              arg: TaggedArgs(tags: searchTerm, page: 1),
                            ),
                          );
                          Navigator.pop(context);
                        },
                      ),
                    ),

                    _buildDoubleWidgetRow(
                      Text(
                        "${language.content.score}",
                        style: TextStyle(fontSize: 20),
                      ),
                      Text("${_post.score}"),
                    ),

                    _buildDoubleWidgetRow(
                      Text(
                        "${language.content.tags}",
                        style: TextStyle(fontSize: 20),
                      ),
                      Flexible(
                        child: Wrap(
                          spacing: 3,
                          children: List.generate(
                            _tags.length,
                            (index) => Chip(
                              label: Text(_tags[index].tag.content),
                              deleteButtonTooltipMessage:
                                  "Add or remove search",
                              backgroundColor:
                                  TagToColorMap[_tags[index].tag.tagType],
                              deleteIcon: Icon(_tags[index].selected
                                  ? Icons.remove
                                  : Icons.add),
                              onDeleted: () {
                                if (_tags[index].selected) {
                                  _selectedTags.remove(_tags[index].tag);
                                } else
                                  _selectedTags.add(_tags[index].tag);

                                setState(() {
                                  _tags[index].selected =
                                      !_tags[index].selected;
                                });
                              },
                            ),
                          )..add(_selectedTags.length != 0
                              ? GestureDetector(
                                  child: Chip(
                                    label: Icon(Icons.search,
                                        color:
                                            Theme.of(context).backgroundColor),
                                    backgroundColor:
                                        Theme.of(context).accentColor,
                                  ),
                                  onTap: () {
                                    searchTerm = _selectedTags
                                        .map((x) => x.content)
                                        .join(" ");
                                    homePageFetchTypeChanged
                                        .add(FetchType.Search);
                                    booruBloc.onReset.add(null);
                                    booruBloc.onUpdate.add(
                                      UpdateArg(
                                        fetchType: FetchType.Search,
                                        arg: TaggedArgs(
                                            tags: searchTerm, page: 1),
                                      ),
                                    );
                                    Navigator.pop(context);
                                  },
                                )
                              : Container()),
                        ),
                      ),
                      alignmentFix: true,
                    ),

                    _buildDoubleWidgetRow(
                      Text(
                        "${language.content.rating}",
                        style: TextStyle(fontSize: 20),
                      ),
                      Text("${_post.rating.toString()}"),
                    ),

                    // Source link
                    _buildDoubleWidgetRow(
                      Text(
                        "${language.content.source}",
                        style: TextStyle(fontSize: 20),
                      ),
                      Expanded(
                        child: RichText(
                          text: new TextSpan(
                            text: _post.sourceUrl == ""
                                ? "${language.content.noSource}"
                                : _post.sourceUrl,
                            style: new TextStyle(color: Colors.blue),
                            recognizer: new TapGestureRecognizer()
                              ..onTap = () {
                                var url = _post.sourceUrl;
                                if (url.startsWith("https://i.pximg.net/")) {
                                  var id = url.split('/').last;
                                  if (id.contains("_")) {
                                    id = id.split("_").first;
                                  } else {
                                    id = id.split(".").first;
                                  }
                                  url = "https://www.pixiv.net/artworks/$id";
                                }
                                launch(url);
                              },
                          ),
                        ),
                      ),
                    ),

                    _buildDoubleWidgetRow(
                        Text(
                          "${language.content.comments}",
                          style: TextStyle(fontSize: 20),
                        ),
                        // Comments
                        _buildExpandablePanel(),
                        alignmentFix: true)
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoubleWidgetRow(Widget left, Widget right,
          {bool alignmentFix = false}) =>
      Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment:
            alignmentFix ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            width: 100,
            child: left,
          ),
          right
        ],
      );

  Widget _buildExpandablePanel() {
    if (_comments.length == 0) {
      return Container();
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(
            _comments.length,
            (index) => Container(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(color: Colors.accents[index]),
                  child: ExpandableNotifier(
                    child: Column(
                      children: [
                        ExpandablePanel(
                          header: Column(
                            children: <Widget>[
                              Text(_comments[index].creator,
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              Text(_comments[index].content),
                              ExpandableButton(
                                child: Text("Expand"),
                              ),
                            ],
                          ),
                          expanded: Column(children: [
                            ExpandableButton(
                              child: Text("Back"),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                )),
      );
    }
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      return;
    }
  }

  Widget _buildGallery() {
    return Hero(
      tag: _post,
      child: PhotoViewGallery.builder(
        gaplessPlayback: true,
        enableRotation: true,
        backgroundDecoration: BoxDecoration(color: Colors.transparent),
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (context, index) => PhotoViewGalleryPageOptions(
          controller: _galleryController,
          maxScale: 1.0,
          initialScale: PhotoViewComputedScale.contained,
          filterQuality: FilterQuality.high,
          imageProvider: !kIsWeb && !Platform.isWindows
              ? CachedNetworkImageProvider(_post.jpegUrl)
              : NetworkImage(_post.jpegUrl),
        ),
        pageController: PageController(),
        itemCount: 1,
        loadingBuilder: (BuildContext context, ImageChunkEvent event) {
          String url;
          switch (AppSettings.previewQuality) {
            case PreviewQuality.Low:
              url = _post.previewUrl;
              break;
            case PreviewQuality.Medium:
              url = _post.sampleUrl;
              break;
            case PreviewQuality.High:
              url = _post.jpegUrl;
              break;
            case PreviewQuality.Original:
              url = _post.fileUrl;
              break;
            default:
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: -1, end: 1),
                  duration: Duration(milliseconds: 800),
                  builder: (BuildContext context, double value, Widget child) =>
                      Opacity(
                        opacity: value < 0 ? 0 : value,
                        child: Image(
                          gaplessPlayback: true,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          image: !kIsWeb && !Platform.isWindows
                              ? CachedNetworkImageProvider(url)
                              : NetworkImage(url),
                        ),
                      )),
              Center(
                child: Container(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(
                    value: event == null
                        ? null
                        : event.cumulativeBytesLoaded /
                            event.expectedTotalBytes,
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class PanelArg {
  PanelState panelState;
}

class OpenPanelArg extends PanelArg {
  final panelState;
  OpenPanelArg({@required this.panelState});
}

class OpenCommentPanelArg extends PanelArg {
  final panelState;
  OpenCommentPanelArg({@required this.panelState});
}

enum PanelState { Open, Close }
