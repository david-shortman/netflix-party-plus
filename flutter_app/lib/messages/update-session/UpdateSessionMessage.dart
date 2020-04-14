import 'package:flutterapp/messages/update-session/UpdateSessionContent.dart';

import '../Message.dart';

class UpdateSessionMessage extends SocketMessage {
  String type = 'udpateSession';

  UpdateSessionMessage(UpdateSessionContent content) {
    super.content = content;
  }
}