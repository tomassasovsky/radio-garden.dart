// Copyright (c) 2022, Tomás Sasovsky
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:radio_garden/radio_garden.dart';

Future<void> main() async {
  dotEnvFlavour = DotEnvFlavour.production;
  await dotEnvFlavour.initialize();

  // Create nyxx client and nyxx_commands plugin
  final client = NyxxFactory.createNyxxWebsocket(token, intents);

  final commands = CommandsPlugin(
    prefix: mentionOr((_) => prefix),
    options: const CommandsOptions(
      hideOriginalResponse: false,
    ),
  )
    ..addCommand(info)
    ..addCommand(music)
    ..addCommand(radio)
    ..onCommandError.listen(commandErrorHandler);

  client
    ..registerPlugin(Logging())
    ..registerPlugin(CliIntegration())
    ..registerPlugin(IgnoreExceptions())
    ..registerPlugin(commands);

  // Initialise our services
  PrometheusService.init(client, commands);
  MusicService.init(client);

  // Connect
  await client.connect();
}
