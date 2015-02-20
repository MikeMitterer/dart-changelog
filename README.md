# git-help

Helps with some "git" related things. Its main purpose is to write a <strong>CHANGELOG.md</strong> file.
You can also set the version of your pubspec.yaml according to the latest git tag.
 
###Example output###
* https://github.com/MikeMitterer/dart-git-help/blob/master/CHANGELOG.md

###Installation###

Install
```shell
    pub global activate git-help
```

Update
```shell
    # activate git-help again
    pub global activate git-help
```

###Usage + Workflow###

```shell
    # your commit with a "keyword"
    git commit -am "feature: This is my new feature"
    git tag -am 0.0.1
    
    # Write CHANGELOG.md and set the version in pubspec.yaml
    git-help -cy

    # push everything to your repo
    git push -u origin --all
    git push -u origin --tags   
    
    # push it to pub
    pub publish 
```
-c - Writes CHANGELOG.md<br>
-y - Sets the version in your pubspec.yaml

"feature" is a commit keyword. All the other keywords are [here][keywords]

###Commandline-options###

```shell
Usage: git-help [options]
    -h, --help          Shows this message
    -s, --settings      Prints settings
    -c, --changelog     Writes CHANGELOG.md
    -k, --keys          Print CHANGELOG keywords (lables)
    -d, --simulation    Simulation, no write operations
    -i, --init          [ your GIT-Repo name ]
    -r, --domain        [ Domain where your repo is ]
    -v, --loglevel      [ info | debug | warning ]
    -a, --account       [ Your account @ GitHub, BitBucket... ]

Sample:
    Init repo:                'git-help -a YourName -i yourrepo.git'
    Simpulate initialisation: 'git-help -d -a YourName -i yourrepo.git'
    Simpulate BitBucket init: 'git-help -d -r bibucket.org -a YourName -i yourrepo.git'

    Write CHANGELOG.md:       'git-help -c'
``` 

###License###

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