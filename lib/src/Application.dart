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
                return;
            }

            bool foundOptionToWorkWith = false;
            if (argResults.wasParsed(Options._ARG_REPO_TO_INIT) && argResults.wasParsed(Options._ARG_ACCOUNT)) {
                foundOptionToWorkWith = true;
                initRepo(config);
            }
            if (argResults.wasParsed(Options._ARG_CHANGELOG)) {
                foundOptionToWorkWith = true;
                writeChangeLog(config.simulation);
            }
            if (argResults.wasParsed(Options._ARG_SET_VERSION_IN_YAML)) {
                foundOptionToWorkWith = true;
                setVersionInYaml(config.simulation);
            }

            if(!foundOptionToWorkWith) {
                options.showUsage();
            }
        }

        on FormatException
        catch (error) {
            options.showUsage();
            _logger.severe("Error: $error");
        }
    }


    void initRepo(final Config config) {
        Validate.notNull(config);

        final String repository = config.repotoinit.endsWith(".git") ? config.repotoinit : "${config.repotoinit}.git";
        _logger.info("Init $repository...");

        final Repo repo = new Repo();
        if(repo.isValid) {
            _logger.info("Repo is already initialisized - nothing more todo!");
            return;
        }

        final Repo simulatedRepo = new Repo.forSimulation(config.domain,config.account,repository);
        if(!simulatedRepo.isValid) {
            throw new ArgumentError("Invalid Repo-Url: ${simulatedRepo.originToAdd}");
        }

        if(config.simulation == false) {
            final File dotGit = new File(".git");

            if(!dotGit.existsSync()) {
                // git init
                final ProcessResult resultInit= Process.runSync('git', ["init"]);
                if(resultInit.exitCode != 0) {
                    _logger.severe(resultInit.stderr);
                }
            }

            // git remote add origin https://github.com/MikeMitterer/dart-wsk-material.git
            // git remote add origin git@bitbucket.org:mikemitterer/eosflexmobile.git
            final ProcessResult resultAddOrigin = Process.runSync('git', ["remote", "add" , "origin", simulatedRepo.originToAdd ]);
            if(resultAddOrigin.exitCode != 0) {
                _logger.severe("'remote add' failed ${resultAddOrigin.stderr}");
            }

            // git remote set-url origin git@github.com:MikeMitterer/dart-wsk-material.git
            // git remote set-url origin git@bitbucket.org:mikemitterer/eosflexmobile.git
            final ProcessResult resultSetUrl = Process.runSync('git', ["remote", "set-url" , "origin", simulatedRepo.urlToAdd ]);
            if(resultSetUrl.exitCode != 0) {
                _logger.severe("'remote set-url' faild ${resultSetUrl.stderr}}");
            }

        } else {
            // -------- Simulation!!!! --------
            _logger.info("git init");
            _logger.info("git remote add origin ${simulatedRepo.originToAdd}");
            _logger.info("git remote set-url origin ${simulatedRepo.urlToAdd}");
        }

        _logger.info("Done!");
        _logger.info("    Call now 'git push -u origin --all'");
        _logger.info("    and 'git push -u origin --tags'");
    }

    void writeChangeLog(final bool isSimulation) {

        final File file = new File("CHANGELOG.md");
        if(file.existsSync()) { file.deleteSync(); }

        final String yamlName = _yamlName;
        final String yamlDescription = _yamlDescription;

        final StringBuffer buffer = new StringBuffer();
        if(yamlName.isNotEmpty) {
            buffer.writeln("#Change Log for ${yamlName}#");

        } else { buffer.writeln("#Change Log#"); }

        if(yamlDescription.isNotEmpty) { buffer.writeln(yamlDescription); }

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
                    buffer.writeln("\n###${firsCharUppercase(key)}###");

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
        } else {
            _logger.info(buffer.toString());
        }
        _logger.info("${file.path} created...");
    }

    void setVersionInYaml(final bool isSimulation) {
        final List<String> tags = _getTags();
        if(tags.isEmpty) {
            _logger.warning("No tags available. Add one with 'git tag -am 0.0.1'");
            return;
        }

        final String tag = tags.first;

        if(!isSimulation) {
            final File file = new File("pubspec.yaml");
            if(!file.existsSync()) {
                _logger.warning("${file.path} not found.");
                return;
            }
            String content = file.readAsStringSync();
            content = content.replaceFirst(new RegExp(r"version: .*"),"version: $tag");

            file.writeAsStringSync(content);
        }
        _logger.info("Version is set to: $tag");
    }

    // -- private -------------------------------------------------------------
    String get _yamlName => _getYamlPart("name");

    String get _yamlDescription => _getYamlPart("description");

    String _getYamlPart(final String part) {
        Validate.notBlank(part);

        final File file = new File("pubspec.yaml");
        if(!file.existsSync()) {
            return "";
        }
        final RegExp regexp = new RegExp("$part: (.*)");
        final String content = file.readAsStringSync();
        final Match m = regexp.firstMatch(content);
        if(m == null) {
            return "";
        }
        return m[1];
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
            final String repository = repo.repository;
            final String domain = repo.domain;

            // pretty-format: http://opensource.apple.com/source/Git/Git-19/src/git-htmldocs/pretty-formats.txt
            changelogformat = "%s [%h](http://$domain/$ghaccount/$repository/commit/%H)";
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
            final String repository = repo.repository;
            final String domain = repo.domain;

            if(tag == "Unreleased") {
                headline = "[$tag](http://$domain/$ghaccount/$repository/compare/$range)";
            } else {
                headline = "[$tag](http://$domain/$ghaccount/$repository/commits/$tag)";
            }

        } else {
            headline = "$tag";
        }

        return headline;
    }

    /// Gibt alle Tags zurück den aktuellsten zuerst
    List<String> _getTags() {
        // git tag -l
        final ProcessResult resultGetTags = Process.runSync('git', ["tag", "-l"]);
        if(resultGetTags.exitCode != 0) {
            _logger.severe("'Tag-Request failed with error ${resultGetTags.stderr}!");
        }
        final List<String> tags = new List<String>();
        resultGetTags.stdout.split(new RegExp(r"\s+")).reversed.forEach((final String tag) {
            if(tag.isNotEmpty) {
                tags.add(tag);
            }
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


