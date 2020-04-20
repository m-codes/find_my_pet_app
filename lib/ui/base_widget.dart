import 'package:flutter/material.dart';
import '../UI/sizing.dart';
import '../utils/ui_utils.dart';

//Built to wrap around project widgets to get sizing information
class BaseWidget extends StatelessWidget {
  final Widget Function(
      BuildContext context, SizingInformation sizingInformation) builder;

  const BaseWidget({Key key, this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    //Returns sizing, orientation, device, screen, and widget information
    return LayoutBuilder(builder: (context, boxConstraints) {
      var sizingInformation = SizingInformation(
          orientation: mediaQuery.orientation,
          deviceScreenType: getDeviceType(mediaQuery),
          screenSize: mediaQuery.size,
          localWidgetSize:
              Size(boxConstraints.maxWidth, boxConstraints.maxHeight));
      return builder(context, sizingInformation);
    });
  }
}
