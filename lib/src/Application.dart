part of gitinit;

class Application {
    final Logger _logger = new Logger("gitinit.Application");

    static const _ARG_HELP              = 'help';
    static const _ARG_LOGLEVEL          = 'loglevel';
    static const _ARG_SETTINGS          = 'settings';
    static const _ARG_INIT              = 'init';
    static const _ARG_CHANGELOG         = 'changelog';
    static const _ARG_CHANGELOG_KEYS    = 'keys';

    ArgParser _parser;

    Application() : _parser = Application._createOptions();

    void run(final List<String> args) {

        try {
            final ArgResults argResults = _parser.parse(args);
            final Config config = new Config(argResults);

            _configLogging(config.loglevel);

            if (argResults.wasParsed(_ARG_HELP) || (/*config.dirstoscan.length == 0 && */
                args.length == 0 )) {
                _showUsage();
            }
            else if (argResults.wasParsed(_ARG_SETTINGS)) {
                _printSettings(config.settings);
            }
            else if (argResults.wasParsed(_ARG_CHANGELOG_KEYS)) {
                    _printChangelogLabels();
                }
            else if (argResults.wasParsed(_ARG_INIT)) {
                    _initRepo(argResults[_ARG_INIT]);
                }
                else if (argResults.wasParsed(_ARG_CHANGELOG)) {
                        _writeChangeLog(config.settings);
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

        final String repository = repoName.endsWith(".git") ? repoName : "${repoName}.git";
        _logger.info("Init $repository...");

        final File dotGit = new File(".git");

        if(!dotGit.existsSync()) {
            // git init
            final ProcessResult resultInit= Process.runSync('git', ["init"]);
            if(resultInit.exitCode != 0) {
                _logger.severe(resultInit.stderr);
            }
        }

        // git remote add origin https://github.com/MikeMitterer/dart-wsk-material.git
        final ProcessResult resultAddOrigin = Process.runSync('git', ["remote", "add" , "origin", "https://github.com/MikeMitterer/$repository"]);
        if(resultAddOrigin.exitCode != 0) {
            _logger.severe("'remote add' failed ${resultAddOrigin.stderr}");
        }

        // git remote set-url origin git@github.com:MikeMitterer/dart-wsk-material.git
        final ProcessResult resultSetUrl = Process.runSync('git', ["remote", "set-url" , "origin", "git@github.com:MikeMitterer/$repository"]);
        if(resultSetUrl.exitCode != 0) {
            _logger.severe("'remote set-url' faild ${resultSetUrl.stderr}}");
        }

        _logger.info("Done!");
        _logger.info("    Call now 'git push -u origin --all'");
        _logger.info("    and 'git push -u origin --tags'");
    }

    void _writeChangeLog(final Map<String,String> settings) {
        Validate.notEmpty(settings);

        final File file = new File("CHANGELOG.md");
        if(file.existsSync()) { file.deleteSync(); }

        final StringBuffer buffer = new StringBuffer();
        buffer.writeln("#Change Log#");

        String firsCharUppercase(final String word) {
            return "${word.substring(0,1).toUpperCase()}${word.substring(1)}";
        }

        void iterateThroughSection(final String tag, final String tagRange,final _LogSections sections,{ final bool isUnreleased: false }) {
            _logger.info("$tag, ${isUnreleased ? '' : _getTagDate(tag) } ($tagRange)");

            _logger.info(_getTagHeadline(tag,tagRange));

            buffer.writeln();
            if(!isUnreleased) {
                buffer.writeln("##${_getTagHeadline(tag,tagRange)} - ${_getTagDate(tag)}##");
            } else {
                buffer.writeln("##${_getTagHeadline(tag,tagRange)}##");
            }

            sections.names.forEach((final String key,final List<String> lines) {
                if(lines.isNotEmpty) {
                    _logger.info("Section: ${firsCharUppercase(key)}");
                    buffer.writeln("###${firsCharUppercase(key)}###");

                    lines.forEach((final String line) {
                        _logger.info(" - $line");
                        buffer.writeln("* ${line}");
                    });
                }
            });
        }


        final List<String> tags = _getTags();

        String tagRange = "${tags.first}...HEAD";
        final _LogSections sectionsUnreleased = _getLogSections(tagRange);
        if(!sectionsUnreleased.isEmpty()) {
            iterateThroughSection("Unreleased",tagRange,sectionsUnreleased,isUnreleased: true );
        }

        for(int index = 0; index < tags.length; index++) {
            final String tag = tags[index];
            //_logger.info("Tag: $tag, ${_getTagDate(tag)}");

            tagRange = index < tags.length - 1 ? "${tag}...${tags[index + 1]}" : tag;

            final _LogSections sections = _getLogSections(tagRange);
            if(!sections.isEmpty()) {
                iterateThroughSection(tag, tagRange,sections);
            }
        }

        file.writeAsString(buffer.toString());
        _logger.info("${file.path} created...");
    }

    void _printChangelogLabels() {
        final _LogSections sections = new _LogSections();
        _logger.info("Labels:");
        sections.key2Section.forEach((final String key,final String section ) {
            _logger.info("\t${key.padRight(10)}Sample: git commit -am \"$key: <your message>\"");
        });
        _logger.info("");
    }

    _LogSections _getLogSections(final String forTag) {
        Validate.notBlank(forTag);

        final String ghaccount = _getAccountName();
        final String ghproject = _getRepoName().replaceFirst(r".git","");

        // pretty-format: http://opensource.apple.com/source/Git/Git-19/src/git-htmldocs/pretty-formats.txt
        final String changelogformat = "%s [%h](http://github.com/$ghaccount/$ghproject/commit/%H)";
        _logger.fine(changelogformat);

        //'git', 'log',range , "--pretty=format:$changelogformat"
        final ProcessResult resultGetLog = Process.runSync('git', ["log", forTag , "--pretty=format:$changelogformat"]);
        if(resultGetLog.exitCode != 0) {
            _logger.severe("Get Log for $forTag faild with ${resultGetLog.stderr}!");
        }

        final _LogSections sections = new _LogSections();
        resultGetLog.stdout.split(new RegExp(r"\n+|\r+")).forEach((final String line) {
            if(line.isNotEmpty) {
                sections.addLineToSection(line);
            }
        });

        return sections;
    }

    String _getUser() {
        final ProcessResult resultGetUser = Process.runSync('git', ["config", "--get" , "user.name"]);
        if(resultGetUser.exitCode != 0) {
            _logger.severe("Get user.name faild with ${resultGetUser.stderr}!");
        }
        final String user = resultGetUser.stdout.trim();
        _logger.fine("User: $user");
        return user;
    }

    String _getRepoName() {
        final ProcessResult resultGetRepo = Process.runSync('git', ["config", "--get" , "remote.origin.url"]);
        if(resultGetRepo.exitCode != 0) {
            _logger.severe("Get remote.origin.url faild with ${resultGetRepo.stderr}!");
        }
        final String repository = resultGetRepo.stdout.replaceFirst(new RegExp(r"[^/]*/"),"").trim();
        _logger.fine("Repository: $repository");
        return repository;
    }

    String _getAccountName() {
        final ProcessResult resultGetRepo = Process.runSync('git', ["config", "--get" , "remote.origin.url"]);
        if(resultGetRepo.exitCode != 0) {
            _logger.severe("Get remote.origin.url faild with ${resultGetRepo.stderr}!");
        }
        String accountname = resultGetRepo.stdout.replaceFirst(new RegExp(r"[^:]*:"),"").trim();
        accountname = accountname.replaceFirst(new RegExp(r"/.*"),"").trim();
        _logger.fine("AccountName: $accountname");
        return accountname;
    }

    String _getTagDate(final String tag) {
        Validate.notBlank(tag);

        final ProcessResult resultGetTagDate = Process.runSync('git', ["log", "-1" , "--format=%ai", tag ]);
        if(resultGetTagDate.exitCode != 0) {
            _logger.severe("Get Date for Tag $tag faild with ${resultGetTagDate.stderr}!");
        }
        final String date = resultGetTagDate.stdout.replaceFirst(new RegExp(r" .*"),"").trim();
        _logger.fine("Date: $date");
        return date;
    }

    String _getTagHeadline(final String tag, final String range) {
        Validate.notBlank(tag);
        Validate.notBlank(range);

        final String ghaccount = _getAccountName();
        final String ghproject = _getRepoName().replaceFirst(r".git","");

        final String headline = "[$tag](http://github.com/$ghaccount/$ghproject/compare/$range)";
        return headline;
    }

    /// Gibt alle Tags zurück und sortiert sie in umgekehrter Reihenfolge
    List<String> _getTags() {
        // git tag -l
        final ProcessResult resultGetTags = Process.runSync('git', ["tag", "-l"]);
        if(resultGetTags.exitCode != 0) {
            _logger.severe("'Tag-Request failed with error ${resultGetTags.stderr}!");
        }
        final List<String> lines = new List<String>();

        resultGetTags.stdout.split(new RegExp(r"\s+")).forEach((final String tag) {
            if(tag.isNotEmpty) {
                lines.add(tag);
            }
        });

        lines.sort((final String one, final String two) {
            return one.compareTo(two) * -1;
        });

        _logger.fine(lines);

        return lines;
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
            ..addFlag(_ARG_CHANGELOG,       abbr: 'c', negatable: false, help: "Writes CHANGELOG.md")
            ..addFlag(_ARG_CHANGELOG_KEYS,  abbr: 'k', negatable: false, help: "Print CHANGELOG keywords (lables)")

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

class _LogSections {
    final Logger _logger = new Logger("gitinit._LogSections");

    final List<String> features = new List<String>();
    final List<String> fixes = new List<String>();
    final List<String> bugs = new List<String>();
    final List<String> docs = new List<String>();
    final List<String> style = new List<String>();
    final List<String> refactor = new List<String>();
    final List<String> test = new List<String>();
    final List<String> chore = new List<String>();

    final List<String> others = new List<String>();

    final Map<String,List<String>> names = new Map<String,List<String>>();
    final Map<String,String> key2Section = new Map<String,String>();

    _LogSections() {
        names["chore"] = chore;
        names["feature"] = features;
        names["fixes"] = fixes;
        names["bugs"] = bugs;
        names["style"] = style;
        names["docs"] = docs;
        names["refactor"] = refactor;
        names["test"] = test;

        key2Section["feat"] = "feature";
        key2Section["feature"] = "feature";
        key2Section["chore"] = "chore";
        key2Section["fix"] = "fixes";
        key2Section["fixes"] = "fixes";
        key2Section["bug"] = "bugs";
        key2Section["bugs"] = "bugs";
        key2Section["style"] = "style";
        key2Section["doc"] = "docs";
        key2Section["docs"] = "docs";
        key2Section["refactor"] = "refactor";
        key2Section["test"] = "test";

        names.forEach((final String name,final List<String> lines) {
            if(key2Section.containsKey(name) == false) {
                throw new ArgumentError("$name ist in der key2Section-Lise nicht enthalten!!!!!");
            }
        });
    }


    void addLineToSection(final String line) {
        if(line == null || line.isEmpty) {
            return;
        }

        final int index = line.indexOf(":");
        if(index == -1) {
            others.add(line);
            return;
        }
        final String section = line.substring(0,index);
        //_logger.info("Section: $section");

        if(key2Section.containsKey(section)) {
            //_logger.info("Line: $line");
            names[key2Section[section]].add(line.replaceFirst("${section}:","").trim());
        } else {
            others.add(line);
        }
    }

    bool isEmpty({ final bool includeOthers: false }) {
        bool empty = features.isEmpty && fixes.isEmpty && docs.isEmpty && style.isEmpty && refactor.isEmpty && test.isEmpty && chore.isEmpty;
        if(includeOthers) {
            empty = empty && others.isEmpty;
        }
        return empty;
    }
}
