part of changelog;

/// Stores all the available sections.
class _LogSections {
    final Logger _logger = new Logger("githelp._LogSections");

    final List<String> features = new List<String>();
    final List<String> fixes = new List<String>();
    final List<String> bugs = new List<String>();
    final List<String> docs = new List<String>();
    final List<String> style = new List<String>();
    final List<String> refactor = new List<String>();
    final List<String> test = new List<String>();
    final List<String> chore = new List<String>();

    final List<String> others = new List<String>();

    /// Label-Names
    final Map<String,List<String>> names = new Map<String,List<String>>();

    /// Holds alias for Labels
    final Map<String,String> key2Section = new Map<String,String>();

    /// Conventions: https://github.com/ajoslin/conventional-changelog/blob/master/CONVENTIONS.md
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
        key2Section["reorganize"] = "refactor";
        key2Section["reorg"] = "refactor";
        key2Section["test"] = "test";

        names.forEach((final String name,final List<String> lines) {
            if(key2Section.containsKey(name) == false) {
                throw new ArgumentError("$name ist in der key2Section-Lise nicht enthalten!!!!!");
            }
        });
    }


    void addLogLineToSection(final String line) {
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