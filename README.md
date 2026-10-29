# EasyIFly

[![CI Status](https://img.shields.io/travis/duanbhu/EasyIFly.svg?style=flat)](https://travis-ci.org/duanbhu/EasyIFly)
[![Version](https://img.shields.io/cocoapods/v/EasyIFly.svg?style=flat)](https://cocoapods.org/pods/EasyIFly)
[![License](https://img.shields.io/cocoapods/l/EasyIFly.svg?style=flat)](https://cocoapods.org/pods/EasyIFly)
[![Platform](https://img.shields.io/cocoapods/p/EasyIFly.svg?style=flat)](https://cocoapods.org/pods/EasyIFly)

Current release: **1.1.0**. See [CHANGELOG.md](CHANGELOG.md) for changes.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

### CocoaPods

EasyIFly is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'EasyIFly'
```

### Swift Package Manager

EasyIFly also supports [Swift Package Manager](https://swift.org/package-manager/). To install it using SPM:

1. In Xcode, open your project and navigate to **File > Swift Packages > Add Package Dependency...**
2. Enter the repository URL: `https://github.com/duanbhu/EasyIFly.git`
3. Select the version you want to use
4. Click **Add Package** to add EasyIFly to your project

## UI themes

The speech sheet matches EasyIFlyAndroid: a 48 pt title, 92 pt microphone area,
55 pt end button, 15 pt corners, and a five-frame waveform (350 ms per frame).
The default theme is blue; all presentation methods accept a theme:

```swift
EasyIFly.showPhoneInput(theme: .red) { phone in
    print(phone)
}
```

Customize each part independently, including while the sheet is visible:

```swift
var theme = SpeechRecognitionTheme.red
theme.titleBackgroundColor = .white
let sheet = EasyIFly.showVirtualNumberInput(theme: theme) { number in
    print(number)
}
sheet?.theme = .blue
```

The example app includes blue/red theme selection and phone, virtual number,
and text input modes. Existing calls continue to use the blue theme.

## Author

duanbhu, 310701836@qq.com

## License

EasyIFly is available under the MIT license. See the LICENSE file for more info.

## Simulator preview

On iOS Simulator, `SpeechRecognizer` uses a Swift preview implementation: no
microphone, network requests, or iFlytek SDK import. Device builds keep the real
SDK. Simulator text injection follows the normal filter and callback path:

```swift
#if targetEnvironment(simulator)
sheet?.simulateResult("138001380001234")
#endif
```

With CocoaPods, the example's `post_integrate` hook also skips the vendor
XCFramework copy phase and removes only `iflyMSC` from simulator linker flags.
Run `pod install` in `Example`, then run `EasyIFly-Example` on an arm64 simulator.
Hosts using this library must also call the helper in their Podfile:

```ruby
# Copy scripts/cocoapods_simulator.rb into your project's scripts directory.
require_relative 'scripts/cocoapods_simulator'
post_integrate do |installer|
  easyifly_enable_simulator(installer)
end
```

SPM manifests cannot infer the simulator destination. For SPM preview builds,
set `EASYIFLY_SIMULATOR=1` **before package resolution and building** (for example,
`EASYIFLY_SIMULATOR=1 xcodebuild ...`). That manifest mode removes the binary
SDK target and dependency entirely. Unset the variable and resolve packages
again before device builds. Xcode's GUI requires launching Xcode with that
environment; a scheme's runtime environment does not affect package resolution.

The sample accepts simulator launch arguments for repeatable UI acceptance:

- `-speech-theme blue` or `red`
- `-speech-mode phone`, `virtual`, or `text`
- `-show-dialog YES` to show the sheet at launch
- `-auto-start NO` to inspect the sheet without starting a session
- `-simulated-text 138001380001234` to inject a result after two seconds

These arguments and injection APIs are compiled only for the simulator. They
never enable simulated recognition in a device build.
