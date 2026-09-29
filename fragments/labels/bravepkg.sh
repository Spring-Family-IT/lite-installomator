bravepkg)
    name="Brave Browser"
    type="pkg"
    downloadURL="https://referrals.brave.com/latest/Brave-Browser.pkg" # Universal
        # https://referrals.brave.com/latest/Brave-Browser-arm64.pkg - ARM64
    appNewVersion="$(curl -fsL "https://updates.bravesoftware.com/sparkle/Brave-Browser/stable/appcast.xml" | grep -oE 'sparkle:version="[0-9.]+"' | cut -d '"' -f 2 | sort -V | tail -n 1)" # lite: highest version, feed order is not reliable
    versionKey="CFBundleVersion"
    expectedTeamID="KL8N8XSYF4"
    ;;
