import 'package:flutter/material.dart';
import 'package:yande_web/pages/post_view_page.dart';
import 'pages/home_page.dart';
import 'pages/search_tagged_posts_page.dart';
import 'themes/theme_light.dart';

void main() => runApp(MyApp());

// Routes
const String homePage = '/';
const String searchTaggedPostsPage = '/searchTaggedPostsPage';
const String postViewPage = '/postViewPage';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        onGenerateRoute: _routes(), title: 'Home', theme: lightTheme);
  }

  RouteFactory _routes() {
    return (settings) {
      final Map<String, dynamic> arg = settings.arguments;
      Widget screen;
      switch (settings.name) {
        case homePage:
          screen = HomePage();
          break;
        case searchTaggedPostsPage:
          screen = SearchTaggedPostsPage(key: arg["key"]);
          break;
        case postViewPage:
          screen = PostViewPage(post: arg["post"]);
          break;
        default:
          return null;
      }
      // var route = PageRouteBuilder(
      //   pageBuilder: (context, animation, secondaryAnimation) => screen,
      //   transitionsBuilder: (context, animation, secondaryAnimation, child) {
      //     var begin = Offset(0.0, 1.0);
      //     var end = Offset.zero;
      //     var curve = Curves.ease;

      //     var tween =
      //         Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      //     return SlideTransition(
      //       position: animation.drive(tween),
      //       child: child,
      //     );
      //   },
      // );
      //return route;
      return MaterialPageRoute(builder: (BuildContext contex) => screen);
    };
  }
}
