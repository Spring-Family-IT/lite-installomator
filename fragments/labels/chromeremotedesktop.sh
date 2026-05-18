chromeremotedesktop)
    name="chromeremotedesktop"
    type="pkgInDmg"
    packageID="com.google.pkg.ChromeRemoteDesktopHost"
    downloadURL="https://dl.google.com/chrome-remote-desktop/chromeremotedesktop.dmg"
    # No public version endpoint; Homebrew uses extract_plist on the same DMG.
    # Proxy their cask version (~1-3 day lag).
    appNewVersion=$(curl -fsL "https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/c/chrome-remote-desktop-host.rb" | sed -nE 's/^[[:space:]]*version[[:space:]]+"([^"]+)".*/\1/p')
    expectedTeamID="EQHXZ8M8AV"
    ;;
