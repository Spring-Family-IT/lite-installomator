code42)
    name="Code42"
    type="pkgInDmg"
    if [[ $(arch) == i386 ]]; then
       downloadURL="https://download-preservation.code42.com/installs/agent/latest-mac.dmg"
    elif [[ $(arch) == arm64 ]]; then
       downloadURL="https://download-preservation.code42.com/installs/agent/latest-mac-arm64.dmg"
    fi
    # Redirect resolves to .../agent/cloud/<version>/<build>/install/Code42_<version>_..._Mac<-arm64>.dmg.
    # The path version matches the installed app's CFBundleShortVersionString (com.backup42.desktop).
    appNewVersion=$(curl -fsIL -o /dev/null -w "%{url_effective}" "${downloadURL}" | sed -nE 's@.*/agent/cloud/([0-9.]+)/[0-9]+/install/.*@\1@p')
    expectedTeamID="9YV9435DHD"
    blockingProcesses=( NONE )
    ;;
