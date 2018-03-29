# NOCReachability

[![Build Status](https://img.shields.io/travis/a-snail/NOCReachability.svg)](https://travis-ci.org/a-snail/NOCReachability)
[![Version](https://img.shields.io/cocoapods/v/NOCReachability.svg)](http://cocoadocs.org/docsets/NOCReachability)
[![Platform](https://img.shields.io/cocoapods/p/NOCReachability.svg)](http://cocoadocs.org/docsets/NOCReachability)
[![License](https://img.shields.io/cocoapods/l/NOCReachability.svg)](http://cocoadocs.org/docsets/NOCReachability)
[![Twitter](https://img.shields.io/badge/twitter-@snail_bok-blue.svg?style=flat)](http://twitter.com/snail_bok)

NOCReachability is a library that provides functions for checking the status of network connections.


## Installation

You can install it using [CocoaPods](https://cocoapods.org/), the project dependency management tool using Objective-C and Swift.

### Installation with CocoaPods
To inject a NOCReachability dependency into your Xcode project using CocoaPods, add NOCReachability in the Podfile.

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'

target 'YourProjectName' do
  pod 'NOCReachability', '~> 1.0'
end
```

If you are already using a Podfile, you only need to add the NOCReachability dependency.

```ruby
pod 'NOCReachability', '~> 1.0'
```

If the NOCReachability dependency is added to the Podfile, execute the following command.
```bash
$ pod install
```


## Usage

NOCReachability is a singleton pattern, and you can use singleton objects with the `NOCReachability.sharedInstance` property.

### Network connection status
| Connection status | NOCReachabilityStatus | Explanation |
| ----: | :---- | :---- |
| -1 | NOCReachabilityStatusUnknown | The status of the network connection is unknown. |
| 0 | NOCReachabilityStatusNotReachable | The network is not connected. |
| 1 | NOCReachabilityStatusReachableViaWWAN | The status of the network connection using the mobile network(Cellular). |
| 2 | NOCReachabilityStatusReachableViaWiFi | The status of the network connection using the WiFi. |

### Check current network connection status
You can simply check the code below.

```objective-c
NOCReachabilityStatus status = NOCReachability.sharedInstance.status;
```

If you use the `[NOCReachability.sharedInstance statusToString]` method, you can check the network status as a string rather than a constant.

```objective-c
NSString *status = [NOCReachability.sharedInstance statusToString];
```

### Network connection state change detection
If the network status of the device changes, you can set the code block to be executed and perform the desired operation if the network is changed.

```objective-c
NOCReachability *reachability = NOCReachability.sharedInstance;
[reachability setStatusChangeBlock:^(NOCReachabilityStatus status) {
    // A code block that to be executed when the network state changes.
}];
[reachability startMonitoring];
```

If you want to stop detecting network state changes started with the above code, you can stop it with the following code.
```objective-c
[NOCReachability.sharedInstance stopMonitoring];
```

### Monitoring network changes using the NotificationCenter
If you started monitoring network changes using the `[NOCReachability.sharedInstance startMonitoring]` method, you can also perform the desired action if the network changes by using a notification reception instead of a code block.

If the network changes, the name of the notification delivered is `NOCReachabilityDidChangeNotification`.

If the device's network changes and a `NOCReachabilityDidChangeNotification` notification is sent, the changed network state is passed to the` userInfo` object of the notification object with the value of `NOCReachabilityNotificationStatus`.


## License

NOCReachability is released under the MIT license.
See [LICENSE](LICENSE) for details.
