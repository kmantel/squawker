// import 'package:flutter/material.dart';

/// The default PageView scroll physics are very sensitive, and easily swipe pages when you mean to scroll up and down
/// instead. This dampens the physics, by making the widget "heavy" (mass), so it's harder to swipe.
// class ClampingScrollPhysics extends ScrollPhysics {
//   const ClampingScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);
//
//   @override
//   ClampingScrollPhysics applyTo(ScrollPhysics? ancestor) {
//     return ClampingScrollPhysics(parent: buildParent(ancestor));
//   }
//
//   @override
//   SpringDescription get spring => const SpringDescription(
//     mass: 50,
//     stiffness: 100,
//     damping: 1,
//   );
// }