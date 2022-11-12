FROM dart:2.18.0 AS build

WORKDIR /app
COPY pubspec.* /app/
RUN dart pub get

COPY . /app
RUN dart pub get --offline

RUN dart run nyxx_commands:compile bin/radio_garden_development.dart -o bot.dart
EXPOSE 8080
EXPOSE 2333

CMD [ "./bot.exe" ]
