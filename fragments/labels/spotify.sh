spotify)
    name="Spotify"
    type="dmg"
    if [[ $(arch) == arm64 ]]; then
        downloadURL="https://download.scdn.co/SpotifyARM64.dmg"
    elif [[ $(arch) == i386 ]]; then
        downloadURL="https://download.scdn.co/Spotify.dmg"
    fi
    # No public version endpoint; URL serves DMG directly. Homebrew uses extract_plist;
    # proxy their cask version (~1-3 day lag).
    appNewVersion=$(curl -fsL "https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/s/spotify.rb" | sed -nE 's/^[[:space:]]*version[[:space:]]+"([^"]+)".*/\1/p')
    expectedTeamID="2FNC3A47ZF"
    ;;
