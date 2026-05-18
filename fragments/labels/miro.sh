miro)
    # credit: @matins
    name="Miro"
    type="dmg"
    if [[ $(arch) == arm64 ]]; then
        downloadURL="https://desktop.miro.com/platforms/darwin-arm64/Install-Miro.dmg"
    elif [[ $(arch) == i386 ]]; then
        downloadURL="https://desktop.miro.com/platforms/darwin/Install-Miro.dmg"
    fi
    # Miro publishes no public version endpoint that matches CFBundleShortVersionString,
    # so we proxy the Homebrew Cask version (extract_plist by their CI; ~1-3 day lag).
    appNewVersion=$(curl -fsL "https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/m/miro.rb" | sed -nE 's/^[[:space:]]*version[[:space:]]+"([^"]+)".*/\1/p')
    expectedTeamID="M3GM7MFY7U"
    ;;
