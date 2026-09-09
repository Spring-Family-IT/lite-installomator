sonos|\
sonoss1)
    # credit: Erik Stam (@erikstam)
    name="Sonos S1 Controller"
    type="dmg"
    downloadURL="https://www.sonos.com/redir/controller_software_mac"
    # Sonos' Akamai edge returns 403 to non-browser requests on the redirect;
    # the full header set below is required (dropping any part brings back 403).
    curlOptions=( -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" -H "Accept-Language: en-US,en;q=0.9" -H "Accept-Encoding: gzip, deflate, br" -H "Sec-Fetch-Dest: document" -H "Sec-Fetch-Mode: navigate" -H "Sec-Fetch-Site: none" )
    expectedTeamID="2G4LW83Q3E"
    ;;
