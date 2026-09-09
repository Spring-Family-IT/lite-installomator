sonoss2)
    name="Sonos"
    type="dmg"
    downloadURL="https://www.sonos.com/redir/controller_software_mac2"
    # Sonos' Akamai edge returns 403 to non-browser requests on the redirect;
    # the full header set below is required (dropping any part brings back 403).
    curlOptions=( -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" -H "Accept-Language: en-US,en;q=0.9" -H "Accept-Encoding: gzip, deflate, br" -H "Sec-Fetch-Dest: document" -H "Sec-Fetch-Mode: navigate" -H "Sec-Fetch-Site: none" )
    # DMG ships CFBundleShortVersionString=17.x (marketing) and CFBundleVersion=90.0.xxxxx
    # (build, encoded in filename Sonos_90.0-xxxxx.dmg). Only the build is derivable, so compare on it.
    versionKey="CFBundleVersion"
    appNewVersion=$(curl -sL -r 0-0 -o /dev/null -w "%{url_effective}" "${curlOptions[@]}" "${downloadURL}" | sed -nE 's@.*/Sonos_([0-9.\-]+)\.dmg$@\1@p' | tr '-' '.')
    expectedTeamID="2G4LW83Q3E"
    ;;
