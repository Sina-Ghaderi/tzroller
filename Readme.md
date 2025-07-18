# tzroller

**tzroller** is a Magisk module that automatically fetches the latest [IANA tzdata](https://www.iana.org/time-zones), compiles it, and installs it on your Android device.

## Features

- Automatically downloads the latest IANA timezone database
- Compiles tzdata into Android-compatible format
- Installs updated time zone definitions system-wide via Magisk
- Keeps your Android device's time zone data in sync with upstream

## Requirements

- Rooted Android device with [Magisk](https://topjohnwu.github.io/Magisk/) installed
- Internet connection  
**Note for users in Iran 🇮🇷:** Accessing the IANA tzdata server requires a **VPN**.

## Installation

1. Go to the [Releases](https://github.com/Sina-Ghaderi/tzroller/releases) section of this repository.
2. Download the latest `tzroller.zip` file.
3. Open the Magisk app.
4. Navigate to **Modules** > **Install from storage**.
5. Select the downloaded ZIP file.
6. Reboot your device.

## How It Works

1. On installation or update, the module downloads the latest tzdata from IANA.
2. It compiles the tzdata using `zic` (zone information compiler).
3. The compiled data is copied via Magisk overlay to one of the following system paths, depending on your Android version:
   - `/system/usr/share/zoneinfo` (for older Android versions)
   - `/system/apex/com.android.tzdata/etc/tz` (for Android 10 and above)
4. Android will then use the updated timezone definitions without requiring a full system update.

## Notes

- This module replaces system timezone data only at runtime using Magisk overlay. It does **not** modify the actual system partition.
- Supports both legacy and APEX-based tzdata locations.
- Compatible with most Android ROMs and versions that follow the AOSP structure.
- To update the data manually, simply re-install the module.

## Disclaimer

Use at your own risk. While the module is designed to be safe and non-destructive, modifying system behavior always carries some risk. Make sure to have a backup before making changes.

## License

MIT License

---

Feel free to contribute or open issues for bugs and suggestions.
