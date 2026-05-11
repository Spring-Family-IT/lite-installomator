lucidlinkclassic)
    name="Lucid"
    # https://www.lucidlink.com/download#other-platforms-classic
    type="pkg"
    downloadURL="https://www.lucidlink.com/download/latest/osx/stable/"
    appNewVersion=$( curl -fsIL "${downloadURL}" | grep -i "^location" | tail -1 | awk '{print $2}' | sed -E 's/.*\/[a-zA-Z]*-([0-9.]*)\..*/\1/g' )
    expectedTeamID="Y4KMJPU2B4"
    blockingProcesses=( "Lucid" )
    ;;
