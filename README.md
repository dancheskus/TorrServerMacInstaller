# TorrServer Mac Installer

TorrServer Mac Installer is a macOS menu bar app for installing, running, updating, and configuring TorrServer without using Terminal.

Developer: dancheskus

Project: [dancheskus/TorrServerMacInstaller](https://github.com/dancheskus/TorrServerMacInstaller)

## English

### Install and use the app


1. Download `TorrServerMacInstaller.dmg` from the latest GitHub Release.
2. Open the DMG file.
3. Drag `TorrServerMacInstaller.app` into `Applications`.
4. Open the app from `Applications`.
5. Use the menu bar icon to install, start, stop, update, and configure TorrServer.

The app stores TorrServer files here:

```text
~/Library/Application Support/TorrServerMacInstaller
```

When you quit the app from the menu bar, TorrServer is stopped too. Enable **Launch at Login** inside the app if you want TorrServer to start automatically when macOS starts.

If macOS warns that the app is from an unidentified developer, open **System Settings** -> **Privacy & Security** and allow the app there, or right-click the app and choose **Open**.

### Terminal installer alternative

If you prefer not to use the app, the original terminal installer is still available as `installer.command`.


1. Open Terminal.
2. Go to the folder where you want to download the script:

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


5. Enter your macOS password when Terminal asks for it.

## Русский

### Установка и использование приложения


1. Скачайте `TorrServerMacInstaller.dmg` из последнего GitHub Release.
2. Откройте DMG-файл.
3. Перетащите `TorrServerMacInstaller.app` в `Applications`.
4. Запустите приложение из `Applications`.
5. Используйте иконку в меню-баре, чтобы установить, запустить, остановить, обновить и настроить TorrServer.

Приложение хранит файлы TorrServer здесь:

```text
~/Library/Application Support/TorrServerMacInstaller
```

Если выйти из приложения через меню-бар, TorrServer тоже будет остановлен. Включите **Launch at Login** внутри приложения, если хотите, чтобы TorrServer запускался автоматически при старте macOS.

Если macOS предупреждает, что приложение от неизвестного разработчика, откройте **System Settings** -> **Privacy & Security** и разрешите запуск приложения там, либо нажмите правой кнопкой по приложению и выберите **Open**.

### Альтернатива: установка через Terminal

Если вы не хотите использовать приложение, можно воспользоваться оригинальным терминальным установщиком `installer.command`.


1. Откройте Terminal.
2. Перейдите в папку, куда хотите скачать скрипт:

```bash
cd Desktop
```


3. Скачайте установщик:

```bash
curl https://raw.githubusercontent.com/dancheskus/TorrServerMacInstaller/main/installer.command --output TorrServer_installer.command && chmod +x TorrServer_installer.command
```


4. Запустите его:

```bash
./TorrServer_installer.command
```


5. Введите пароль macOS, когда Terminal попросит его.


