# SlapMe

Slap your MacBook and it yelps back.

SlapMe lives in the menu bar and listens to the MacBook's built-in motion sensor. A slap on the chassis makes your Mac complain out loud (or plays a sound from a folder you choose), buzzes the trackpad, and pops a burst around the pointer.

## Private by construction

- **No network.** SlapMe contains no networking code and links no networking frameworks. It never checks for updates.
- **No permissions.** No Screen Recording, no Accessibility, no Input Monitoring.
- **No logs, no telemetry.** The only things it stores are its own preferences and slap counts, in `~/Library/Preferences/app.slapme.SlapMe.plist`.

## Requirements

- An Apple Silicon MacBook with the motion sensor (verified on a MacBook Pro with M1 Max). Desktop Macs have none; the menu says so.
- macOS 15 or newer.
- To build: Swift 6.2 or newer (Xcode 26 or its Command Line Tools).

## Install

```bash
make install
```

This builds SlapMe, signs it locally, copies it to `/Applications` (or `~/Applications`) and launches it. The first time it runs from Applications it adds itself to Login Items; turn that off in the menu.

From a release zip, unzip and run `./install.sh`. Release builds are signed ad hoc, not notarized, so the script removes the download quarantine. Only do that with a zip you trust; building from source avoids the question.

## Sounds

**Robot Voice** is the default and needs no files: the Mac talks back with the system voice, and harder or faster slaps make it angrier.

To use your own sounds, open **Sounds → Choose Folder…** and pick any folder of audio files (mp3, wav, m4a, aac, aif, aiff, caf). Each slap plays a random one, louder the harder you slap. SlapMe rescans the folder whenever you open the menu, so new files are picked up on their own. Switching back to Robot Voice keeps the folder for next time.

## Effects

| Effect | Default | What it does |
|---|---|---|
| Trackpad Haptics | On | Drives the Taptic Engine directly, so you feel it without touching the trackpad |
| Cursor Burst | On | A ring and spikes pop around the pointer |
| Screen Flash | Off | A white flash over every display, at most three per second |
| Brightness Flash | Off | Dips or lifts the built-in display's backlight |
| USB Moaner | Off | Reacts when a USB device is plugged in or removed |

Every effect except USB Moaner has an intensity slider. **Test Slap** (⌘T while the menu is open) fires everything that is on.

## How detection works

The motion sensor is a Bosch IMU behind Apple's Sensor Processing Unit (`AppleSPUHIDDevice`, usage page `0xFF00`, usage 3). SlapMe asks the sensor's driver to report every millisecond and reads its 22-byte reports (X, Y and Z as little-endian Q16 fixed point at offsets 6, 10 and 14) on a dedicated queue, at about 800 Hz.

Each sample goes through the detector in `SlapCore`:

1. **Gravity removal.** A 0.5 s low-pass tracks gravity; what remains is the shaking.
2. **Jerk.** How fast the shaking changes, summed across axes, in g/s.
3. **The gate.** A slap is strong *and* sudden at the same instant. Typing never is: its strong moments are slow and its sudden moments are tiny. A very strong hit passes on strength alone.
4. **Adaptive noise floor.** The strength threshold rises on a noisy desk and holds still during an impact.
5. **Peak hold and refractory.** A 50 ms window catches the true peak; a 140 ms quiet period keeps one slap's ringing from counting twice.

Every window is in seconds and the sample period comes from the measured rate, so detection is the same whether the sensor runs at 800 Hz or 100 Hz. If reports stop for 3 seconds (sleep, a sensor reset), SlapMe reopens the sensor, backing off up to a minute between tries.

| Sensitivity | Strength | Jerk | Strong enough alone |
|---|---|---|---|
| Extremely Sensitive | 0.15 g | 14 g/s | 0.45 g |
| High | 0.25 g | 20 g/s | 0.60 g |
| Medium | 0.40 g | 30 g/s | 0.90 g |
| Low | 0.70 g | 50 g/s | 1.50 g |
| Requires Significant Force | 1.10 g | 90 g/s | 2.20 g |

Loudness follows the peak force on a log curve, `log(1 + 99t) / log(100)`, with `t` running from 0 at 0.15 g to 1 at 1.8 g, so taps whisper and hard slaps yell.

## Private APIs

| API | Purpose |
|---|---|
| `AppleSPUHIDDriver` properties (IOKit) | Wake the motion sensor |
| `DisplayServicesGetBrightness` / `SetBrightness` | Brightness Flash |
| `MTActuatorCreateFromDeviceID` / `MTActuatorActuate` | Trackpad Haptics |

Private frameworks are loaded at runtime from `/System/Library/PrivateFrameworks`, so if Apple moves one, SlapMe still launches and only that effect falls back or switches off. The app is built with the hardened runtime and needs no SIP changes.

## Uninstall

```bash
make uninstall
```

This quits SlapMe, removes its login item and deletes the app. Your preferences stay; remove them with:

```bash
defaults delete app.slapme.SlapMe
```

## Development

```bash
make app       # dist/SlapMe.app
make run       # build and run it from the terminal
make test      # detector, streak and sensor report tests
make release   # tests, then dist/SlapMe-vX.Y.Z.zip
make icon      # redraw Resources/AppIcon.icns
```

```
Sources/SlapCore/   pure Swift, unit tested: detector, streak, sensor report decoding
Sources/SlapMe/     the menu bar app
Tests/SlapCoreTests synthetic slaps, typing and a captured sensor report
Scripts/icon.swift  draws the app icon
```
