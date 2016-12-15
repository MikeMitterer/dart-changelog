# changelog for Dart
Its main purpose is to write a <strong>CHANGELOG.md</strong> file.
You can also set the version of your pubspec.yaml according to the latest git tag.
Helps with some "git" related stuff. (Mainly initializing the local repo) 
 
### Example output
* https://github.com/MikeMitterer/dart-changelog/blob/master/CHANGELOG.md

### How to use it
1. *Modify your source*
1. git commit -am "feature: My new, exciting feature"
1. git tag v0.1.\<increase prev. version\> *(e.g. if it was v0.1.0 - set it to v0.1.1)*  
1. cl -x *(This writes the new CHANGELOG.md and updates the version in pubspec.yaml)*
1. git commit -am "Released v\<your new version\>" && git push && git publish

  
### Installation

Install
```shell
    pub global activate changelog
```

Update
```shell
    # activate changelog again
    pub global activate changelog
```

Uninstall
```shell
    pub global deactivate changelog
```

### Usage + Workflow

```shell
    # your commit with a "keyword"
    git commit -am "feature: This is my new feature"
    git tag 0.0.1 or git tag -am 0.0.1
    
    # Write CHANGELOG.md and set the version in pubspec.yaml
    changelog -x
    
    # Push CHANGELOG.md and the changed (version) pubspec.yaml to origin
    git commit -am "Released 0.0.1"
    git push origin master

    # push everything to your repo
    git push origin master
    
    # push it to pub
    pub publish 
```
-c - Writes CHANGELOG.md<br>
-y - Sets the version in your pubspec.yaml<br>
-t - pushes all tags to your repo

"feature" is a commit keyword.
Supported keywords are:
```shell
Labels:
	feat      Sample: git commit -am "feat: <your message>"
	feature   Sample: git commit -am "feature: <your message>"
	chore     Sample: git commit -am "chore: <your message>"
	fix       Sample: git commit -am "fix: <your message>"
	fixes     Sample: git commit -am "fixes: <your message>"
	bug       Sample: git commit -am "bug: <your message>"
	bugs      Sample: git commit -am "bugs: <your message>"
	style     Sample: git commit -am "style: <your message>"
	doc       Sample: git commit -am "doc: <your message>"
	docs      Sample: git commit -am "docs: <your message>"
	refactor  Sample: git commit -am "refactor: <your message>"
	reorganizeSample: git commit -am "reorganize: <your message>"
	reorg     Sample: git commit -am "reorg: <your message>"
	test      Sample: git commit -am "test: <your message>"
```
All the other keywords are [here][keywords]

Instead of using `changelog [options]` you can also use `cl [options]

### Commandline-options

```shell
Usage: changelog [options]
    -h, --help          Shows this message
    -s, --settings      Prints settings
    -c, --changelog     Writes CHANGELOG.md
    -k, --keys          Print CHANGELOG keywords (lables)
    -d, --simulation    Simulation, no write operations
    -y, --yaml          Set version in pubspec.yaml
    -t, --tags          Push tags to origin
    -x, --release       Combines -c -t and -y
    -i, --init          [ your GIT-Repo name ]
    -r, --domain        [ Domain where your repo is ]
    -v, --loglevel      [ info | debug | warning ]
    -a, --account       [ Your account @ GitHub, BitBucket... ]

Sample:
    Write CHANGELOG.md:                                              'changelog -c'
    Set version in pubspec.yaml                                      'changelog -y'
    Write CHANGELOG, update Version in pubspec, push tags to origin: 'changelog -x'

    Init GitHub repo:           'changelog -a YourName -i yourrepo.git'
    Simulate initialisation:    'changelog -d -a YourName -i yourrepo.git'
    Simulate BitBucket init:    'changelog -d -r bibucket.org -a YourName -i yourrepo.git'
``` 

## Links
   - [Closing an issue in the same repository](https://help.github.com/articles/closing-issues-via-commit-messages/)
   
### License

    Copyright 2015 Michael Mitterer (office@mikemitterer.at),
    IT-Consulting and Development Limited, Austrian Branch

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
    either express or implied. See the License for the specific language
    governing permissions and limitations under the License.

If this tool is helpful for you - please [(Circle)](http://gplus.mikemitterer.at/) me.


[keywords]: https://github.com/MikeMitterer/dart-git-help/blob/master/lib/src/LogSection.dart