part of gitinit;

class Application {
    final Logger _logger = new Logger("gitinit.Application");

    static const _ARG_HELP          = 'help';
    static const _ARG_LOGLEVEL      = 'loglevel';
    static const _ARG_SETTINGS      = 'settings';
    static const _ARG_INIT          = 'init';

    ArgParser _parser;

    Application() : _parser = Application._createOptions();

    void run(final List<String> args) {

        try {
            final ArgResults argResults = _parser.parse(args);
            final Config config = new Config(argResults);

            _configLogging(config.loglevel);

           if (argResults.wasParsed(_ARG_HELP) || (/*config.dirstoscan.length == 0 && */ args.length == 0 )) {
                _showUsage();
            }
            else if (argResults.wasParsed(_ARG_SETTINGS)) {
                _printSettings(config.settings);
            }
            else if (argResults.wasParsed(_ARG_INIT)) {
                _initRepo(argResults[_ARG_INIT]);
            }
            else {
                _showUsage();
            }
        }

        on FormatException
        catch (error) {
            _showUsage();
            _logger.severe("Error: $error");
        }
    }

    // -- private -------------------------------------------------------------

    void _initRepo(final String repoName) {
        Validate.notBlank(repoName);
        Validate.isTrue(repoName.endsWith(".git"),"Repo-Name must end with .git but was $repoName");

        _logger.info("Init $repoName...");

        final File dotGit = new File(".git");

        if(!dotGit.existsSync()) {
            // git init
            final ProcessResult resultInit= Process.runSync('git', ["init"]);
            if(resultInit.exitCode != 0) {
                _logger.severe(resultInit.stderr);
            }
        }

        // git remote add origin https://github.com/MikeMitterer/dart-wsk-material.git
        final ProcessResult resultAddOrigin = Process.runSync('git', ["remote", "add" , "origin", "https://github.com/MikeMitterer/$repoName"]);
        if(resultAddOrigin.exitCode != 0) {
            _logger.severe("'remote add' failed ${resultAddOrigin.stderr}");
        }

        // git remote set-url origin git@github.com:MikeMitterer/dart-wsk-material.git
        final ProcessResult resultSetUrl = Process.runSync('git', ["remote", "set-url" , "origin", "git@github.com:MikeMitterer/$repoName"]);
        if(resultSetUrl.exitCode != 0) {
            _logger.severe("'remote set-url' faild ${resultSetUrl.stderr}}");
        }

        _logger.info("Done!");
        _logger.info("    Call now 'git push -u origin --all'");
        _logger.info("    and 'git push -u origin --tags'");
    }

    /// Goes through the files
    void _iterateThroughDirSync(final String dir, void callback(final File file)) {
        _logger.info("Scanning: $dir");

        // its OK if the path starts with packages but not if the path contains packages (avoid recursion)
        final RegExp regexp = new RegExp("^/*packages/*");

        final Directory directory = new Directory(dir);
        if (directory.existsSync()) {
            directory.listSync(recursive: true).where((final FileSystemEntity entity) {
                _logger.fine("Entity: ${entity}");

                bool isUsableFile = (entity != null && FileSystemEntity.isFileSync(entity.path) &&
                ( entity.path.endsWith(".dart") || entity.path.endsWith(".DART")) || entity.path.endsWith(".html") );

                if(!isUsableFile) {
                    return false;
                }
                if(entity.path.contains("packages")) {
                    // return only true if the path starts!!!!! with packages
                    return entity.path.contains(regexp);
                }

                return true;

            }).any((final File file) {
                //_logger.fine("  Found: ${file}");
                callback(file);
            });
        }
    }

    void _showUsage() {
        print("Usage: git-init [options]");
        _parser.getUsage().split("\n").forEach((final String line) {
            print("    $line");
        });

        print("");
        print("Sample:");
        print("    git-init -i dart-wsk-angular.git");
        print("");
    }

    void _printSettings(final Map<String,String> settings) {
        Validate.notEmpty(settings);

        int getMaxKeyLength() {
            int length = 0;
            settings.keys.forEach((final String key) => length = max(length,key.length));
            return length;
        }

        final int maxKeyLeght = getMaxKeyLength();

        String prepareKey(final String key) {
            return "${key[0].toUpperCase()}${key.substring(1)}:".padRight(maxKeyLeght + 1);
        }

        print("Settings:");
        settings.forEach((final String key,final String value) {
            print("    ${prepareKey(key)} $value");
        });
    }

    static ArgParser _createOptions() {
        final ArgParser parser = new ArgParser()

            ..addFlag(_ARG_HELP,            abbr: 'h', negatable: false, help: "Shows this message")
            ..addFlag(_ARG_SETTINGS,        abbr: 's', negatable: false, help: "Prints settings")

            ..addOption(_ARG_INIT,          abbr: 'i', help: "[ your GIT-Repo name ]")
            ..addOption(_ARG_LOGLEVEL,      abbr: 'v', help: "[ info | debug | warning ]")
        ;

        return parser;
    }

    void _configLogging(final String loglevel) {
        Validate.notBlank(loglevel);

        hierarchicalLoggingEnabled = false; // set this to true - its part of Logging SDK

        // now control the logging.
        // Turn off all logging first
        switch(loglevel) {
            case "fine":
            case "debug":
                Logger.root.level = Level.FINE;
                break;

            case "warning":
                Logger.root.level = Level.SEVERE;
                break;

            default:
                Logger.root.level = Level.INFO;
        }

        Logger.root.onRecord.listen(new LogPrintHandler(messageFormat: "%m"));
    }
}
