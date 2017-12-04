HapticKey
=========

HapticKey is a simple utility application for MacBook with Touch Bar that triggers a haptic feedback when tapping keys on Touch Bar.

Since Touch Bar is just a flat panel, there are no feedback other than visual change of the key displayed, it is terribly uncomfortable especially when tapping ESC key, like while using vim.
By adding a haptic feedback, which is vibrating track pad not Touch Bar itself, it helps to improve the usage of Touch Bar keys.

Usage
-----

The application is only tested on MacBook Pro (2017) and it may not work on the other environments.

To build the application, you need to use Xcode 9.

The application requires a permission to use Accessibility, as like the other applications that are listening system events.
To run application as a standalone, allow `HapticKey.app` in the Privacy panel of System Preferences.app under the Security & Privacy section.
To run application in Xcode, allow `Xcode.app` instead.

Overview
--------

This applicatin is using `CGEventTap` to listen key down and up events.

Then, it triggers haptic feedbacks by using private APIs in `MultitouchSupport.framework` when the event meets the conditions (It is sent from Touch Bar, The keycode is ESC or F1~F12, It is not repeating)

You can add extra keycodes or modify the conditions to trigger haptic feedbacks as you like.
