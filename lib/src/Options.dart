part of githelp;

class Options {
    static const APPNAME                = 'git-help';

    static const _ARG_HELP                  = 'help';
    static const _ARG_LOGLEVEL              = 'loglevel';
    static const _ARG_SETTINGS              = 'settings';
    static const _ARG_REPO_TO_INIT          = 'init';
    static const _ARG_CHANGELOG             = 'changelog';
    static const _ARG_CHANGELOG_KEYS        = 'keys';
    static const _ARG_SIMULATION            = 'simulation';
    static const _ARG_REPO_DOMAIN           = 'domain';
    static const _ARG_ACCOUNT               = 'account';
    static const _ARG_SET_VERSION_IN_YAML   = "yaml";

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
        print("    Init GitHub repo:           '$APPNAME -a YourName -i yourrepo.git'");
        print("    Simulate initialisation:    '$APPNAME -d -a YourName -i yourrepo.git'");
        print("    Simulate BitBucket init:    '$APPNAME -d -r bibucket.org -a YourName -i yourrepo.git'");
        print("");
        print("    Write CHANGELOG.md:         '$APPNAME -c'");
        print("    Set version in pubspec.yaml '$APPNAME -y'");
        print("");
    }

    // -- private -------------------------------------------------------------

    static ArgParser _createParser() {
        final ArgParser parser = new ArgParser()

            ..addFlag(_ARG_HELP,                abbr: 'h', negatable: false, help: "Shows this message")
            ..addFlag(_ARG_SETTINGS,            abbr: 's', negatable: false, help: "Prints settings")
            ..addFlag(_ARG_CHANGELOG,           abbr: 'c', negatable: false, help: "Writes CHANGELOG.md")
            ..addFlag(_ARG_CHANGELOG_KEYS,      abbr: 'k', negatable: false, help: "Print CHANGELOG keywords (lables)")
            ..addFlag(_ARG_SIMULATION,          abbr: 'd', negatable: false, help: "Simulation, no write operations")
            ..addFlag(_ARG_SET_VERSION_IN_YAML, abbr: 'y', negatable: false, help: "Set version in pubspec.yaml")

            ..addOption(_ARG_REPO_TO_INIT,  abbr: 'i', help: "[ your GIT-Repo name ]")
            ..addOption(_ARG_REPO_DOMAIN,   abbr: 'r', help: "[ Domain where your repo is ]")
            ..addOption(_ARG_LOGLEVEL,      abbr: 'v', help: "[ info | debug | warning ]")
            ..addOption(_ARG_ACCOUNT,       abbr: 'a', help: "[ Your account @ GitHub, BitBucket... ]")
        ;

        return parser;
    }
}