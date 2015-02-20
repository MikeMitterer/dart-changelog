part of githelp;

/// Repo baut schlussendlich immer etwas
/// in dieser Art zusammen:
///     http://$baseUrl/$account/$repository/commit/%H
///     http://github.com/MikeMitterer/dart-wsk-material/commit/f98429bc61b9c87261b56283bb8034debdaca919
abstract class Repo {
    /// Sample: dart-wsk-material
    String get repository;

    /// Sample: MikeMitterer
    String get account;

    /// Sample: github.com
    String get domain;

    /// Sample: git@github.com:MikeMitterer/dart-wsk-material.git
    String get urlToAdd;

    /// Sample BitBucket: ssh://git@bitbucket.org/mikemitterer/webapp.base.dart.git
    /// Sample GH: git@github.com:MikeMitterer/dart-wsk-material.git
    String get originToAdd;

    bool get isValid;

    factory Repo() {
        final Logger _logger = new Logger("githelp.factory.Repo");

        final ProcessResult result = Process.runSync('git', ["config", "--get", "remote.origin.url"]);
        if (result == null || result.stdout.isEmpty || result.exitCode != 0) {
            _logger.fine("Get remote.origin.url faild. ${result.stderr}, using DummyRepo instead!");
            return new _DummyRepo();
        }
        final String originUrl = result.stdout as String;
        if (originUrl.contains("github")) {
            return new RepoGitHub(originUrl);

        } else if(originUrl.contains("bitbucket")) {
            return new RepoBitBucket(originUrl);
        }

        return new _DummyRepo(originUrl);
    }

    /// For "init" - returns the right Repo before!!!! initialisation
    factory Repo.forSimulation(final String simulationDomain,
                               final String simulationAccount,
                               final String simulationRepository) {
        Validate.notBlank(simulationDomain);
        Validate.notBlank(simulationAccount);
        Validate.notBlank(simulationRepository);

        if (simulationDomain.contains("github")) {
            return new RepoGitHub("git@${simulationDomain}:${simulationAccount}/$simulationRepository");

        } else if(simulationDomain.contains("bitbucket")) {
            return new RepoBitBucket("ssh://git@${simulationDomain}/${simulationAccount}/$simulationRepository");
        }

        return new _DummyRepo("${simulationDomain}:${simulationAccount}/$simulationRepository");
    }

    // -- private -------------------------------------------------------------


}

class _DummyRepo implements Repo {
    final Logger _logger = new Logger("githelp._DummyRepo");

    final String _originUrl;

    String get repository => "";

    String get account => "";

    String get domain => "";

    String get originToAdd => _originUrl;

    String get urlToAdd => "";

    bool get isValid => false;

    _DummyRepo(this._originUrl);
}

class RepoGitHub implements Repo {
    final Logger _logger = new Logger("githelp.RepoGitHub");

    // remote.origin.url=git@github.com:MikeMitterer/dart-wsk-material.git
    final String _originUrl;

    RepoGitHub(this._originUrl) {
        Validate.notBlank(_originUrl);
    }

    bool get isValid => true;

    /// github.com
    String get domain {
        String baseurl = _originUrl.replaceFirst(new RegExp(r"[^@]*@"), "").trim();
        baseurl = baseurl.replaceFirst(new RegExp(r":.*"), "").trim();
        _logger.finer("BaseUrl: $baseurl");
        return baseurl;
    }

    /// MikeMitterer
    String get account {
        String accountname = _originUrl.replaceFirst(new RegExp(r"[^:]*:"), "").trim();
        accountname = accountname.replaceFirst(new RegExp(r"/.*"), "").trim().toLowerCase();
        _logger.finer("AccountName: $accountname");
        return accountname;
    }

    /// dart-wsk-material
    String get repository {
        String repository = _originUrl.replaceFirst(new RegExp(r"[^/]*/"), "").trim();
        repository = repository.replaceFirst(r".git","");

        _logger.finer("Repository: $repository");
        return repository;
    }

    /// Sample: git@github.com:MikeMitterer/dart-wsk-material.git
    String get urlToAdd => "git@${domain}:${account}/${repository}.git";


    /// Sample GH: https://github.com/MikeMitterer/dart-wsk-material.git
    String get originToAdd => "https://${domain}/${account}/${repository}.git";
}


class RepoBitBucket implements Repo {
    final Logger _logger = new Logger("githelp.RepoBitBucket");

    // remote.origin.url=ssh://git@bitbucket.org/mikemitterer/webapp.base.dart.git
    final String _originUrl;

    RepoBitBucket(this._originUrl) {
        Validate.notBlank(_originUrl);
    }

    bool get isValid => true;

    /// bitbucket.org
    String get domain {
        String baseurl = _originUrl.replaceFirst(new RegExp(r"[^@]*@"), "").trim();
        baseurl = baseurl.replaceFirst(new RegExp(r"/.*"), "").trim();
        _logger.finer("BaseUrl: $baseurl");
        return baseurl;
    }

    /// mikemitterer
    String get account {
        String everythingAfterAt = _originUrl.replaceFirst(new RegExp(r"[^@]*@"), "").trim();
        everythingAfterAt = everythingAfterAt.replaceFirst(domain,"").trim();

        final List<String> parts = everythingAfterAt.split("/");

        final String accountname = parts[1].toLowerCase();
        _logger.finer("AccountName: $accountname");
        return accountname;
    }


    String get repository {
        String everythingAfterAt = _originUrl.replaceFirst(new RegExp(r"[^@]*@"), "").trim();
        everythingAfterAt = everythingAfterAt.replaceFirst("${domain}","");

        final List<String> parts = everythingAfterAt.split("/");

        final String repository = parts[2].toLowerCase().replaceFirst(r".git","");

        _logger.finer("Repository: $repository");
        return repository;
    }

    /// Sample: git@github.com:MikeMitterer/dart-wsk-material.git
    String get urlToAdd => "git@${domain}:${account}/${repository}.git";

    /// Sample BitBucket: git@bitbucket.org:mikemitterer/eosflexmobile.git
    String get originToAdd => "git@${domain}:${account}/${repository}.git";
}