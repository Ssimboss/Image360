[![Version](https://img.shields.io/github/tag/Ssimboss/Image360.svg?label=release)](https://github.com/Ssimboss/Image360/tree/1.1.3)
[![CocoaPods Compatible](https://img.shields.io/badge/CocoaPods-compatible-4BC51D.svg)](https://cocoapods.org/pods/Image360)
[![CocoaPods license](https://img.shields.io/cocoapods/l/Image360.svg)](https://github.com/Ssimboss/Image360/blob/master/LICENSE)
![Travis CI](https://api.travis-ci.org/Ssimboss/Image360.svg?branch=master)


# What is this?

Image360 is a simple stack of Image360Controller + Image360View which allows you to display 360° panoramic images.
 
![alt tag](https://raw.githubusercontent.com/Ssimboss/Image360/master/example.gif)

## How to use it?
- Create an instance of `Image360Controller` in your code.
- Set 360° image as `image: UIImage` of just created instance.
- Use `inertia: Float` of instance to setup inertia of gestures.
- You can switch off special orientation subview(compass view) with `isOrientationViewHidden: Bool` flag.
- `Image360View` is controled by `Image360Controller` with gestures and device motions by default. You can switch off this features via `isDeviceMotionControlEnabled: Bool` and `isGestureControlEnabled: Bool` flags.

 
### Example
 
```swift
 class ViewController: UIViewController {
 
 ...
 // Image360Controller is inserted to view with container view and bind with "image360" segue
 override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   if let identifier = segue.identifier {
   switch identifier {
     case "image360":
       if let destination = segue.destination as? Image360Controller {
         destination.image = UIImage(named: "MyPanoramicImage")
       }
     default:
       ()
     }
   }
 
 }
```

For more details look at "iOS Example" in this repository.

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate Image360 into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target '<Your Target Name>' do
pod 'Image360', '~> 1.1.3'
end
```

Then, run the following command:

```bash
$ pod install
```
