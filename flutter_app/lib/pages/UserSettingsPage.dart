import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:np_plus/GetItInstance.dart';
import 'package:np_plus/domains/user/LocalUser.dart';
import 'package:np_plus/services/LocalUserService.dart';
import '../vaults/DefaultsVault.dart';

class UserSettingsPage extends StatefulWidget {
  @override
  _UserSettingsPageState createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  final _localUserService = getIt.get<LocalUserService>();

  TextEditingController _usernameController = TextEditingController();
  String _iconName = "";
  List<Widget> _images = List<Widget>();

  List<String> avatars = [
    "Alien.svg",
    "Batman.svg",
    "ChickenLeg.svg",
    "Chocobar.svg",
    "Cinderella.svg",
    "Cookie.svg",
    "CptAmerica.svg",
    "DeadPool.svg",
    "Goofy.svg",
    "Hamburger.svg",
    "hotdog.svg",
    "IceCream.svg",
    "IronMan.svg",
    "Mulan.svg",
    "Pizza.svg",
    "Poohbear.svg",
    "Popcorn.svg",
    "SailorCat.svg",
    "Sailormoon.svg",
    "Snow-White.svg",
    "Wolverine.svg"
  ];

  _UserSettingsPageState() {
    _images = avatars
        .map((avatar) => SvgPicture.asset(
            "assets/avatars/${avatar ?? DefaultsVault.DEFAULT_AVATAR}",
            height: 85))
        .toList();
    _loadSavedLocalUserDetails();
  }

  @override
  void dispose() {
    super.dispose();
    _localUserService.updateProfile(
        username: _usernameController.text, icon: _iconName);
  }

  void onIconSelected(String icon) async {
    await HapticFeedback.lightImpact();
    setState(() {
      this._iconName = icon;
    });
  }

  void _loadSavedLocalUserDetails() async {
    LocalUser localUser = await _localUserService.getLocalUser();
    _usernameController.text = localUser.username ?? "Mobile User";
    setState(() {
      _iconName = localUser.icon ?? DefaultsVault.DEFAULT_AVATAR;
    });
  }

  @override
  Widget build(BuildContext ctxt) {
    return Scaffold(
        appBar: CupertinoNavigationBar(
          actionsForegroundColor: Theme.of(context).primaryColor,
          middle: Text("User Settings",
              style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).textTheme.body1.color)),
          backgroundColor: CupertinoColors.tertiarySystemFill,
        ),
        body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Nickname",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 20, fontFamily: "San Francisco"),
                  )),
              Padding(
                padding: EdgeInsets.all(4),
              ),
              CupertinoTextField(
                textInputAction: TextInputAction.done,
                controller: _usernameController,
                placeholder: 'Enter Username',
                style: Theme.of(context).primaryTextTheme.body1,
                clearButtonMode: OverlayVisibilityMode.editing,
                keyboardType: TextInputType.text,
              ),
              Padding(
                padding: EdgeInsets.all(10),
              ),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Avatar icon",
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 20, fontFamily: "San Francisco"),
                  )),
              Padding(
                padding: EdgeInsets.all(4),
              ),
              Expanded(
                  child: GridView.count(
                      crossAxisCount: 4,
                      crossAxisSpacing: 4.0,
                      mainAxisSpacing: 8.0,
                      children: _getAvatarIconButtons()))
            ])));
  }

  List<Widget> _getAvatarIconButtons() {
    List<Widget> returnWidgets = List<Widget>();
    _images.forEach((inputImage) {
      SvgPicture image = inputImage;
      String imageName =
          (image.pictureProvider as ExactAssetPicture).assetName.substring(14);
      Widget widget = GestureDetector(
          onTap: () => onIconSelected(imageName),
          child: Padding(padding: const EdgeInsets.all(8.0), child: image));
      if (imageName == _iconName) {
        widget = Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: Theme.of(context).primaryColor,
            ),
            child: Padding(padding: const EdgeInsets.all(8.0), child: image));
      }
      returnWidgets.add(widget);
    });
    return returnWidgets;
  }
}
