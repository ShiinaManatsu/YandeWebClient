import 'package:animated_stream_list/animated_stream_list.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:booru_app/pages/home_page.dart';
import 'package:booru_app/models/rx/task_bloc.dart';

class TaskOverlay extends StatefulWidget {
  @override
  _TaskOverlayState createState() => _TaskOverlayState();
}

class _TaskOverlayState extends State<TaskOverlay>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      Positioned(
        right: 20,
        bottom: 20,
        child: ClipRRect(
          child: StreamBuilder<List<DownloadTask>>(
            stream: taskBloc.tasks,
            builder: (context, snapshot) => Container(
              padding: snapshot.data.length != 0
                  ? EdgeInsets.all(12)
                  : EdgeInsets.zero,
              alignment: Alignment.bottomRight,
              width: 400,
              color: Colors.transparent,
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    //Text("Text"),
                    AnimatedStreamList<DownloadTask>(
                      shrinkWrap: true,
                      streamList: taskBloc.tasks,
                      duration: Duration(milliseconds: 300),
                      itemBuilder: (item, index, context, animation) =>
                          _animateInCard(item, animation),
                      itemRemovedBuilder: (item, index, context, animation) =>
                          _animateOutCard(item, animation),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  /// Animate card in
  Widget _animateInCard(DownloadTask task, Animation<double> animation) {
    var curvedAnimation = animation.drive(CurveTween(curve: Curves.ease));
    return SlideTransition(
      position: curvedAnimation.drive(Tween<Offset>(
        begin: Offset(1.0, 0.0),
        end: Offset.zero,
      )),
      child: _buildCard(task),
    );
  }

  /// Animate card out
  Widget _animateOutCard(DownloadTask task, Animation<double> animation) {
    return SizeTransition(
      axis: Axis.vertical,
      sizeFactor: animation,
      child: _buildCard(task),
    );
  }

  Widget _buildCard(DownloadTask task) {
    return Card(
      child: ListTile(
        title: TweenAnimationBuilder(
          duration: Duration(milliseconds: 300),
          curve: Curves.ease,
          tween: Tween<double>(begin: 0, end: task.progress),
          builder: (context, double value, child) => LinearProgressIndicator(
            value: task.canceled ? null : value,
            valueColor: AlwaysStoppedAnimation<Color>(Color.lerp(
                Colors.blueAccent,
                Colors.pinkAccent,
                task.progress == null ? 0 : task.progress)),
          ),
        ),
        subtitle: Text(task.post.id.toString()),
        leading: AspectRatio(
          aspectRatio: 1,
          child: Image.network(
            task.post.previewUrl,
            fit: BoxFit.cover,
          ),
        ),
        onTap: () => OpenFile.open(task.filePath),
        trailing: InkWell(
            onTap: () => taskBloc.cancelTask.add(task),
            child: Icon(Icons.cancel)),
      ),
    );
  }
}

/// Example to show how to popup overlay with custom animation.
class AnimatedOverlay extends StatelessWidget {
  final double value;

  static final Tween<Offset> tweenOffset =
      Tween<Offset>(begin: Offset(0, 40), end: Offset(0, 0));

  static final Tween<double> tweenOpacity = Tween<double>(begin: 0, end: 1);

  const AnimatedOverlay({Key key, @required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: tweenOffset.transform(value),
      child: Opacity(
        child: TaskOverlay(),
        opacity: tweenOpacity.transform(value),
      ),
    );
  }
}
