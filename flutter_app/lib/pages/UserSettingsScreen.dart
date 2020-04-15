import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettingsScreen extends StatefulWidget {
  @override
  _UserSettingsScreenState createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  TextEditingController _usernameController = TextEditingController();
  String _username = "";
  String _iconName = "";
  List<Widget> images = new List<Widget>();


  _UserSettingsScreenState() {
    _setUsernameTextFieldFromSharedPreferences();
    images.add(SvgPicture.asset('assets/images/Alien.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/Batman.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/ChickenLeg.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/Chocobar.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/Cinderella.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/Cookie.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/CptAmerica.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/DeadPool.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/Goofy.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/Hamburger.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/hotdog.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/IceCream.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/IronMan.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/Mulan.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/Pizza.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/Poohbear.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/Popcorn.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/SailorCat.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/Sailormoon.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/Snow-White.svg', height: 85));
    images.add(SvgPicture.asset('assets/images/Wolverine.svg', height: 85));
  }

  _usernameChanged() {
    _updateUsernameInPreferences();
    //
  }
  _updateUsernameInPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("username", _usernameController.text);
  }

  _updateIconInPreferences(String iconName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("userIcon", iconName);
    setState(() {
      this._iconName = iconName;
    });

  }

  _setUsernameTextFieldFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _usernameController.text = prefs.getString("username");
      _username = prefs.getString("username");
      _iconName = prefs.getString("userIcon") ?? "";
    });
  }

  List<Widget>_getWidgets() {
    List<Widget> widgets = new List<Widget>();
    widgets.add(new TextFormField(
      controller: _usernameController,
      decoration: InputDecoration(labelText: 'Enter Username'),
    ));
    Row row = Row(children: new List<Widget>());
    for(int i=0; i<images.length; i++) {
      SvgPicture image = images.elementAt(i);
      String imageName = (image.pictureProvider as ExactAssetPicture).assetName.substring(14);
      Widget widget = GestureDetector(onTap: () {_updateIconInPreferences(imageName);},child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: image));
      if(imageName == _iconName) {
        widget = Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(69, 182, 254, 1),
            ),
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: image)
        );
      }

      row.children.add(widget);
      if ((i+1)%4 == 0) {
        widgets.add(row);
        row = new Row(children: new List<Widget>());
      }
    }
    widgets.add(row);

    return widgets;
  }

  @override
  Widget build (BuildContext ctxt) {
    _usernameController.addListener(_usernameChanged);
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("User Settings"),
      ),
      body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(children: _getWidgets())
      ),
    );
  }



}