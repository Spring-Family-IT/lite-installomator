asana)
    name="Asana"
    type="dmg"
    downloadURL="https://desktop-downloads.asana.com/darwin_universal/prod/latest/Asana.dmg"
    appNewVersion=$(curl -fsL "https://desktop-downloads.asana.com/darwin_universal/prod/RELEASES.json" | sed -nE 's/.*"currentRelease"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p')
    expectedTeamID="A679L395M8"
    ;;
