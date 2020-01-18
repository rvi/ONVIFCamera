# ONVIFCamera

[![Version](https://img.shields.io/cocoapods/v/ONVIFCamera.svg?style=flat)](http://cocoapods.org/pods/ONVIFCamera)
[![License](https://img.shields.io/cocoapods/l/ONVIFCamera.svg?style=flat)](http://cocoapods.org/pods/ONVIFCamera)
[![Platform](https://img.shields.io/cocoapods/p/ONVIFCamera.svg?style=flat)](http://cocoapods.org/pods/ONVIFCamera)

This library have been developped to ease the connection of an iOS device to an ONVIF Camera.
With this library you are able to get the informations from a camera, the different media profiles available and retrieve the stream URI to play it.\
\
I wrote an article explaining how to use this code and how to create an ONVIF app, you can read it [here, on Hackernoon](https://hackernoon.com/live-stream-an-onvif-camera-on-your-ios-app-57fe9cead5a5).

![Screenshot](https://github.com/rvi/ONVIFCamera/blob/master/images/screenshot.png)
![Screenshot](https://github.com/rvi/ONVIFCamera/blob/master/images/screenShotAppleTV.png)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first, or run `pod try ONVIFCamera` in your terminal.


## Requirements

To use this project on an iOS device (real device, not a simulator) you need a `SOAPEngine` licence key. You don't need one if you want to build and run the project on your simulator.
You can buy one [here](https://www.prioregroup.com/iphone/soapengine.aspx) or parse the XML yourself like it has been done on [the Android project](https://github.com/rvi/ONVIFCameraAndroid).

## Installation

##iOS

ONVIFCamera is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ONVIFCamera'
```

##TVOS

```ruby
pod 'ONVIFCameraTVOS'
```

## Author

Rémy Virin, remy@virin.us

## License

ONVIFCamera is available under the MIT license. See the LICENSE file for more info.
