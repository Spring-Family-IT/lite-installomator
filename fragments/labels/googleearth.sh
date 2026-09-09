googleearth)
    name="Google Earth Pro"
    type="pkgInDmg"
    downloadURL="https://dl.google.com/earth/client/advanced/current/GoogleEarthProMac-Intel.dmg"
    # No public version endpoint; URL serves the DMG directly with no version hints.
    # Proxy the Homebrew Cask version (their CI runs extract_plist; ~1-3 day lag).
    # Upstream scrapes "7.3" from google.com/earth/about/versions, which can never
    # detect point releases, so it is not used here.
    appNewVersion=$(curl -fsL "https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/g/google-earth-pro.rb" | sed -nE 's/^[[:space:]]*version[[:space:]]+"([^"]+)".*/\1/p')
    # App reports CFBundleShortVersionString="7.3" but CFBundleVersion="7.3.7.1327";
    # only the latter matches the cask version, so compare on it.
    versionKey="CFBundleVersion"
    expectedTeamID="EQHXZ8M8AV"
    ;;
