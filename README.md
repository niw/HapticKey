HapticKey
=========

HapticKey is a simple utility application for MacBook with Touch Bar that triggers a haptic feedback when tapping keys on Touch Bar.

Since Touch Bar is just a flat panel, there are no feedback other than visual change of the key displayed, it is terribly uncomfortable especially when tapping ESC key, like while using vim.
By adding a haptic feedback, which is vibrating track pad not Touch Bar itself, it helps to improve the usage of Touch Bar keys.

Usage
-----

Download a prebuild application binary from [Releases](https://github.com/niw/HapticKey/releases) page.

The application requires a permission to use Accessibility, as like the other applications that are listening system events.
To run application as a standalone, allow `HapticKey.app` in the Privacy panel of System Preferences.app under the Security & Privacy section.
To run application in Xcode, allow `Xcode.app` instead.

Overview
--------

To build the application, you need to use Xcode 9.

This application is using `CGEventTap` to listen key down and up events.

Then, it triggers haptic feedbacks by using private APIs in `MultitouchSupport.framework` when the event meets the conditions.

Currently, the application is listening either ESC and F1, F2, etc. keys or tap gestures on Touch Bar.
You can implement your own `HTKEventListener` to extend the application to trigger haptic feedbacks on arbitrary events.
