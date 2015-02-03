library test;

import 'dart:html';
import 'package:unittest/html_enhanced_config.dart';

//-----------------------------------------------------------------------------
// Notwendige externe includes

import 'package:unittest/unittest.dart';

import 'dart:collection';
import 'dart:async';

import 'package:json/json.dart' as Json;
import 'package:event_bus/event_bus.dart';
import 'package:intl/intl.dart';
import 'package:http_utils/http_utils.dart';

//-----------------------------------------------------------------------------
// Logging

import 'package:logging/logging.dart';

// Handlers that are shared between client and server
import 'package:logging_handlers/logging_handlers_shared.dart';
//import 'package:logging_handlers/browser_logging_handlers.dart';

//-----------------------------------------------------------------------------
// Teile des Packages die getestet werden (mobiad_rest_ui)
//      Sample: import 'package:mobiad_rest_ui/<library>.dart';
//

//-----------------------------------------------------------------------------
// Test-Imports (find . -mindepth 2 -iname "*.dart" | sed "s/\.\///g" | sed "s/\(.*\)/part '\1';/g")


part 'simple/simple_test.dart';

// Mehr Infos: http://www.dartlang.org/articles/dart-unit-tests/
void main() {
    final Logger logger = new Logger("test");

    useHtmlEnhancedConfiguration();
    configLogging();
    //startQuickLogging();

    testSimple();

}

// Weitere Infos: https://github.com/chrisbu/logging_handlers#quick-reference

void configLogging() {
    hierarchicalLoggingEnabled = false; // set this to true - its part of Logging SDK

    // now control the logging.
    // Turn off all logging first
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen(new LogPrintHandler());
}
