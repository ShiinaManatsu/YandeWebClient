import 'package:flutter/material.dart';
import 'package:yande_web/controllors/search_box.dart';
import 'package:yande_web/pages/post_waterfall_widget.dart';
import 'package:yande_web/settings/app_settings.dart';
import 'package:yande_web/themes/theme_light.dart';

import '../main.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  double panelWidth = 1000;
  double leftPanelWidth = 86;
  Key _homeWaterfall=Key("_homeWaterfall");
  Key _homePageBar=Key("homePageBar");


  var type = ClientType.Yande;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    panelWidth = MediaQuery.of(context).size.width;
    return Scaffold(
        drawer: appDrawer(),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(64),
          child: AppBar(
            title: SearchBox(key: _homePageBar,),
            iconTheme: IconThemeData(color: baseBlackColor),
            centerTitle: true,
            actions: <Widget>[
              Container(
                width: 64,
                child: FlatButton(
                  onPressed: () {Navigator.pushNamed(context, searchTaggedPostsPage);},
                  child: Icon(Icons.person),
                  //padding: EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(32.0)),
                ),
              ),
              Center(
                child: DropdownButton(
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
                  value: type,
                ),
              ),
            ],
          ),
        ),
        body: _buildRow(context));
  }

  void onDropdownChanged(item) {
    var opt = item as ClientType;
    switch (opt) {
      case ClientType.Yande:
        AppSettings.currentClient = ClientType.Yande;
        setState(() {
          type = ClientType.Yande;
        });
        break;
      case ClientType.Konachan:
        AppSettings.currentClient = ClientType.Konachan;
        setState(() {
          type = ClientType.Konachan;
        });
        break;
      default:
        break;
    }
  }

  Widget _buildRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Left panel
        //container,
        Expanded(
          child: PostWaterfall(
            panelWidth: panelWidth,
            key: _homeWaterfall,
          ),
        )
      ],
    );
  }

 

  @override
  void initState() {
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;
}
