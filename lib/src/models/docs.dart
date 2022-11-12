// Copyright (c) 2022, Tomás Sasovsky
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final Logger _logger = Logger('RG.Packages');

/// Documentation for an entire package.
class PackageDocs {
  /// Create a new [PackageDocs] for a given package.
  PackageDocs({
    required this.packageName,
  });

  /// The name of the package.
  final String packageName;

  /// The entries into this package's documentation, mapped by qualified name.
  Map<String, DocEntry> entries = {};

  /// All the elements in this package's documentation
  Iterable<DocEntry> get elements => entries.values;

  /// The short name of the elements in this package's documentation entries.
  Iterable<String> get elementNames => elements.map((e) => e.name);

  /// The URL to this package's documentation index on [pub.dev](https://pub.dev).
  String get urlToDocs =>
      'https://pub.dev/documentation/$packageName/latest/index.json';

  /// Update this package's local data from [urlToDocs].
  Future<void> update() async {
    _logger.fine('Updating docs for package "$packageName"');

    final response = await http.get(Uri.parse(urlToDocs));

    if (response.statusCode != 200) {
      _logger.shout(
        'Unable to update docs for package "$packageName": '
        'Error ${response.statusCode}',
      );
      return;
    }

    try {
      final data = (jsonDecode(response.body) as List<dynamic>)
          .cast<Map<String, dynamic>>();

      entries = {};

      for (final dataEntry in data) {
        final entry = DocEntry.fromJson(dataEntry);

        entries[entry.qualifiedName] = entry;
      }
    } on FormatException {
      _logger.shout(
        'Unable to update docs for package "$packageName": '
        'Malformed JSON in response',
      );
    }
  }
}

/// An entry into a package's documentation.
class DocEntry {
  /// Create a new [DocEntry] for a given element.
  const DocEntry({
    required this.name,
    required this.qualifiedName,
    required this.displayName,
    required this.packageName,
    required this.type,
    required this.urlToDocs,
  });

  /// Create a [DocEntry] from a documentation entry object
  /// received from a dartdoc `index.json` file.
  factory DocEntry.fromJson(Map<String, dynamic> json) {
    final displayName = StringBuffer();

    switch (json['type']) {
      case 'constant':
      case 'property':
      case 'method':
        final enclosedBy = json['enclosedBy'] as Map;
        final name = json['name'];
        final enclosingName = enclosedBy['name'];
        displayName.write('$enclosingName.$name');
        break;
      case 'library':
        final packageName = json['packageName'];
        final name = json['name'];
        if (packageName != name) {
          displayName.write('$packageName.$name');
        } else {
          displayName.write(name);
        }
        break;
      case 'constructor':
        final enclosedBy = json['enclosedBy'] as Map;
        final name = json['name'];
        final enclosingName = enclosedBy['name'];
        if (name == enclosingName) {
          displayName.write('(new) $name');
        } else {
          displayName.write('$name');
        }
        break;
      default:
        final name = json['name'];
        displayName.write(name);
        break;
    }

    return DocEntry(
      name: json['name'] as String,
      displayName: displayName.toString(),
      qualifiedName: json['qualifiedName'] as String,
      packageName: json['packageName'] as String,
      type: json['type'] as String,
      urlToDocs:
          'https://pub.dev/documentation/${json['packageName'] as String}/latest/${json['href'] as String}',
    );
  }

  /// The short name of the element.
  final String name;

  /// The name that should be displayed to the user
  /// when interacting with this element.
  ///
  /// This is generally a combination of [name] and the enclosing element.
  final String displayName;

  /// The qualified name of the element.
  final String qualifiedName;

  final String packageName;

  /// The type of this entry.
  final String type;

  /// The URL to this element's documentation.
  final String urlToDocs;
}
