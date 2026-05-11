lucidlink)
    name="LucidLink"
    # https://www.lucidlink.com/download
    type="pkg"
    downloadURL="https://www.lucidlink.com/download/new-ll-latest/macos/stable/"
    appNewVersion=$( curl -fsIL "${downloadURL}" | grep -i "^location" | tail -1 | awk '{print $2}' | sed -E 's/.*\/[a-zA-Z]*-([0-9.]*)\..*/\1/g' )
    expectedTeamID="Y4KMJPU2B4"
    blockingProcesses=( "LucidLink" )
    ;;
