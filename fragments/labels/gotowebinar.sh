gotowebinar)
    name="GoTo"
    type="dmg"
    downloadURL="https://goto-desktop.goto.com/GoTo-arm64.dmg"
    # GoTo publishes an electron-updater manifest with the current version.
    appNewVersion=$(curl -fsL "https://goto-desktop.goto.com/latest-mac.yml" | sed -nE 's/^version:[[:space:]]+(.+)$/\1/p')
    expectedTeamID="GFNFVT632V"
    ;;
