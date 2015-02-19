part of githelp;

/**
 * Defines default-configurations.
 * Most of these configs can be overwritten by commandline args.
 */
class Config {
    final Logger _logger = new Logger("githelp.Config");

    static const String _KEY_LOGLEVEL     = "loglevel";
    static const String _KEY_SIMULATION   = "simulation";

    final ArgResults _argResults;
    final Map<String,dynamic> _settings = new Map<String,dynamic>();

    Config(this._argResults) {

        _settings[_KEY_LOGLEVEL]      = 'info';
        _settings[_KEY_SIMULATION]    = false;

        _overwriteSettingsWithArgResults();
    }

    List<String> get dirstoscan => _argResults.rest;

    String get loglevel => _settings[_KEY_LOGLEVEL];
    bool get simulation => _settings[_KEY_SIMULATION];

    Map<String,String> get settings {
        final Map<String,String> settings = new Map<String,String>();

        settings["loglevel"]                                = loglevel;
        settings["Simulation only, no write to filesystem"] = simulation ? "yes" : "no";

        if(dirstoscan.length > 0) {
            settings["Dirs to scan"]                            = dirstoscan.join(", ");
        }

        return settings;
    }

    // -- private -------------------------------------------------------------

    _overwriteSettingsWithArgResults() {

        /// Makes sure that path does not end with a /
        String checkPath(final String arg) {
            String path = arg;
            if(path.endsWith("/")) {
                path = path.replaceFirst(new RegExp("/\$"),"");
            }
            return path;
        }

        if(_argResults.wasParsed(Options._ARG_LOGLEVEL)) {
            _settings[_KEY_LOGLEVEL] = _argResults[Options._ARG_LOGLEVEL];
        }

        if(_argResults.wasParsed(Options._ARG_SIMULATION)) {
            _settings[_KEY_SIMULATION] = true;
        }

    }
}
