# TorrServer Mac Installer

TorrServer Mac Installer provides a normal macOS menu bar app for installing and running TorrServer without using Terminal.

Developer: dancheskus

Project: [dancheskus/TorrServerMacInstaller](https://github.com/dancheskus/TorrServerMacInstaller)

## Download and use the app

1. Download `TorrServerMacInstaller.zip` from releases.
2. Unzip it.
3. Drag `TorrServerMacInstaller.app` to `/Applications`.
4. Open the app.
5. Use the menu bar icon to install, start, stop, update, and configure TorrServer.

The app stores TorrServer files in:

```text
~/Library/Application Support/TorrServerMacInstaller
```

When you quit the app from the menu bar, TorrServer is stopped too. Enable **Launch at Login** inside the app if you want TorrServer to start when macOS starts.

## Build from source

```bash
./scripts/build-app.sh
```

The unsigned app and zip archive will be created in `dist/`.

## Terminal alternative

The original terminal installer is still available as `installer.command`.

1. Open Terminal.
2. Navigate to the preferred download location:

```bash
cd Desktop
```

3. Download the installer:

```bash
curl https://raw.githubusercontent.com/dancheskus/TorrServerMacInstaller/main/installer.command --output TorrServer_installer.command && chmod +x TorrServer_installer.command
```

4. Run it:

```bash
./TorrServer_installer.command
```

5. Enter your macOS password when asked.
