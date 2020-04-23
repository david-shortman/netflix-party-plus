import 'dart:convert';

import 'package:np_plus/domains/mappable/Mappable.dart';

class MessageArray implements Mappable {
  List<dynamic> propertyBagList;

  MessageArray(String messageArrayString) {
    String maessageArrayJson = '{ \"messageArray\": $messageArrayString }';
    dynamic messageArrayObject = json.decode(maessageArrayJson);
    propertyBagList = messageArrayObject['messageArray'];
  }

  @override
  Map<String, dynamic> toMap() {
    return {'messageArray': propertyBagList};
  }
}
