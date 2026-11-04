# Authen

Safari extension distro for [Authenticator](https://github.com/Authenticator-Extension/Authenticator)

<a href="https://apps.apple.com/us/app/authen/id1602945200?mt=12" target="_blank"><img width="150" alt="Download on the App Store" src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg"/></a>

![2560x1600bb](https://user-images.githubusercontent.com/876920/176361939-a359dd46-254a-4784-86bf-19f9c999f5aa.png)

## Build

The extension lives in the `authenticator` submodule.

```
git submodule update --init
./scripts/build-safari.sh
```

Open `Authenticator.xcodeproj` and run the macOS app. The script installs the submodule dependencies with Puppeteer's Chromium download skipped, and it sets `NODE_OPTIONS=--openssl-legacy-provider` so webpack 4 runs on current Node. Xcode packages `authenticator/safari`.

The project uses the published bundle ids `com.rebornix.Authen` and `com.rebornix.Authen.Extension`. `DEVELOPMENT_TEAM` is empty. Signing and the App Store upload stay with the maintainers. The deployment target is macOS 14.4, which is what `ASWebAuthenticationSession` needs for an https callback.

Google Drive sign-in uses the client id already in the Chrome manifest. The client secret in `authenticator/src/models/credentials.ts` stays empty in git. The release script fills it before a production build. The redirect is `https://authenticator.cc/oauth`.

## Drive backups

A backup is a dated JSON file in a Drive folder named Authenticator Backups. The scope is `drive.file`, so the app only sees files it created. There is no download or merge.

With a passphrase, the file is encrypted. That encryption is only as strong as the passphrase. With encryption turned off, or with no passphrase, the file is the raw secrets. The Drive page already warns about that. Dropbox and OneDrive stay in the code and stay hidden on Safari.

## Dependencies

`crypto-js` is 4.2.0. That clears the production PBKDF2 advisory `npm audit` reported for 4.0.0.

These stay unfixed because the fix is a new major version, and this tree stays on Vue 2 and webpack 4:

- `uuid` 3.x. The patched release is 11.
- Vue 2. The ReDoS advisory is fixed in Vue 3, and Vue 2 is end of life.
- High and critical findings in the dev tree (webpack 4, eslint 6, and their dependencies). `npm audit fix --force` would leave Vue 2 and webpack 4.
