duckduckgo)
    name="DuckDuckGo"
    type="dmg"
    # lite: appcast2 mixes public and internal-channel builds, newest first.
    # Take the highest public version (items without <sparkle:channel>) and
    # the enclosure URL of that same item.
    ddgXML=$(curl -fsL "https://staticcdn.duckduckgo.com/macos-desktop-browser/appcast2.xml")
    appNewVersion=$(printf "%s\n" "$ddgXML" | xpath '//rss/channel/item[not(sparkle:channel)]/sparkle:shortVersionString/text()' 2>/dev/null | grep -oE '^[0-9.]+$' | sort -V | tail -n 1)
    downloadURL=$(printf "%s\n" "$ddgXML" | xpath "(//rss/channel/item[not(sparkle:channel)][sparkle:shortVersionString='${appNewVersion}']/enclosure/@url)[1]" 2>/dev/null | cut -d '"' -f 2)
    expectedTeamID="HKE973VLUW"
    ;;
