airtable)
    name="Airtable"
    type="dmg"
    downloadURL="https://static.airtable.com/download/AirtableInstaller.dmg"
    # Airtable's Squirrel update endpoint returns the current version as JSON.
    appNewVersion=$(curl -sSL "https://airtable.com/desktopAppLatestVersion?version=0.0.0&platform=darwin" | sed -nE 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p')
    expectedTeamID="E22RZMX62E"
    ;;
