brave)
    name="Brave Browser"
    type="dmg"
    if [[ $(arch) != "i386" ]]; then
        printlog "Architecture: arm64 (not i386)"
        downloadURL=$(curl -fsIL https://laptop-updates.brave.com/latest/osxarm64/release | grep -i "^location" | sed -E 's/.*(https.*\.dmg).*/\1/g')
        appNewVersion="$(curl -fsL "https://updates.bravesoftware.com/sparkle/Brave-Browser/stable-arm64/appcast.xml" | grep -oE 'sparkle:version="[0-9.]+"' | cut -d '"' -f 2 | sort -V | tail -n 1)" # lite: highest version, feed order is not reliable
        #appNewVersion="96.$(curl -fsL "https://updates.bravesoftware.com/sparkle/Brave-Browser/stable-arm64/appcast.xml" | xpath '//rss/channel/item[last()]/enclosure/@sparkle:shortVersionString' 2>/dev/null  | cut -d '"' -f 2 | cut -d "." -f1-3)"
    else
        printlog "Architecture: i386"
        downloadURL=$(curl -fsIL https://laptop-updates.brave.com/latest/osx/release | grep -i "^location" | sed -E 's/.*(https.*\.dmg).*/\1/g')
        appNewVersion="$(curl -fsL "https://updates.bravesoftware.com/sparkle/Brave-Browser/stable/appcast.xml" | grep -oE 'sparkle:version="[0-9.]+"' | cut -d '"' -f 2 | sort -V | tail -n 1)" # lite: highest version, feed order is not reliable
        #appNewVersion="96.$(curl -fsL "https://updates.bravesoftware.com/sparkle/Brave-Browser/stable/appcast.xml" | xpath '//rss/channel/item[last()]/enclosure/@sparkle:shortVersionString' 2>/dev/null  | cut -d '"' -f 2 | cut -d "." -f1-3)"
    fi
    versionKey="CFBundleVersion"
#    downloadURL=$(curl -fsL "https://updates.bravesoftware.com/sparkle/Brave-Browser/stable/appcast.xml" | xpath '//rss/channel/item[last()]/enclosure/@url' 2>/dev/null  | cut -d '"' -f 2)
    expectedTeamID="KL8N8XSYF4"
    ;;
