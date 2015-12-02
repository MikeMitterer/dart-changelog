part of githelp;

/**
 * Defines default-configurations.
 * Most of these configs can be overwritten by commandline args.
 */
class Config {
    final Logger _logger = new Logger("githelp.Config");

    final ArgResults _argResults;
    final Map<String,dynamic> _settings = new Map<String,dynamic>();

    Config(this._argResults) {

        _settings[Options._ARG_LOGLEVEL]      = 'info';
        _settings[Options._ARG_SIMULATION]    = false;
        _settings[Options._ARG_PUSH_TAGS]     = false;
        _settings[Options._ARG_REPO_DOMAIN]   = "github.com";
        _settings[Options._ARG_ACCOUNT]       = "<not set>";
        _settings[Options._ARG_REPO_TO_INIT]  = "<not set>";

        _overwriteSettingsWithArgResults();
    }

    List<String> get dirstoscan => _argResults.rest;

    String get loglevel => _settings[Options._ARG_LOGLEVEL];
    bool get simulation => _settings[Options._ARG_SIMULATION];
    String get domain => _settings[Options._ARG_REPO_DOMAIN];
    String get account => _settings[Options._ARG_ACCOUNT];
    String get repotoinit => _settings[Options._ARG_REPO_TO_INIT];
    bool get pushtags => _settings[Options._ARG_PUSH_TAGS];

    void printSettings() {

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

    Map<String,String> get settings {
        final Repo repo = new Repo();
        final Map<String,String> settings = new Map<String,String>();

        settings["loglevel"]                                = loglevel;
        settings["Simulation only, no write to filesystem"] = simulation ? "yes" : "no";
        settings["Predefined origin domain"]                = repo.isValid ? repo.domain : domain;
        settings["Push tags to origin "]                    = pushtags ? "yes" : "no";;

        settings["Repo is valid (remote url set)"]          = repo.isValid ? "yes" : "no";
        settings["Accout"]                                  = repo.isValid ? repo.account : account;
        settings["Repository"]                              = repo.isValid ? "${repo.repository}.git" : repotoinit;
        settings["Domain"]                                  = repo.isValid ? repo.domain : domain;

        if(dirstoscan.length > 0) {
            settings["Dirs to scan"]                        = dirstoscan.join(", ");
        }

        return settings;
    }

    // -- private -------------------------------------------------------------

    _overwriteSettingsWithArgResults() {

        if(_argResults.wasParsed(Options._ARG_LOGLEVEL)) {
            _settings[Options._ARG_LOGLEVEL] = _argResults[Options._ARG_LOGLEVEL];
        }

        if(_argResults.wasParsed(Options._ARG_SIMULATION)) {
            _settings[Options._ARG_SIMULATION] = true;
        }

        if(_argResults.wasParsed(Options._ARG_REPO_DOMAIN)) {
            _settings[Options._ARG_REPO_DOMAIN] = _argResults[Options._ARG_REPO_DOMAIN];
        }

        if(_argResults.wasParsed(Options._ARG_ACCOUNT)) {
            _settings[Options._ARG_ACCOUNT] = (_argResults[Options._ARG_ACCOUNT] as String).replaceAll(" ","");
        }

        if(_argResults.wasParsed(Options._ARG_REPO_TO_INIT)) {
            _settings[Options._ARG_REPO_TO_INIT] = _argResults[Options._ARG_REPO_TO_INIT];
            if(! (_settings[Options._ARG_REPO_TO_INIT] as String).endsWith(".git")) {
                _settings[Options._ARG_REPO_TO_INIT] = "${_settings[Options._ARG_REPO_TO_INIT]}.git";
            }
        }

    }
}
