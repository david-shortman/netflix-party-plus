import 'package:flutterapp/messages/update-session/UpdateSessionContent.dart';

import '../Message.dart';

class UpdateSessionMessage extends SocketMessage {
  String type = 'updateSession';

  UpdateSessionMessage(UpdateSessionContent content) {
    super.content = content;
  }
}