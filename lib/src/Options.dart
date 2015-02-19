part of githelp;

class Options {
    static const APPNAME                = 'git-help';

    static const _ARG_HELP              = 'help';
    static const _ARG_LOGLEVEL          = 'loglevel';
    static const _ARG_SETTINGS          = 'settings';
    static const _ARG_INIT              = 'init';
    static const _ARG_CHANGELOG         = 'changelog';
    static const _ARG_CHANGELOG_KEYS    = 'keys';
    static const _ARG_SIMULATION        = 'simulation';

    final ArgParser _parser;

    Options() : _parser = Options._createParser();

    ArgResults parse(final List<String> args) {
        Validate.notNull(args);
        return _parser.parse(args);
    }

    void showUsage() {
        print("Usage: $APPNAME [options]");
        _parser.getUsage().split("\n").forEach((final String line) {
            print("    $line");
        });

        print("");
        print("Sample:");
        print("    $APPNAME -i dart-wsk-angular.git");
        print("");
    }

    // -- private -------------------------------------------------------------

    static ArgParser _createParser() {
        final ArgParser parser = new ArgParser()

            ..addFlag(_ARG_HELP,            abbr: 'h', negatable: false, help: "Shows this message")
            ..addFlag(_ARG_SETTINGS,        abbr: 's', negatable: false, help: "Prints settings")
            ..addFlag(_ARG_CHANGELOG,       abbr: 'c', negatable: false, help: "Writes CHANGELOG.md")
            ..addFlag(_ARG_CHANGELOG_KEYS,  abbr: 'k', negatable: false, help: "Print CHANGELOG keywords (lables)")
            ..addFlag(_ARG_SIMULATION,      abbr: 'd', negatable: false, help: "Simulation, no write operations")

            ..addOption(_ARG_INIT,          abbr: 'i', help: "[ your GIT-Repo name ]")
            ..addOption(_ARG_LOGLEVEL,      abbr: 'v', help: "[ info | debug | warning ]")
        ;

        return parser;
    }
}