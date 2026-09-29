logitechoptionsplus)
    name="Logi Options+"
    appName="logioptionsplus.app"
    archiveName="logioptionsplus_installer.zip"
    installerTool="logioptionsplus_installer.app"
    type="zip"
    # lite: Logitech tags its download articles per macOS major and lags new
    # releases (macOS 27 had no articles at launch), so fall back to the newest
    # macOS major that has any.
    osMajorVersion=$(sw_vers -productVersion | awk -F "." '{print$1}')
    for (( logiOS = osMajorVersion; logiOS >= osMajorVersion - 3; logiOS-- )); do
        logiJSON=$(curl -fs "https://support.logi.com/api/v2/help_center/en-us/articles.json?label_names=webcontent=productdownload,webos=mac-macos-x-${logiOS}.0")
        [[ "$logiJSON" == *logioptionsplus*zip* ]] && break
    done
    downloadURL="$(printf "%s" "$logiJSON" | tr "," "\n"  | grep  -o "https://.*logioptionsplus.*zip" | head -1)"
    appNewVersion=$(printf "%s" "$logiJSON" | tr "," "\n" | grep -A 10 "macOS" | grep -B 5 -ie "https.*/.*/optionsplus/.*\.zip" | grep "Software Version" | sed 's/\\u[0-9a-z][0-9a-z][0-9a-z][0-9a-z]//g' | grep -ioe "Software Version.*[0-9.]*" | tr "/" "\n" | grep -oe "[0-9.]*" | head -1)
    CLIInstaller="logioptionsplus_installer.app/Contents/MacOS/logioptionsplus_installer"
    CLIArguments=(--quiet)
    expectedTeamID="QED4VVPZWA"
    ;;
