import 'package:flutter_combainsdk/messages.g.dart';

class CapturePayload {
  Signals? signals;

  CapturePayload({this.signals});

  static CapturePayload fromCombainLocation(FlutterCombainLocation location) {
    return CapturePayload(
      signals: Signals(
        location: Location(lat: location.latitude, lng: location.longitude),
        indoor: location.indoor != null
            ? Indoor(
                building: null,
                buildingId: location.indoor!.buildingId,
                floorIndex: location.indoor!.floorIndex,
                floorLabel: null,
                buildingModelId: location.indoor!.buildingModelId,
              )
            : null,
      ),
    );
  }

  CapturePayload.fromJson(Map<String, dynamic> json) {
    signals = json['signals'] != null
        ? new Signals.fromJson(json['signals'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.signals != null) {
      data['signals'] = this.signals!.toJson();
    }
    return data;
  }
}

class Signals {
  Location location;
  Indoor? indoor;

  Signals({required this.location, this.indoor});

  Signals.fromJson(Map<String, dynamic> json)
    : location = new Location.fromJson(json['Location']),
      indoor = json['Indoor'] != null
          ? new Indoor.fromJson(json['Indoor'])
          : null;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Location'] = this.location!.toJson();
    if (this.indoor != null) {
      data['Indoor'] = this.indoor!.toJson();
    }
    return data;
  }
}

class Location {
  double lat;
  double lng;

  Location({required this.lat, required this.lng});

  Location.fromJson(Map<String, dynamic> json)
    : lat = (json['lat'] as num).toDouble(),
      lng = (json['lng'] as num).toDouble();

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    return data;
  }
}

class Indoor {
  String? room;
  String? building;
  int? buildingId;
  int? floorIndex;
  String? floorLabel;
  int? buildingModelId;

  Indoor({
    this.room,
    this.building,
    this.buildingId,
    this.floorIndex,
    this.floorLabel,
    this.buildingModelId,
  });

  Indoor.fromJson(Map<String, dynamic> json) {
    room = json['room'];
    building = json['building'];
    buildingId = json['buildingId'];
    floorIndex = json['floorIndex'];
    floorLabel = json['floorLabel'];
    buildingModelId = json['buildingModelId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['room'] = this.room;
    data['building'] = this.building;
    data['buildingId'] = this.buildingId;
    data['floorIndex'] = this.floorIndex;
    data['floorLabel'] = this.floorLabel;
    data['buildingModelId'] = this.buildingModelId;
    return data;
  }
}
