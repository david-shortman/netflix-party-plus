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
  String _iconName = "";
  List<Widget> images = new List<Widget>();
  List<Widget> imageWidgets = new List();


  _UserSettingsScreenState() {
    _setUsernameTextFieldFromSharedPreferences();
    images.add(SvgPicture.asset("assets/avatars/Alien.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/Batman.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/ChickenLeg.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/Chocobar.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/Cinderella.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/Cookie.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/CptAmerica.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/DeadPool.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/Goofy.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/Hamburger.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/hotdog.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/IceCream.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/IronMan.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/Mulan.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/Pizza.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/Poohbear.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/Popcorn.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/Sailor Cat.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/Sailormoon.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/Snow-White.svg", height: 85));
    images.add(SvgPicture.asset("assets/avatars/Wolverine.svg", height: 85));
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
      _iconName = prefs.getString("userIcon") ?? "";
    });
  }

   _getImageWidgets() {
     List<Widget> returnWidgets = new List<Widget>();
     images.forEach((inputImage) {
       SvgPicture image = inputImage;
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
       returnWidgets.add(widget);
     });
     return returnWidgets;
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
        child: Column( children: [new TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(labelText: 'Enter Username', suffixIcon: IconButton(icon: Icon(Icons.cancel), onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback( (_) => _usernameController.clear());
          },)),
        ), Expanded( child: GridView.count(crossAxisCount: 4,
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 8.0,
            children: _getImageWidgets())
        )])));

  }



}