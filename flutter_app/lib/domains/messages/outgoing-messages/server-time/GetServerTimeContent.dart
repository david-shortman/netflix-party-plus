import 'package:np_plus/domains/messages/MessageContent.dart';

class GetServerTimeContent implements MessageContent {
  String _version;

  GetServerTimeContent(String version) {
    this._version = version;
  }

  @override
  Map<String, dynamic> toMap() => {'version': _version};
}
