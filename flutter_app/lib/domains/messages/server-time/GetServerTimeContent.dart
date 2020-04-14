import 'package:flutterapp/domains/messages/MessageContent.dart';

class GetServerTimeContent extends MessageContent {
  String _version;

  GetServerTimeContent(String version) {
    this._version = version;
  }

  Map<String, dynamic> toMap() =>
      {
        'version': _version
      };
}
