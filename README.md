# MacOS Middleware Sound Producer

A macOS middleware that turns system activity into sounds that feel real.

## Sound Produced

- Keyboard Typing: Individual key sounds (extracted from mechanical keyboard profiles).
- Window Management: Opening, closing, moving, resizing, minimizing, and zooming windows.
- Disk Activity: File creation and modification in Documents/Desktop.
- App Activity: Loading/Processing sounds when the active app updates its title (e.g., Terminal commands).
- Network Activity: Data transfer sounds for the currently active application.

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

### Showcase Demo 🎬


```bash ./demo_mode.sh```
*Sit back and enjoy the symphony of system sounds!*

## Configuration

Edit `config.json` to change sound files or mappings:

```json
{
    "events": {
        "window_close": "path/to/sound.mp3",
        "network_activity": "path/to/loading.mp3",
        ...
    }
}
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

## License

MIT
