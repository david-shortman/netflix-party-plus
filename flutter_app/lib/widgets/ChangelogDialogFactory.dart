import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutterapp/changelog/ChangelogService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangelogDialogFactory {
  static Widget getChangelogDialog(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(
        "New features in v${ChangelogService.getLatestVersion()}",
        style: TextStyle(fontSize: 35),
      ),
      content: Column(
        children: <Widget>[
          Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: MarkdownBody(
                    data: ChangelogService.getCurrentChangelog(),
                    styleSheet: MarkdownStyleSheet(p: TextStyle(fontSize: 18)),
                  )))
        ],
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: CupertinoButton(
            color: CupertinoColors.activeBlue,
            child: Text("Great!"),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString(
                  "lastViewedChangelog", ChangelogService.getLatestVersion());
              Navigator.pop(context);
            },
          ),
        )
      ],
    );
  }
}
