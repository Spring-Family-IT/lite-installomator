googleearth)
    name="Google Earth Pro"
    type="pkgInDmg"
    downloadURL="https://dl.google.com/earth/client/advanced/current/GoogleEarthProMac-Intel.dmg"
    # No public version endpoint; URL serves the DMG directly with no version hints.
    # Proxy the Homebrew Cask version (their CI runs extract_plist; ~1-3 day lag).
    appNewVersion=$(curl -fsL "https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/g/google-earth-pro.rb" | sed -nE 's/^[[:space:]]*version[[:space:]]+"([^"]+)".*/\1/p')
    expectedTeamID="EQHXZ8M8AV"
    ;;
