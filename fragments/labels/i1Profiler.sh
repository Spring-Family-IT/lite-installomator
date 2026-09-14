i1profiler)
    name="i1Profiler"
    type="pkgInZip"
    # Feed uses the sparkle: prefix; xmllint has no namespace binding for it, so match attributes by local-name().
    downloadURL=$(curl -fs "https://downloads.xrite.com/downloads/autoupdate/i1profiler_mac_appcast.xml" | xmllint --xpath 'string(//rss/channel/item[1]/enclosure/@url)' -)
    appNewVersion=$(curl -fs "https://downloads.xrite.com/downloads/autoupdate/i1profiler_mac_appcast.xml" | xmllint --xpath 'string(//rss/channel/item[1]/enclosure/@*[local-name()="shortVersionString"])' -)
    expectedTeamID="2K7GT73B4R"
    ;;
