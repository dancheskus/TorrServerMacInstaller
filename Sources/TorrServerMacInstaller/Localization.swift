import Foundation

enum L {
    private enum Language {
        case bg
        case en
        case fr
        case ro
        case ru
        case uk

        static var current: Language {
            switch UserDefaults.standard.string(forKey: "languageCode") {
            case "bg": return .bg
            case "en": return .en
            case "fr": return .fr
            case "ro": return .ro
            case "ru": return .ru
            case "uk": return .uk
            default: break
            }

            let preferred = Locale.preferredLanguages.first?.lowercased() ?? ""
            if preferred.hasPrefix("bg") { return .bg }
            if preferred.hasPrefix("fr") { return .fr }
            if preferred.hasPrefix("ro") { return .ro }
            if preferred.hasPrefix("ru") { return .ru }
            if preferred.hasPrefix("uk") { return .uk }
            return .en
        }
    }

    private static var language: Language { .current }

    private static func text(bg: String, en: String, fr: String, ro: String, ru: String, uk: String) -> String {
        switch language {
        case .bg: bg
        case .en: en
        case .fr: fr
        case .ro: ro
        case .ru: ru
        case .uk: uk
        }
    }

    static var notInstalled: String { text(bg: "Не е инсталиран", en: "Not Installed", fr: "Non installé", ro: "Neinstalat", ru: "Не установлено", uk: "Не встановлено") }
    static var stopped: String { text(bg: "Спрян", en: "Stopped", fr: "Arrêté", ro: "Oprit", ru: "Остановлен", uk: "Зупинено") }
    static var starting: String { text(bg: "Стартиране", en: "Starting", fr: "Démarrage", ro: "Pornire", ru: "Запуск", uk: "Запуск") }
    static var running: String { text(bg: "Работи", en: "Running", fr: "En cours", ro: "Rulează", ru: "Работает", uk: "Працює") }
    static func running(_ version: String) -> String { "\(running) \(version)" }
    static var stopping: String { text(bg: "Спиране", en: "Stopping", fr: "Arrêt", ro: "Oprire", ru: "Остановка", uk: "Зупинка") }
    static var installing: String { text(bg: "Инсталиране", en: "Installing", fr: "Installation", ro: "Instalare", ru: "Установка", uk: "Встановлення") }
    static var error: String { text(bg: "Грешка", en: "Error", fr: "Erreur", ro: "Eroare", ru: "Ошибка", uk: "Помилка") }

    static var webUI: String { text(bg: "Уеб интерфейс", en: "Web UI", fr: "Interface web", ro: "Interfață web", ru: "Веб-интерфейс", uk: "Вебінтерфейс") }
    static var openInBrowser: String { text(bg: "Отвори в браузъра", en: "Open in Browser", fr: "Ouvrir dans le navigateur", ro: "Deschide în browser", ru: "Открыть в браузере", uk: "Відкрити в браузері") }
    static var version: String { text(bg: "Версия", en: "Version", fr: "Version", ro: "Versiune", ru: "Версия", uk: "Версія") }
    static var reloadVersions: String { text(bg: "Обнови списъка с версии", en: "Reload versions", fr: "Recharger les versions", ro: "Reîncarcă versiunile", ru: "Обновить список версий", uk: "Оновити список версій") }
    static var latest: String { text(bg: "последна", en: "latest", fr: "dernière", ro: "ultima", ru: "последняя", uk: "остання") }
    static var install: String { text(bg: "Инсталирай", en: "Install", fr: "Installer", ro: "Instalează", ru: "Установить", uk: "Встановити") }
    static var installSelectedVersion: String { install }
    static var installLatest: String { text(bg: "Инсталирай последната", en: "Install Latest", fr: "Installer la dernière", ro: "Instalează ultima", ru: "Установить последнюю", uk: "Встановити останню") }
    static var settings: String { text(bg: "Настройки", en: "Settings", fr: "Réglages", ro: "Setări", ru: "Настройки", uk: "Налаштування") }
    static var languageLabel: String { text(bg: "Език", en: "Language", fr: "Langue", ro: "Limbă", ru: "Язык", uk: "Мова") }
    static var languageSystem: String { text(bg: "Системен", en: "System", fr: "Système", ro: "Sistem", ru: "Системный", uk: "Системна") }
    static var languageBulgarian: String { text(bg: "Български", en: "Bulgarian", fr: "Bulgare", ro: "Bulgară", ru: "Болгарский", uk: "Болгарська") }
    static var languageEnglish: String { text(bg: "Английски", en: "English", fr: "Anglais", ro: "Engleză", ru: "Английский", uk: "Англійська") }
    static var languageFrench: String { text(bg: "Френски", en: "French", fr: "Français", ro: "Franceză", ru: "Французский", uk: "Французька") }
    static var languageRomanian: String { text(bg: "Румънски", en: "Romanian", fr: "Roumain", ro: "Română", ru: "Румынский", uk: "Румунська") }
    static var languageRussian: String { text(bg: "Руски", en: "Russian", fr: "Russe", ro: "Rusă", ru: "Русский", uk: "Російська") }
    static var languageUkrainian: String { text(bg: "Украински", en: "Ukrainian", fr: "Ukrainien", ro: "Ucraineană", ru: "Украинский", uk: "Українська") }
    static var port: String { text(bg: "Порт", en: "Port", fr: "Port", ro: "Port", ru: "Порт", uk: "Порт") }
    static var authorization: String { text(bg: "Авторизация", en: "Authorization", fr: "Autorisation", ro: "Autorizare", ru: "Авторизация", uk: "Авторизація") }
    static var username: String { text(bg: "Потребител", en: "Username", fr: "Nom d'utilisateur", ro: "Utilizator", ru: "Пользователь", uk: "Користувач") }
    static var password: String { text(bg: "Парола", en: "Password", fr: "Mot de passe", ro: "Parolă", ru: "Пароль", uk: "Пароль") }
    static var launchAtLogin: String { text(bg: "Стартирай при вход", en: "Launch at Login", fr: "Lancer à l'ouverture de session", ro: "Pornește la autentificare", ru: "Запускать при входе", uk: "Запускати при вході") }
    static var stopServer: String { text(bg: "Спри сървъра", en: "Stop Server", fr: "Arrêter le serveur", ro: "Oprește serverul", ru: "Остановить сервер", uk: "Зупинити сервер") }
    static var startServer: String { text(bg: "Стартирай сървъра", en: "Start Server", fr: "Démarrer le serveur", ro: "Pornește serverul", ru: "Запустить сервер", uk: "Запустити сервер") }
    static var removeServer: String { text(bg: "Премахни сървъра", en: "Remove Server", fr: "Supprimer le serveur", ro: "Elimină serverul", ru: "Удалить сервер", uk: "Видалити сервер") }
    static var remove: String { text(bg: "Премахни", en: "Remove", fr: "Supprimer", ro: "Elimină", ru: "Удалить", uk: "Видалити") }
    static var cancel: String { text(bg: "Отказ", en: "Cancel", fr: "Annuler", ro: "Anulează", ru: "Отмена", uk: "Скасувати") }
    static var open: String { text(bg: "Отвори", en: "Open", fr: "Ouvrir", ro: "Deschide", ru: "Открыть", uk: "Відкрити") }
    static var removeServerTitle: String { text(bg: "Премахване на сървъра?", en: "Remove server?", fr: "Supprimer le serveur ?", ro: "Eliminați serverul?", ru: "Удалить сервер?", uk: "Видалити сервер?") }
    static var removeServerMessage: String { text(bg: "Бинарният файл на TorrServer ще бъде изтрит. Автоинсталацията няма да се стартира отново, докато не инсталирате сървъра ръчно.", en: "The TorrServer binary will be deleted. Automatic installation will not run again until you install the server manually.", fr: "Le binaire TorrServer sera supprimé. L'installation automatique ne se relancera pas tant que vous n'installez pas le serveur manuellement.", ro: "Binarul TorrServer va fi șters. Instalarea automată nu va mai rula până când instalați serverul manual.", ru: "Бинарный файл TorrServer будет удален. Автоустановка больше не запустится, пока вы не установите сервер вручную.", uk: "Бінарний файл TorrServer буде видалено. Автовстановлення більше не запуститься, доки ви не встановите сервер вручну.") }
    static var restart: String { text(bg: "Рестартирай", en: "Restart", fr: "Redémarrer", ro: "Repornește", ru: "Перезапустить", uk: "Перезапустити") }
    static var restartRequired: String { text(bg: "Нужен е рестарт, за да се приложат промените.", en: "Restart required to apply changes.", fr: "Redémarrage requis pour appliquer les modifications.", ro: "Este necesară repornirea pentru a aplica modificările.", ru: "Нужен перезапуск, чтобы применить изменения.", uk: "Потрібен перезапуск, щоб застосувати зміни.") }
    static var about: String { text(bg: "За приложението", en: "About", fr: "À propos", ro: "Despre", ru: "О приложении", uk: "Про програму") }
    static var developer: String { text(bg: "Разработчик на инсталатора: dancheskus", en: "Installer developer: dancheskus", fr: "Développeur de l'installateur : dancheskus", ro: "Dezvoltator instalator: dancheskus", ru: "Разработчик установщика: dancheskus", uk: "Розробник інсталятора: dancheskus") }

    static var openApp: String { text(bg: "Отвори приложението", en: "Open App", fr: "Ouvrir l'app", ro: "Deschide aplicația", ru: "Открыть приложение", uk: "Відкрити програму") }
    static var installOrUpdate: String { text(bg: "Инсталирай / обнови...", en: "Install / Update...", fr: "Installer / Mettre à jour...", ro: "Instalează / Actualizează...", ru: "Установить / обновить...", uk: "Встановити / оновити...") }
    static var quit: String { text(bg: "Изход", en: "Quit", fr: "Quitter", ro: "Ieșire", ru: "Выйти", uk: "Вийти") }
    static var quitTitle: String { text(bg: "Изход от TorrServer?", en: "Quit TorrServer?", fr: "Quitter TorrServer ?", ro: "Ieși din TorrServer?", ru: "Выйти из TorrServer?", uk: "Вийти з TorrServer?") }
    static var quitAgain: String { text(bg: "Натиснете Command-Q още веднъж за изход.", en: "Press Command-Q again to quit.", fr: "Appuyez à nouveau sur Command-Q pour quitter.", ro: "Apăsați din nou Command-Q pentru a ieși.", ru: "Нажмите Command-Q еще раз, чтобы выйти.", uk: "Натисніть Command-Q ще раз, щоб вийти.") }
    static var quitAgainServerWillStop: String { text(bg: "Натиснете Command-Q още веднъж за изход. TorrServer ще бъде спрян.", en: "Press Command-Q again to quit. TorrServer will stop.", fr: "Appuyez à nouveau sur Command-Q pour quitter. TorrServer sera arrêté.", ro: "Apăsați din nou Command-Q pentru a ieși. TorrServer se va opri.", ru: "Нажмите Command-Q еще раз, чтобы выйти. TorrServer будет остановлен.", uk: "Натисніть Command-Q ще раз, щоб вийти. TorrServer буде зупинено.") }

    static var installingFallback: String { text(bg: "Инсталиране...", en: "Installing...", fr: "Installation...", ro: "Instalare...", ru: "Установка...", uk: "Встановлення...") }
    static var loadingVersions: String { text(bg: "Зареждане на версии...", en: "Loading versions...", fr: "Chargement des versions...", ro: "Se încarcă versiunile...", ru: "Загрузка версий...", uk: "Завантаження версій...") }
    static var startingServer: String { text(bg: "Стартиране на сървъра...", en: "Starting server...", fr: "Démarrage du serveur...", ro: "Se pornește serverul...", ru: "Запуск сервера...", uk: "Запуск сервера...") }
    static var stoppingServer: String { text(bg: "Спиране на сървъра...", en: "Stopping server...", fr: "Arrêt du serveur...", ro: "Se oprește serverul...", ru: "Остановка сервера...", uk: "Зупинка сервера...") }
    static var serverStartFailed: String { text(bg: "Сървърът не успя да стартира.", en: "Server failed to start.", fr: "Le serveur n'a pas pu démarrer.", ro: "Serverul nu a pornit.", ru: "Сервер не удалось запустить.", uk: "Не вдалося запустити сервер.") }
    static var preparingInstallation: String { text(bg: "Подготовка на инсталацията...", en: "Preparing installation...", fr: "Préparation de l'installation...", ro: "Se pregătește instalarea...", ru: "Подготовка установки...", uk: "Підготовка встановлення...") }
    static var preparingFolders: String { text(bg: "Подготовка на папките...", en: "Preparing folders...", fr: "Préparation des dossiers...", ro: "Se pregătesc dosarele...", ru: "Подготовка папок...", uk: "Підготовка папок...") }
    static func downloading(_ tag: String) -> String { text(bg: "Изтегляне на \(tag)...", en: "Downloading \(tag)...", fr: "Téléchargement de \(tag)...", ro: "Se descarcă \(tag)...", ru: "Загрузка \(tag)...", uk: "Завантаження \(tag)...") }
    static var installingServerBinary: String { text(bg: "Инсталиране на сървърния файл...", en: "Installing server binary...", fr: "Installation du binaire serveur...", ro: "Se instalează binarul serverului...", ru: "Установка бинарного файла...", uk: "Встановлення бінарного файлу...") }

    static var releasesLoadError: String { text(bg: "Неуспешно зареждане на релийзите на TorrServer.", en: "Could not load TorrServer releases.", fr: "Impossible de charger les versions de TorrServer.", ro: "Nu s-au putut încărca versiunile TorrServer.", ru: "Не удалось загрузить релизы TorrServer.", uk: "Не вдалося завантажити релізи TorrServer.") }
    static func downloadError(_ tag: String) -> String { text(bg: "Неуспешно изтегляне на \(tag).", en: "Could not download \(tag).", fr: "Impossible de télécharger \(tag).", ro: "Nu s-a putut descărca \(tag).", ru: "Не удалось загрузить \(tag).", uk: "Не вдалося завантажити \(tag).") }
    static var authRequiredError: String { text(bg: "При включена авторизация са нужни потребител и парола.", en: "Username and password are required when authorization is enabled.", fr: "Un nom d'utilisateur et un mot de passe sont requis lorsque l'autorisation est activée.", ro: "Numele de utilizator și parola sunt necesare când autorizarea este activată.", ru: "Для включенной авторизации нужны имя пользователя и пароль.", uk: "Для ввімкненої авторизації потрібні ім'я користувача та пароль.") }
    static var portRangeError: String { text(bg: "Портът трябва да бъде между 1 и 65535.", en: "Port must be between 1 and 65535.", fr: "Le port doit être compris entre 1 et 65535.", ro: "Portul trebuie să fie între 1 și 65535.", ru: "Порт должен быть от 1 до 65535.", uk: "Порт має бути від 1 до 65535.") }
}
