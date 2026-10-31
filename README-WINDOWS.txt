OSOBNÝ STRÁŽCA — WINDOWS BUILD STARTER

This package adds a GitHub Actions workflow to build the Swift app on a GitHub-hosted macOS runner. It does not itself sign or install the app. The build is unsigned; a compatible sideloading tool must sign it for your own device using your Apple Account.

BUILD STEPS
1. Extract this ZIP.
2. Create a new PUBLIC repository on GitHub (the standard hosted macOS runner is free for public repositories).
3. Upload all extracted files/folders, including the hidden .github folder, to the repository. Ensure the workflow file is at .github/workflows/build-ios.yml.
4. Open the repository's Actions tab. Select “Build Osobny Strazca iOS app” and run the workflow, or push to main.
5. When it finishes successfully, open the workflow run and download the “OsobnyStrazca-unsigned-ipa” artifact. Extract the downloaded artifact ZIP to get OsobnyStrazca-unsigned.ipa.
6. Use a reputable iOS sideloading tool on Windows to sign and install the IPA on your own iPhone with your Apple Account. Follow that tool's current official instructions. A free signing profile typically expires after 7 days and then needs refreshing.

NOTES
- Do not put passwords, Apple Account credentials, certificates, or other secrets into the repository.
- The source is not yet tested by Xcode in this environment. If the build fails, open the failed workflow and copy the first relevant error from the build log.
- Bluetooth and notifications must be tested on a real iPhone with the ESP32. Background behavior is subject to iOS restrictions.
- This is a school-project starter, not a certified safety device.


LATEST APP TEXT UPDATE
- Fall events are now displayed as “Pád zaznamenaný”.
- The app keeps the ESP32 BLE event identifier PAD_DETEKTOVANY unchanged; only the text shown in the app and notification has changed.
- The fall notification explains that a possible fall was recorded and asks the recipient to check on the user.
- Test, ready, and alarm-cancel events now show readable Slovak descriptions instead of raw firmware codes.

To publish this update, replace the files in your GitHub repository with the updated package contents and run the GitHub Actions workflow again. Install the newly built IPA over the previous build (or remove the old app first if your sideloading tool requires it).
