part of githelp;

class Application {
    final Logger _logger = new Logger("githelp.Application");

    final Options options;

    Application() : options = new Options();

    void run(final List<String> args) {

        try {
            final ArgResults argResults = options.parse(args);
            final Config config = new Config(argResults);

            _configLogging(config.loglevel);

            if (argResults.wasParsed(Options._ARG_HELP) || (/*config.dirstoscan.length == 0 && */
                args.length == 0 )) {
                options.showUsage();
                return;
            }

            if (argResults.wasParsed(Options._ARG_SETTINGS)) {
                _printSettings(config.settings);
                return;
            }

            if (argResults.wasParsed(Options._ARG_CHANGELOG_KEYS)) {
                    _printChangelogLabels();
            }

            if (argResults.wasParsed(Options._ARG_INIT)) {
                _initRepo(argResults[Options._ARG_INIT]);
            }
            else if (argResults.wasParsed(Options._ARG_CHANGELOG)) {
                _writeChangeLog(config.simulation);
            }
            else {
                options.showUsage();
            }
        }

        on FormatException
        catch (error) {
            options.showUsage();
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

    void _writeChangeLog(final bool isSimulation) {

        final File file = new File("CHANGELOG.md");
        if(file.existsSync()) { file.deleteSync(); }

        final StringBuffer buffer = new StringBuffer();
        buffer.writeln("#Change Log#");

        String firsCharUppercase(final String word) {
            return "${word.substring(0,1).toUpperCase()}${word.substring(1)}";
        }

        void iterateThroughSection(final String tag, final String tagRange,final _LogSections sections,{ final bool isUnreleased: false }) {
            _logger.fine("\n$tag, ${isUnreleased ? '' : _getTagDate(tag) } ($tagRange)");
            //_logger.fine(_getTagHeadline(tag,tagRange));

            buffer.writeln();
            if(!isUnreleased) {
                buffer.writeln("##${_getTagHeadline(tag,tagRange)} - ${_getTagDate(tag)}##");
            } else {
                buffer.writeln("##${_getTagHeadline(tag,tagRange)}##");
            }

            sections.names.forEach((final String key,final List<String> lines) {
                if(lines.isNotEmpty) {
                    _logger.fine("Section: ${firsCharUppercase(key)}");
                    buffer.writeln("###${firsCharUppercase(key)}###");

                    lines.forEach((final String line) {
                        _logger.fine(" * $line");
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

        if(!isSimulation) {
            file.writeAsString(buffer.toString());
            _logger.info("\n${file.path} created...");
        }
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

        final Repo repo = new Repo();
        String changelogformat;
        if(repo.isValid) {
            final String ghaccount = repo.account;
            final String repository = repo.repository.replaceFirst(r".git","");
            final String baseurl = repo.baseUrl;

            // pretty-format: http://opensource.apple.com/source/Git/Git-19/src/git-htmldocs/pretty-formats.txt
            changelogformat = "%s [%h](http://$baseurl/$ghaccount/$repository/commit/%H)";
        } else {
            changelogformat = "%s [%h]";
        }
        //_logger.fine(changelogformat);

        //'git', 'log',range , "--pretty=format:$changelogformat"
        final ProcessResult resultGetLog = Process.runSync('git', ["log", forTag , "--pretty=format:$changelogformat"]);
        if(resultGetLog.exitCode != 0) {
            _logger.severe("Get Log for $forTag faild with ${resultGetLog.stderr}!");
        }

        final _LogSections sections = new _LogSections();
        resultGetLog.stdout.split(new RegExp(r"\n+|\r+")).forEach((final String line) {
            if(line.isNotEmpty) {
                sections.addLogLineToSection(line);
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

    String _getTagDate(final String tag) {
        Validate.notBlank(tag);

        final ProcessResult result = Process.runSync('git', ["log", "-1" , "--format=%ai", tag ]);
        if(result.exitCode != 0) {
            _logger.severe("Get Date for Tag $tag faild with ${result.stderr}!");
        }
        final String date = result.stdout.replaceFirst(new RegExp(r" .*"),"").trim();
        //_logger.fine("Date: $date");
        return date;
    }

    String _getTagHeadline(final String tag, final String range) {
        Validate.notBlank(tag);
        Validate.notBlank(range);

        final Repo repo = new Repo();
        String headline;
        if(repo.isValid) {
            final String ghaccount = repo.account;
            final String repository = repo.repository.replaceFirst(r".git","");
            final String baseurl = repo.baseUrl;

            headline = "[$tag](http://$baseurl/$ghaccount/$repository/compare/$range)";

        } else {
            headline = "$tag";
        }

        return headline;
    }

    /// Gibt alle Tags zurück und sortiert sie in umgekehrter Reihenfolge
    List<String> _getTags() {
        // git tag -l
        final ProcessResult resultGetTags = Process.runSync('git', ["tag", "-l"]);
        if(resultGetTags.exitCode != 0) {
            _logger.severe("'Tag-Request failed with error ${resultGetTags.stderr}!");
        }
        final List<String> tags = new List<String>();

        resultGetTags.stdout.split(new RegExp(r"\s+")).forEach((final String tag) {
            if(tag.isNotEmpty) {
                tags.add(tag);
            }
        });

        tags.sort((final String one, final String two) {
            return one.compareTo(two) * -1;
        });

        _logger.fine("Tags with annotation (git tag -am v1.1): $tags");

        return tags;
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


