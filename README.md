HapticKey
=========

HapticKey is a simple utility application for MacBook with Touch Bar that triggers a haptic feedback when tapping Touch Bar.

Since Touch Bar is just a flat panel, there are no feedback other than visual change of the key displayed, it is terribly uncomfortable especially when tapping ESC key, like while using Vim.

By adding a haptic feedback, which is vibrating a track pad not Touch Bar itself, it helps to improve the usage of Touch Bar. It is also optionally playing a sound effect or flashing the screen like a visual bell on terminal.

Usage
-----

Download the latest pre-build application binary from [Releases](https://github.com/niw/HapticKey/releases) page. Note that these pre-build application binaries are not signed so you need to allow to execute it on Security & Privacy settings pane in System Preferences.

Also, the application may ask a permission to use Accessibility, as like the other applications that are listening system events.

Development
-----------

To build the application from the source code, you need to use the latest Xcode 9.

This application is using `CGEventTap` to listen key down and up or tap events on Touch Bar.

It triggers haptic feedbacks by using private APIs in `MultitouchSupport.framework` when the event meets the conditions.

Currently, the application is listening either ESC and F1, F2, etc. keys or tap events on Touch Bar.
You can implement your own `HTKEventListener` to extend the application to trigger feedbacks on arbitrary events.
