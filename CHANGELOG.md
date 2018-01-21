# Change Log

### version 1.0.0
- Simple `init()` constructor for `Image360Controller` implemented.
- README, Log, Swift version fixes.

### version 0.2.4
- XCode 9.2 updates
- Swift updated to 4.0

### version 0.2.3
 - XCode 8.3 updates & deprecations.
 - Your custom gesture & motion controllers could be integrated to work with `Image360`. Now `Image360Controller` has settable `gestureController` & `motionController`. Both are instances of a very abstract protocol `Image360.Controller`.

### version 0.2.2
 - Support of multiple Image360Controllers one one screen implemented.

### version 0.2.1
 - Interface orientation changes handled.

### version 0.2.0
 - FPS improved
 - Typos fixed

### version 0.1.6
 - `Inertia` enum deprecated. `Image360Controller.inertia` now is a `Float` value.
 - `Image360Contoller` now have flag `isGestureControlEnabled` to enable/disable gesture control.
 - Device motion control for `Image360Contoller` implemented. This feature could be enabled/disabled via new `isDeviceMotionControlEnabled` flag.

### version 0.1.5
 - `Image360View` now has special orientation subview. It's controlled via `isOrientationViewHidden` property.

### version 0.1.4
 - Scale problems of `Image360View` solved.

### version 0.1.3
 - `Image360ViewObserver` protocol implemented.
 - Manual scale control of `Image360View` implemented.

### version 0.1.2
 - `Image360View` become public. Manual rotation control of `Image360View` implemented.

### version 0.1.1
 - **CocoaPods** integration.

### version 0.1.0
 - Initial version.
