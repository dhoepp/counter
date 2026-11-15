# Counter

Mechanical-style 4-wheel tally counter for iPhone (SwiftUI, iOS 17+).
Big + button, small - button, and the hardware volume buttons also count.

## Build (needs a Mac with Xcode 15+)
```
brew install xcodegen
xcodegen generate     # creates Counter.xcodeproj from project.yml
open Counter.xcodeproj
```
Set your Team under Signing & Capabilities, then run on a **real device**
(the volume buttons and volume observation don't work in the Simulator).

## Notes
- Counts 0-9999, clamped (no wrap). Value persists across launches.
- Volume buttons: original volume is restored when the app goes to background.
  They don't work on the lock screen or while another app is in front.
