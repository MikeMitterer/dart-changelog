part of gitinit;

/**
 * Defines default-configurations.
 * Most of these configs can be overwritten by commandline args.
 */
class Config {
    final Logger _logger = new Logger("gitinit.Config");

    static const String _KEY_LOGLEVEL     = "loglevel";

    final ArgResults _argResults;
    final Map<String,dynamic> _settings = new Map<String,dynamic>();

    Config(this._argResults) {

        _settings[_KEY_LOGLEVEL]      = 'info';

        _overwriteSettingsWithArgResults();
    }

    List<String> get dirstoscan => _argResults.rest;

    String get loglevel => _settings[_KEY_LOGLEVEL];


    Map<String,String> get settings {
        final Map<String,String> settings = new Map<String,String>();

        settings["loglevel"]        = loglevel;

        if(dirstoscan.length > 0) {
            settings["Dirs to scan"] = dirstoscan.join(", ");
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

        if(_argResults[Application._ARG_LOGLEVEL] != null) {
            _settings[_KEY_LOGLEVEL] = _argResults[Application._ARG_LOGLEVEL];
        }
    }
}
