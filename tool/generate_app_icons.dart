/* I set up the app identity infrastructure for Android and PWA, including:

- `pubspec.yaml`
  - Added `flutter_launcher_icons` dev dependency.
  - Added `flutter_icons` config pointing at `assets/images/app_logo.png`.
  - Added `assets/images/` to Flutter assets so logo files are available at runtime.

- `tool/generate_app_icons.dart`
  - New script to generate Android `mipmap` launcher icons and PWA web icons from:
    - `assets/images/app_logo.png` for Android
    - `assets/images/primary_logo.png` for PWA when available
  - It writes: */
// - `android/app/src/main/res/mipmap-*/ic_launcher.png`
/*     - `web/icons/Icon-192.png`
    - `web/icons/Icon-512.png`
    - `web/icons/Icon-maskable-192.png`
    - `web/icons/Icon-maskable-512.png`

- `web/manifest.json`
  - Updated app name/short name/description/scope to `Campaignza`.

- `web/index.html`
  - Added explicit favicon/apple-touch-icon links for the PWA.

What remains
- The script could not actually generate icons yet because neither `assets/images/app_logo.png` nor `assets/images/primary_logo.png` is present in the current workspace.
- Once those files are added, run:
  - `flutter pub run tool/generate_app_icons.dart`
  - optionally `flutter pub run flutter_launcher_icons:main` for launcher icon generation via the standard plugin */

import 'dart:io';

import 'package:image/image.dart';

const _androidIconSizes = {
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

const _webIconSizes = [192, 512];

void main() {
  final appLogo = File('assets/images/app_logo.png');
  final primaryLogo = File('assets/images/primary_logo.png');

  if (!appLogo.existsSync() && !primaryLogo.existsSync()) {
    stderr.writeln(
      'Missing app logo source files. Place one of the following in assets/images/:\n'
      '  - app_logo.png\n'
      '  - primary_logo.png',
    );
    exit(1);
  }

  final androidSource = appLogo.existsSync() ? appLogo : primaryLogo;
  final webSource = primaryLogo.existsSync() ? primaryLogo : appLogo;

  _generateAndroidIcons(androidSource);
  _generateWebIcons(webSource);

  stdout.writeln('App icon generation complete.');
}

void _generateAndroidIcons(File sourceFile) {
  final bytes = sourceFile.readAsBytesSync();
  final image = decodeImage(bytes);
  if (image == null) {
    stderr.writeln('Unable to decode source image: ${sourceFile.path}');
    exit(1);
  }

  final square = _cropToSquare(image);

  for (final entry in _androidIconSizes.entries) {
    final outputDir = Directory('android/app/src/main/res/${entry.key}');
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final resized = copyResize(square, width: entry.value, height: entry.value);
    final outputFile = File('${outputDir.path}/ic_launcher.png');
    outputFile.writeAsBytesSync(encodePng(resized));
    stdout.writeln('Created Android icon: ${outputFile.path}');
  }
}

void _generateWebIcons(File sourceFile) {
  final bytes = sourceFile.readAsBytesSync();
  final image = decodeImage(bytes);
  if (image == null) {
    stderr.writeln('Unable to decode source image: ${sourceFile.path}');
    exit(1);
  }

  final square = _cropToSquare(image);
  final iconsDir = Directory('web/icons');
  if (!iconsDir.existsSync()) {
    iconsDir.createSync(recursive: true);
  }

  for (final size in _webIconSizes) {
    final resized = copyResize(square, width: size, height: size);
    final iconFile = File('${iconsDir.path}/Icon-$size.png');
    iconFile.writeAsBytesSync(encodePng(resized));
    stdout.writeln('Created web icon: ${iconFile.path}');

    final maskableFile = File('${iconsDir.path}/Icon-maskable-$size.png');
    maskableFile.writeAsBytesSync(encodePng(resized));
    stdout.writeln('Created web maskable icon: ${maskableFile.path}');
  }
}

Image _cropToSquare(Image image) {
  if (image.width == image.height) return image;

  if (image.width > image.height) {
    final left = ((image.width - image.height) / 2).round();
    return copyCrop(
      image,
      x: left,
      y: 0,
      width: image.height,
      height: image.height,
    );
  }

  final top = ((image.height - image.width) / 2).round();
  return copyCrop(image, x: 0, y: top, width: image.width, height: image.width);
}
