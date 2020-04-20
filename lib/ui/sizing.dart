import 'package:flutter/material.dart';
import './screen_type.dart';

//For sizing types
class SizingInformation {
  final Orientation orientation;
  final DeviceScreenType deviceScreenType;
  final Size screenSize;
  final Size localWidgetSize;

  SizingInformation({
    this.orientation,
    this.deviceScreenType,
    this.screenSize,
    this.localWidgetSize,
  });

  //Overriding toString method to show sizing information during production
  @override
  String toString() {
    return 'ScreenSize: $screenSize, widgetSize $localWidgetSize, orientation: $orientation, deviceScreenType $deviceScreenType';
  }
}
