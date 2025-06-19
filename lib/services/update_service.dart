import 'package:flutter/material.dart';
import 'package:flutter_autoupdate/flutter_autoupdate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static Future<void> checkForUpdate(BuildContext context) async {
    final updater = UpdateManager(
      versionUrl: 'https://agung-dev-project.web.app/version.json',
    );

    final result = await updater.fetchUpdates();

    final info = await PackageInfo.fromPlatform();
    final versionString = info.version.split('+').first;
    final currentVersion = Version.parse(versionString);

    if (result != null && Version.parse(result.latestVersion.toString()) > currentVersion) {
      // Tampilkan dialog update
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Update Available'),
          content: Text(
            'Version ${result.latestVersion} is available.\n\n${result.releaseNotes ?? ""}',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await launchUrl(Uri.parse(result.downloadUrl));
              },
              child: const Text('Download from GitHub'),
            ),
          ],
        ),
      );
    }
  }
}
