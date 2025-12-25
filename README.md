# MacOS Middleware Sound Producer

A macOS middleware that turns system activity into sounds that feel real.

## Sound Produced

- Keyboard Typing: Individual key sounds (extracted from mechanical keyboard profiles).
- Window Management: Opening, closing, moving, resizing, minimizing, and zooming windows.
- Disk Activity: File creation and modification in Documents/Desktop.
- App Activity: Loading/Processing sounds when the active app updates its title (e.g., Terminal commands).
- Network Activity: Data transfer sounds for the currently active application.

### File Monitoring Scope
To prevent constant system noise, this tool **only** monitors specific user directories:
- `~/Desktop`
- `~/Documents`

*Changes in Downloads, Home, or System folders are ignored.*

## Requirements

- **macOS 13.0+** (Ventura or later recommended)
- **Accessibility Permissions**: The app requires Accessibility privileges to monitor key presses and window events.

## Installation & Usage

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/gajzzs/MacOSMiddleWareSoundProducer.git
    cd MacOSMiddleWareSoundProducer
    ```

2.  **Build and Run**:
    ```bash
    swift run
    ```
    *Note: The first time you run it, macOS will ask for Accessibility Permissions. Grant them in System Settings -> Privacy & Security -> Accessibility, then restart the app.*

3.  **Run in Background**:
    You can run it directly from the terminal, or quit the terminal and it will stay running (if launched via `swift run &`).
    Control the app via the **Waveform Icon** in the Menu Bar.

4.  **Foreground Mode (Debug)**:
    If you want to see logs or run it in your terminal:
    ```bash
    MacOSMiddleWareForeground=1 swift run
    ```

### Showcase Demo 🎬


```bash ./demo_mode.sh```
*Sit back and enjoy the symphony of system sounds!*

## Configuration

Edit `config.json` to change sound files or mappings:

```
{
    "events": {
        "window_close": "path/to/sound.mp3",
        "network_activity": "path/to/loading.mp3",
        ...
    }
}
```

### Environment Variables
You can override configuration dynamically using environment variables.

#### 1. Audio Overrides
Override any event sound path by prefixing the event name with `MW_SOUND_`.
```bash
export MW_SOUND_WINDOW_OPEN="/path/to/custom_open.mp3"
export MW_SOUND_APP_ACTIVITY="/path/to/blip.wav"
```

#### 2. Role Filtering
Fine-tune which Accessibility Roles trigger sounds.

**Role Groups**:
- `Structural` (SplitGroups, Drawers, Grids - *Ignored by default*)
- `Web` (Links, WebAreas - *Ignored by default*)
- `Input` (TextFields, TextAreas - *Ignored by default*)
- `Menus` (Status Bars, Menu Items - *Ignored by default*)
- `Controls` (Checkboxes, Sliders, Buttons - *Ignored by default*)

**Commands**:
```bash
# Enable a group (Un-ignore)
export MW_ENABLE_GROUP="Structural,Web"

# Disable a group (Force Ignore)
export MW_DISABLE_GROUP="Controls"

# Specific Roles
export MW_INCLUDE_ROLES="AXButton"
export MW_IGNORE_ROLES="AXTitle"
```

## Tips for Best Experience

Since this app provides audio feedback, you might find that the default macOS visual animations feel "slow" compared to the instant sound.

For a snappier feel, you can speed up or disable system animations:

1.  **Disable Window Animations** (Instant Open/Close):
    ```bash
    defaults write -g NSAutomaticWindowAnimationsEnabled -bool false
    ```
2.  **Speed up Resize**:
    ```bash
    defaults write -g NSWindowResizeTime -float 0.001
    ```
    *(Restart apps or logout/login for changes to apply fully)*

### To Revert Changes (Restore Defaults)

If you miss the animations, run these commands:

```bash
defaults delete -g NSAutomaticWindowAnimationsEnabled
defaults delete -g NSWindowResizeTime
```

## Roadmap / Known Issues

- [ ] **optimization**: Fix high system usage (likely due to aggressive Accessibility polling or `nettop` monitoring).
- [ ] **features**: Add filter for specific applications.

## License

MIT
