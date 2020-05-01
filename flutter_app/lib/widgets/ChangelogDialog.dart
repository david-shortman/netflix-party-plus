import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:np_plus/changelog/ChangelogService.dart';
import 'package:np_plus/vaults/PreferencePropertyVault.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangelogDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
                    styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context)
                                .primaryTextTheme
                                .bodyText1
                                .color)),
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
                  PreferencePropertyVault.LAST_VIEWED_CHANGELOG_VERSION,
                  ChangelogService.getLatestVersion());
              Navigator.pop(context);
            },
          ),
        )
      ],
    );
  }
}
