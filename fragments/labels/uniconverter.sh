uniconverter)
    # credit: Gabe Marchan (gabemarchan.com - @darklink87)
    # Wondershare publishes a CRM release-versions API; first item is the latest.
    # The app bundle embeds the major version (Wondershare UniConverter 17.app);
    # CFBundleVersion is the API-comparable string (17.3.5) — CFBundleShortVersionString
    # carries an extra build suffix (17.3.5.108) that doesn't appear in the API.
    type="zip"
    appNewVersion=$(curl -sSL "https://crm.wondershare.com/api/v1/support/14207/release-versions" | grep -oE '"version_name":"[^"]+"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
    name="Wondershare UniConverter ${appNewVersion%%.*}"
    versionKey="CFBundleVersion"
    if [[ $(arch) == arm64 ]]; then
        downloadURL="https://download.wondershare.com/cbs_down/uniconverter-mac_arm_${appNewVersion}_full14207.zip"
    elif [[ $(arch) == i386 ]]; then
        downloadURL="https://download.wondershare.com/cbs_down/uniconverter-mac_${appNewVersion}_full14207.zip"
    fi
    expectedTeamID="YZC2T44ZDX"
    ;;
