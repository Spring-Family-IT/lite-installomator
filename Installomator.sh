#!/bin/zsh --no-rcs
label="" # if no label is sent to the script, this will be used

# lite-installomator
#
# A fork of Installomator (https://github.com/Installomator/Installomator)
# trimmed down to a curated subset of labels.
#
# Downloads and installs Applications
# 2020-2024 Installomator
#
# inspired by the download scripts from William Smith and Sander Schram
#
# Contributors:
#    Armin Briegel - @scriptingosx
#    Isaac Ordonez - @issacatmann
#    Søren Theilgaard - @Theile
#    Adam Codega - @acodega
#    Trevor Sysock - @BigMacAdmin
#    Bart Reardon - @bartreardon
#
# with contributions from many others

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# NOTE: adjust these variables:

# set to 0 for production, 1 or 2 for debugging
# while debugging, items will be downloaded to the parent directory of this script
# also no actual installation will be performed
# debug mode 1 will download to the directory the script is run in, but will not check the version
# debug mode 2 will download to the temp directory, check for blocking processes, check the version, but will not install anything or remove the current version
DEBUG=1

# notify behavior
NOTIFY=success
# options:
#   - success      notify the user on success
#   - silent       no notifications
#   - all          all notifications (great for Self Service installation)

# time in seconds to wait for a prompt to be answered before exiting the script
PROMPT_TIMEOUT=86400
# Common times translated into seconds
# 60    =  1 minute
# 300   =  5 minutes
# 600   = 10 minutes
# 3600  =  1 hour
# 86400 = 24 hours (default)

# behavior when blocking processes are found
# BLOCKING_PROCESS_ACTION is ignored if app label uses updateTool
BLOCKING_PROCESS_ACTION=tell_user
# options:
#   - ignore       continue even when blocking processes are found
#   - quit         app will be told to quit nicely if running
#   - quit_kill    told to quit twice, then it will be killed
#                  Could be great for service apps if they do not respawn
#   - silent_fail  exit script without prompt or installation
#   - prompt_user  show a user dialog for each blocking process found,
#                  user can choose "Quit and Update" or "Not Now".
#                  When "Quit and Update" is chosen, blocking process
#                  will be told to quit. Installomator will wait 30 seconds
#                  before checking again in case Save dialogs etc are being responded to.
#                  Installomator will abort if quitting after three tries does not succeed.
#                  "Not Now" will exit Installomator.
#   - prompt_user_then_kill
#                  show a user dialog for each blocking process found,
#                  user can choose "Quit and Update" or "Not Now".
#                  When "Quit and Update" is chosen, blocking process
#                  will be terminated. Installomator will abort if terminating
#                  after two tries does not succeed. "Not Now" will exit Installomator.
#   - prompt_user_loop
#                  Like prompt-user, but clicking "Not Now", will just wait an hour,
#                  and then it will ask again.
#                  WARNING! It might block the MDM agent on the machine, as
#                  the script will not exit, it will pause until the hour has passed,
#                  possibly blocking for other management actions in this time.
#   - tell_user    User will be showed a notification about the important update,
#                  but user is only allowed to Quit and Continue, and then we
#                  ask the app to quit. This is default.
#   - tell_user_then_kill
#                  User will be showed a notification about the important update,
#                  but user is only allowed to Quit and Continue. If the quitting fails,
#                  the blocking processes will be terminated.
#   - kill         kill process without prompting or giving the user a chance to save


# logo-icon used in dialog boxes if app is blocking
LOGO=appstore
# options:
#   - appstore      Icon is Apple App Store (default)
#   - jamf          JAMF Pro
#   - mosyleb       Mosyle Business
#   - mosylem       Mosyle Manager (Education)
#   - addigy        Addigy
#   - microsoft     Microsoft Endpoint Manager (Intune)
#   - ws1           Workspace ONE (AirWatch)
#   - filewave      FileWave
#   - kandji        Kandji
# path can also be set in the command call, and if file exists, it will be used.
# Like 'LOGO="/System/Applications/App\ Store.app/Contents/Resources/AppIcon.icns"'
# (spaces have to be escaped).


# App Store apps handling
IGNORE_APP_STORE_APPS=no
# options:
#  - no            If the installed app is from App Store (which include VPP installed apps)
#                  it will not be touched, no matter its version (default)
#  - yes           Replace App Store (and VPP) version of the app and handle future
#                  updates using Installomator, even if latest version.
#                  Shouldn’t give any problems for the user in most cases.
#                  Known bad example: Slack will lose all settings.

# Owner of copied apps
SYSTEMOWNER=0
# options:
#  - 0             Current user will be owner of copied apps, just like if they
#                  installed it themselves (default).
#  - 1             root:wheel will be set on the copied app.
#                  Useful for shared machines.

# install behavior
INSTALL=""
# options:
#  -               When not set, the software will only be installed
#                  if it is newer/different in version
#  - force         Install even if it’s the same version


# Re-opening of closed app
REOPEN="yes"
# options:
#  - yes           App will be reopened if it was closed
#  - no            App not reopened

# Only let Installomator return the name of the label
# RETURN_LABEL_NAME=0
# options:
#   - 1      Installomator will return the name of the label and exit, so last line of
#            output will be that name. When Installomator is locally installed and we
#            use DEPNotify, then DEPNotify can present a more nice name to the user,
#            instead of just the label name.


# Interrupt Do Not Disturb (DND) full screen apps
INTERRUPT_DND="yes"
# options:
#  - yes           Script will run without checking for DND full screen apps.
#  - no            Script will exit when an active DND full screen app is detected.

# Comma separated list of app names to ignore when evaluating DND
IGNORE_DND_APPS=""
# example that will ignore browsers when evaluating DND:
# IGNORE_DND_APPS="firefox,Google Chrome,Safari,Microsoft Edge,Opera,Amphetamine,caffeinate"


# Use proxy for network access
PROXY=""
# Use this format for proxy: server.network.dns:port
# Configure proxy settings so that curl can work through that if needed.
# Port number is important for the check of access.
# Please note that some proxy configurations allow text download, but block binary downloads.
# So could be a situation where curl works for version, but not for download.
# This error line is then shown: “curl output was: curl: (22) The requested URL returned error: 403”


# Swift Dialog integration

# These variables will allow Installomator to communicate progress with Swift Dialog
# https://github.com/swiftDialog/swiftDialog

# This requires Swift Dialog 2.11.2 or higher.

DIALOG_CMD_FILE=""
# When this variable is set, Installomator will write Swift Dialog commands to this path.
# Installomator will not launch Swift Dialog. The process calling Installomator will have
# launch and configure Swift Dialog to listen to this file.
# See `MDM/swiftdialog_example.sh` for an example.

DIALOG_LIST_ITEM_NAME=""
# When this variable is set, progress for downloads and installs will be sent to this
# listitem.
# When the variable is unset, progress will be sent to Swift Dialog's main progress bar.

NOTIFY_DIALOG=0
# If this variable is set to 1, then we will check for installed Swift Dialog v. 2 or later, and use that for notification


# NOTE: How labels work

# Each workflow label needs to be listed in the case statement below.
# for each label these variables can be set:
#
# - name: (required)
#   Name of the installed app.
#   This is used to derive many of the other variables.
#
# - type: (required)
#   The type of the installation. Possible values:
#     - dmg
#     - pkg
#     - zip
#     - tbz
#     - pkgInDmg
#     - pkgInZip
#     - appInDmgInZip
#     - updateronly     This last one is for labels that should only run an updateTool (see below)
#
# - packageID: (optional)
#   The package ID of a pkg
#   If given, will be used to find the version of installed software, instead of searching for an app.
#   Usefull if a pkg does not install an app.
#   See label installomator_st
#
# - downloadURL: (required)
#   URL to download the dmg.
#   Can be generated with a series of commands (see BBEdit for an example).
#
# - curlOptions: (array, optional)
#   Options to the curl command, needed for curl to be able to download the software.
#   Usually used for adding extra headers that some servers need in order to serve the file.
#   curlOptions=( -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Safari/605.1.15" )
#   (See “mocha”-labels, for examples on labels, and buildLabel.sh for header-examples.)
#
# - appNewVersion: (optional)
#   Version of the downloaded software.
#   If given, it will be compared to the installed version, to see if the download is different.
#   It does not check for newer or not, only different.
#
# - versionKey: (optional)
#   How we get version number from app. Possible values:
#     - CFBundleShortVersionString
#     - CFBundleVersion
#   Not all software titles uses fields the same.
#   See Opera label.
#
# - appCustomVersion(){}: (optional function)
#   This function can be added to your label, if a specific custom
#   mechanism hs to be used for getting the installed version.
#   See labels zulujdk11, zulujdk13, zulujdk15
#
# - expectedTeamID: (required)
#   10-digit developer team ID.
#   Obtain the team ID by running:
#
#   - Applications (in dmgs or zips)
#     spctl -a -vv /Applications/BBEdit.app
#
#   - Pkgs
#     spctl -a -vv -t install ~/Downloads/desktoppr-0.2.pkg
#
#   The team ID is the ten-digit ID at the end of the line starting with 'origin='
#
# - archiveName: (optional)
#   The name of the downloaded file.
#   When not given the archiveName is derived from the $name.
#   Note: This has to be defined BEFORE calling downloadURLFromGit or
#   versionFromGit functions in the label.
#
# - appName: (optional)
#   File name of the app bundle in the dmg to verify and copy (include .app).
#   When not given, the appName is derived from the $name.
#
# - targetDir: (optional)
#   dmg or zip:
#     Applications will be copied to this directory.
#     Default value is '/Applications' for dmg and zip installations.
#   pkg:
#     targetDir is used as the install-location. Default is '/'.
#
# - blockingProcesses: (optional)
#   Array of process names that will block the installation or update.
#   If no blockingProcesses array is given the default will be:
#     blockingProcesses=( $name )
#   When a package contains multiple applications, _all_ should be listed, e.g:
#     blockingProcesses=( "Keynote" "Pages" "Numbers" )
#   When a workflow has no blocking processes, use
#     blockingProcesses=( NONE )
#
# - pkgName: (optional, only used for pkgInDmg, dmgInZip, and appInDmgInZip)
#   File name or path to the pkg/dmg file _inside_ the dmg or zip.
#   When not given the pkgName is derived from the $name
#
# - updateTool:
# - updateToolArguments:
#   When Installomator detects an existing installation of the application,
#   and the updateTool variable is set
#       $updateTool $updateArguments
#   Will be run instead of of downloading and installing a complete new version.
#   Use this when the updateTool does differential and optimized downloads.
#   e.g. msupdate on various Microsoft labels
#
# - updateToolRunAsCurrentUser:
#   When this variable is set (any value), $updateTool will be run as the current user.
#
# - CLIInstaller:
# - CLIArguments:
#   If the downloaded dmg is an installer that we can call using CLI, we can
#   use these two variables for what to call.
#   We need to define `name` for the installed app (to be version checked), as well as
#   `installerTool` for the installer app (if named differently than `name`. Installomator
#   will add the path to the folder/disk image with the binary, and it will be called like this:
#       $CLIInstaller $CLIArguments
#   For most installations `CLIInstaller` should contain the `installerTool` for the CLI call
#   (if it’s the same).
#   We can support a whole range of other software titles by implementing this.
#   See label adobecreativeclouddesktop
#
# - installerTool:
#   Introduced as part of `CLIInstaller`. If the installer in the DMG or ZIP is named
#   differently than the installed app, then this variable can be used to name the
#   installer that should be located after mounting/expanding the downloaded archive.
#   See label adobecreativeclouddesktop
#
### Logging
# Logging behavior
LOGGING="INFO"
# options:
#   - DEBUG     Everything is logged
#   - INFO      (default) normal logging level
#   - WARN      only warning
#   - ERROR     only errors
#   - REQ       ????

# MDM profile name
MDMProfileName=""
# options:
#   - MDM Profile               Addigy has this name on the profile
#   - Mosyle Corporation MDM    Mosyle uses this name on the profile
# From the LOGO variable we can know if Addigy og Mosyle is used, so if that variable
# is either of these, and this variable is empty, then we will auto detect this.

# Datadog logging used
datadogAPI=""
# Simply add your own API key for this in order to have logs sent to Datadog
# See more here: https://www.datadoghq.com/product/log-management/

# Log Date format used when parsing logs for debugging, this is the default used by
# install.log, override this in the case statements if you need something custom per
# application (See adobeillustrator).  Using stadard GNU Date formatting.
LogDateFormat="%Y-%m-%d %H:%M:%S"

# Get the start time for parsing install.log if we fail.
starttime=$(date "+$LogDateFormat")

# Check if we have rosetta installed
if [[ $(/usr/bin/arch) == "arm64" ]]; then
    if ! arch -x86_64 /usr/bin/true >/dev/null 2>&1; then # pgrep oahd >/dev/null 2>&1
        rosetta2=no
    fi
fi
VERSION="10.11-lite-beta"
VERSIONDATE="2026-05-12"

# MARK: Functions

cleanupAndExit() { # $1 = exit code, $2 message, $3 level
    if [ -n "$dmgmount" ]; then
        # unmount disk image
        printlog "Unmounting $dmgmount" DEBUG
        unmountingOut=$(hdiutil detach "$dmgmount" 2>&1)
        printlog "Debugging enabled, Unmounting output was:\n$unmountingOut" DEBUG
    fi
    if [ "$DEBUG" -ne 1 ]; then
        # remove the temporary working directory when done (only if DEBUG is not used)
        printlog "Deleting $tmpDir" DEBUG
        deleteTmpOut=$(rm -Rfv "$tmpDir")
        printlog "Debugging enabled, Deleting tmpDir output was:\n$deleteTmpOut" DEBUG
    fi

    # If we closed any processes, reopen the app again
    reopenClosedProcess
    if [[ -n $2 && $1 -ne 0 ]]; then
        printlog "ERROR: $2" $3
        updateDialog "fail" "Error ($1; $2)"
    else
        printlog "$2" $3
        updateDialog "success" ""
    fi
    printlog "################## End Installomator, exit code $1 \n" REQ

    # if label is wrong and we wanted name of the label, then return ##################
    if [[ $RETURN_LABEL_NAME -eq 1 ]]; then
        1=0 # If only label name should be returned we exit without any errors
        echo "#"
    fi
    exit "$1"
}

runAsUser() {
    if [[ $currentUser != "loginwindow" ]]; then
        uid=$(id -u "$currentUser")
        launchctl asuser $uid sudo -u $currentUser "$@"
    fi
}

reloadAsUser() {
    if [[ $currentUser != "loginwindow" ]]; then
        uid=$(id -u "$currentUser")
        su - $currentUser -c "${@}"
    fi
}

displaydialog() { # $1: message $2: title
    message=${1:-"Message"}
    title=${2:-"Installomator"}
    runAsUser osascript -e "button returned of (display dialog \"$message\" with  title \"$title\" buttons {\"Not Now\", \"Quit and Update\"} default button \"Quit and Update\" with icon POSIX file \"$LOGO\" giving up after $PROMPT_TIMEOUT)"
}

displaydialogContinue() { # $1: message $2: title
    message=${1:-"Message"}
    title=${2:-"Installomator"}
    runAsUser osascript -e "button returned of (display dialog \"$message\" with  title \"$title\" buttons {\"Quit and Update\"} default button \"Quit and Update\" with icon POSIX file \"$LOGO\")"
}

displaynotification() { # $1: message $2: title
    message=${1:-"Message"}
    title=${2:-"Notification"}
    manageaction="/Library/Application Support/JAMF/bin/Management Action.app/Contents/MacOS/Management Action"
    hubcli="/usr/local/bin/hubcli"
    swiftdialog="/usr/local/bin/dialog"

    if [[ "$($swiftdialog --version | cut -d "." -f1)" -ge 2 && "$NOTIFY_DIALOG" -eq 1 ]]; then
        "$swiftdialog" --notification --title "$title" --message "$message"
    elif [[ -x "$manageaction" ]]; then
         "$manageaction" -message "$message" -title "$title" &
    elif [[ -x "$hubcli" ]]; then
         "$hubcli" notify -t "$title" -i "$message" -c "Dismiss"
    else
        runAsUser osascript -e "display notification \"$message\" with title \"$title\""
    fi
}

printlog(){
    [ -z "$2" ] && 2=INFO
    log_message=$1
    log_priority=$2
    timestamp=$(date +%F\ %T)

    # Check to make sure that the log isn't the same as the last, if it is then don't log and increment a timer.
    if [[ ${log_message} == ${previous_log_message} ]]; then
        let logrepeat=$logrepeat+1
        return
    fi
    previous_log_message=$log_message

    # Extra spaces for log_priority alignment
    space_char=""
    if [[ ${#log_priority} -eq 3 ]]; then
        space_char="  "
    elif [[ ${#log_priority} -eq 4 ]]; then
        space_char=" "
    fi

    # Once we finally stop getting duplicate logs output the number of times we got a duplicate.
    if [[ $logrepeat -gt 1 ]];then
        echo "$timestamp" : "${log_priority}${space_char} : $label : Last Log repeated ${logrepeat} times" | tee -a $log_location

        if [[ ! -z $datadogAPI ]]; then
            curl -s -X POST https://http-intake.logs.datadoghq.com/v1/input -H "Content-Type: text/plain" -H "DD-API-KEY: $datadogAPI" -d "${log_priority} : $mdmURL : $APPLICATION : $VERSION : $SESSION : Last Log repeated ${logrepeat} times" > /dev/null
        fi
        logrepeat=0
    fi

    # If the datadogAPI key value is set and our logging level is greater than or equal to our set level
    # then post to Datadog's HTTPs endpoint.
    if [[ -n $datadogAPI && ${levels[$log_priority]} -ge ${levels[$datadogLoggingLevel]} ]]; then
        while IFS= read -r logmessage; do
            curl -s -X POST https://http-intake.logs.datadoghq.com/v1/input -H "Content-Type: text/plain" -H "DD-API-KEY: $datadogAPI" -d "${log_priority} : $mdmURL : Installomator-${label} : ${VERSIONDATE//-/} : $SESSION : ${logmessage}" > /dev/null
        done <<< "$log_message"
    fi

    # If our logging level is greaterthan or equal to our set level then output locally.
    if [[ ${levels[$log_priority]} -ge ${levels[$LOGGING]} ]]; then
        while IFS= read -r logmessage; do
            if [[ "$(whoami)" == "root" ]]; then
                echo "$timestamp" : "${log_priority}${space_char} : $label : ${logmessage}" | tee -a $log_location
            else
                echo "$timestamp" : "${log_priority}${space_char} : $label : ${logmessage}"
            fi
        done <<< "$log_message"
    fi
}

# Used to remove dupplicate lines in large log output,
# for example from msupdate command after it finishes running.
deduplicatelogs() {
    loginput=${1:-"Log"}
    logoutput=""
    # Read each line of the incoming log individually, match it with the previous.
    # If it matches increment logrepeate then skip to the next line.
    while read log; do
        if [[ $log == $previous_log ]];then
            let logrepeat=$logrepeat+1
            continue
        fi

        previous_log="$log"
        if [[ $logrepeat -gt 1 ]];then
            logoutput+="Last Log repeated ${logrepeat} times\n"
            logrepeat=0
        fi

        logoutput+="$log\n"
    done <<< "$loginput"
}

# will get the latest release download from a github repo
downloadURLFromGit() { # $1 git user name, $2 git repo name
    gitusername=${1?:"no git user name"}
    gitreponame=${2?:"no git repo name"}

    if [[ $type == "pkgInDmg" ]]; then
        filetype="dmg"
    elif [[ $type == "pkgInZip" ]]; then
        filetype="zip"
    else
        filetype=$type
    fi

    if [ -n "$archiveName" ]; then
        downloadURL=$(curl -sfL "https://api.github.com/repos/$gitusername/$gitreponame/releases/latest" | awk -F '"' "/browser_download_url/ && /$archiveName\"/ { print \$4; exit }")
        if [[ "$(echo $downloadURL | grep -ioE "https.*$archiveName")" == "" ]]; then
            #downloadURL=https://github.com$(curl -sfL "https://github.com/$gitusername/$gitreponame/releases/latest" | tr '"' "\n" | grep -i "^/.*\/releases\/download\/.*$archiveName" | head -1)
            downloadURL="https://github.com$(curl -sfL "$(curl -sfL "https://github.com/$gitusername/$gitreponame/releases/latest" | tr '"' "\n" | grep -i "expanded_assets" | head -1)" | tr '"' "\n" | grep -i "^/.*\/releases\/download\/.*$archiveName" | head -1)"
        fi
    else
        downloadURL=$(curl -sfL "https://api.github.com/repos/$gitusername/$gitreponame/releases/latest" | awk -F '"' "/browser_download_url/ && /$filetype\"/ { print \$4; exit }")
        if [[ "$(echo $downloadURL | grep -ioE "https.*.$filetype")" == "" ]]; then
            #downloadURL=https://github.com$(curl -sfL "https://github.com/$gitusername/$gitreponame/releases/latest" | tr '"' "\n" | grep -i "^/.*\/releases\/download\/.*\.$filetype" | head -1)
            downloadURL="https://github.com$(curl -sfL "$(curl -sfL "https://github.com/$gitusername/$gitreponame/releases/latest" | tr '"' "\n" | grep -i "expanded_assets" | head -1)" | tr '"' "\n" | grep -i "^/.*\/releases\/download\/.*\.$filetype" | head -1)"
        fi
    fi
    if [ -z "$downloadURL" ]; then
        cleanupAndExit 14 "could not retrieve download URL for $gitusername/$gitreponame" ERROR
    else
        echo "$downloadURL"
        return 0
    fi
}

versionFromGit() {
    # credit: Søren Theilgaard (@theilgaard)
    # $1 git user name, $2 git repo name
    gitusername=${1?:"no git user name"}
    gitreponame=${2?:"no git repo name"}

    #appNewVersion=$(curl -L --silent --fail "https://api.github.com/repos/$gitusername/$gitreponame/releases/latest" | grep tag_name | cut -d '"' -f 4 | sed 's/[^0-9\.]//g')
    appNewVersion=$(curl -sLI "https://github.com/$gitusername/$gitreponame/releases/latest" | grep -i "^location" | tr "/" "\n" | tail -1 | sed 's/[^0-9\.]//g')
    if [ -z "$appNewVersion" ]; then
        printlog "could not retrieve version number for $gitusername/$gitreponame" WARN
        appNewVersion=""
    else
        echo "$appNewVersion"
        return 0
    fi
}


# Handling of differences in xpath between Catalina and Big Sur
xpath() {
	# the xpath tool changes in Big Sur and now requires the `-e` option
	if [[ $(sw_vers -buildVersion) > "20A" ]]; then
		/usr/bin/xpath -q -e $@
		# alternative: switch to xmllint (which is not perl)
		#xmllint --xpath $@ -
	else
		/usr/bin/xpath -q $@
	fi
}

# from @Pico: https://macadmins.slack.com/archives/CGXNNJXJ9/p1652222365989229?thread_ts=1651786411.413349&cid=CGXNNJXJ9
getJSONValue() {
	# $1: JSON string OR file path to parse (tested to work with up to 1GB string and 2GB file).
	# $2: JSON key path to look up (using dot or bracket notation).
	printf '%s' "$1" | /usr/bin/osascript -l 'JavaScript' \
		-e "let json = $.NSString.alloc.initWithDataEncoding($.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile$(/usr/bin/uname -r | /usr/bin/awk -F '.' '($1 > 18) { print "AndReturnError(ObjC.wrap())" }'), $.NSUTF8StringEncoding)" \
		-e 'if ($.NSFileManager.defaultManager.fileExistsAtPath(json)) json = $.NSString.stringWithContentsOfFileEncodingError(json, $.NSUTF8StringEncoding, ObjC.wrap())' \
		-e "const value = JSON.parse(json.js)$([ -n "${2%%[.[]*}" ] && echo '.')$2" \
		-e 'if (typeof value === "object") { JSON.stringify(value, null, 4) } else { value }'
}

getAppVersion() {
    # modified by: Søren Theilgaard (@theilgaard) and Isaac Ordonez

    # If label contain function appCustomVersion, we use that and return
    if type 'appCustomVersion' 2>/dev/null | grep -q 'function'; then
        appversion=$(appCustomVersion)
        printlog "Custom App Version detection is used, found $appversion"
        return
    fi

    # pkgs contains a version number, then we don't have to search for an app
    if [[ $packageID != "" ]]; then
        appversion="$(pkgutil --pkg-info-plist ${packageID} 2>/dev/null | grep -A 1 pkg-version | tail -1 | sed -E 's/.*>([0-9.]*)<.*/\1/g')"
        if [[ $appversion != "" ]]; then
            printlog "found packageID $packageID installed, version $appversion"
            updateDetected="YES"
            return
        else
            printlog "No version found using packageID $packageID"
        fi
    fi

    # get app in targetDir, /Applications, or /Applications/Utilities
    if [[ -d "$targetDir/$appName" ]]; then
        applist="$targetDir/$appName"
    elif [[ -d "/Applications/$appName" ]]; then
        applist="/Applications/$appName"
#        if [[ $type =~ '^(dmg|zip|tbz|app.*)$' ]]; then
#            targetDir="/Applications"
#        fi
    elif [[ -d "/Applications/Utilities/$appName" ]]; then
        applist="/Applications/Utilities/$appName"
#        if [[ $type =~ '^(dmg|zip|tbz|app.*)$' ]]; then
#            targetDir="/Applications/Utilities"
#        fi
    else
        printlog "name: $name, appName: $appName"
        # mdfind now handling if kind is either Application or App
        applist=$(mdfind "kMDItemContentType:com.apple.application AND kMDItemFSName:\"$name\"" -0 2>/dev/null)
#        applist=$(mdfind "kMDItemContentType:com.apple.application AND kMDItemFSName:\"$appName\"" -0 2>/dev/null)
#        printlog "App(s) found: ${applist}" DEBUG
    fi
    if [[ -z $applist ]]; then
        printlog "No previous app found" WARN
    else
        printlog "App(s) found: ${applist}" INFO
    fi
#    if [[ $type =~ '^(dmg|zip|tbz|app.*)$' ]]; then
#        printlog "targetDir for installation: $targetDir" INFO
#    fi

    appPathArray=( ${(0)applist} )

    if [[ ${#appPathArray} -gt 0 ]]; then
        filteredAppPaths=( ${(M)appPathArray:#${targetDir}*} )
        if [[ ${#filteredAppPaths} -eq 1 ]]; then
            installedAppPath=$filteredAppPaths[1]
            #appversion=$(mdls -name kMDItemVersion -raw $installedAppPath )
            appversion=$(defaults read $installedAppPath/Contents/Info.plist $versionKey) #Not dependant on Spotlight indexing
            printlog "found app at $installedAppPath, version $appversion, on versionKey $versionKey"
            updateDetected="YES"
            # Is current app from App Store
            if [[ -d "$installedAppPath"/Contents/_MASReceipt ]];then
                printlog "Installed $appName is from App Store, use “IGNORE_APP_STORE_APPS=yes” to replace."
                if [[ $IGNORE_APP_STORE_APPS == "yes" ]]; then
                    printlog "Replacing App Store apps, no matter the version" WARN
                    appversion=0
                else
                    if [[ $DIALOG_CMD_FILE != "" ]]; then
                        updateDialog "wait" "Already installed from App Store. Not replaced."
                        sleep 4
                    fi
                    cleanupAndExit 23 "App previously installed from App Store, and we respect that" ERROR
                fi
            fi
        else
            printlog "could not determine location of $appName" WARN
        fi
    else
        printlog "could not find $appName" WARN
    fi
}

checkRunningProcesses() {
    # don't check in DEBUG mode 1
    if [[ $DEBUG -eq 1 ]]; then
        printlog "DEBUG mode 1, not checking for blocking processes" DEBUG
        return
    fi

    # try at most 3 times
    for i in {1..4}; do
        countedProcesses=0
        for x in ${blockingProcesses}; do
            if pgrep -xq "$x"; then
                printlog "found blocking process $x"
                appClosed=1

                case $BLOCKING_PROCESS_ACTION in
                    quit|quit_kill)
                        printlog "telling app $x to quit"
                        runAsUser osascript -e "tell app \"$x\" to quit"
                        if [[ $i > 2 && $BLOCKING_PROCESS_ACTION = "quit_kill" ]]; then
                          printlog "Changing BLOCKING_PROCESS_ACTION to kill"
                          BLOCKING_PROCESS_ACTION=kill
                        else
                            # give the user a bit of time to quit apps
                            printlog "waiting 30 seconds for processes to quit"
                            sleep 30
                        fi
                        ;;
                    kill)
                      printlog "killing process $x"
                      pkill $x
                      sleep 5
                      ;;
                    prompt_user|prompt_user_then_kill)
                      button=$(displaydialog "Quit “$x” to continue updating? $([[ -n $appNewVersion ]] && echo "Version $appversion is installed, but version $appNewVersion is available.") (Leave this dialogue if you want to activate this update later)." "The application “$x” needs to be updated.")
                      if [[ $button = "Not Now" ]]; then
                        appClosed=0
                        cleanupAndExit 10 "user aborted update" ERROR
                      elif [[ $button = "" ]]; then
                        appClosed=0
                        cleanupAndExit 25 "timed out waiting for user response" ERROR
                      else
                        if [[ $BLOCKING_PROCESS_ACTION = "prompt_user_then_kill" ]]; then
                          # try to quit, then set to kill
                          printlog "telling app $x to quit"
                          runAsUser osascript -e "tell app \"$x\" to quit"
                          # give the user a bit of time to quit apps
                          printlog "waiting 30 seconds for processes to quit"
                          sleep 30
                          printlog "Changing BLOCKING_PROCESS_ACTION to kill"
                          BLOCKING_PROCESS_ACTION=kill
                        else
                          printlog "telling app $x to quit"
                          runAsUser osascript -e "tell app \"$x\" to quit"
                          # give the user a bit of time to quit apps
                          printlog "waiting 30 seconds for processes to quit"
                          sleep 30
                        fi
                      fi
                      ;;
                    prompt_user_loop)
                      button=$(displaydialog "Quit “$x” to continue updating? $([[ -n $appNewVersion ]] && echo "Version $appversion is installed, but version $appNewVersion is available.") (Click “Not Now” to be asked in 1 hour, or leave this open until you are ready)." "The application “$x” needs to be updated.")
                      if [[ $button = "Not Now" ]]; then
                        if [[ $i < 2 ]]; then
                          printlog "user wants to wait an hour"
                          sleep 3600 # 3600 seconds is an hour
                        else
                          printlog "change of BLOCKING_PROCESS_ACTION to tell_user"
                          BLOCKING_PROCESS_ACTION=tell_user
                        fi
                      else
                        printlog "telling app $x to quit"
                        runAsUser osascript -e "tell app \"$x\" to quit"
                        # give the user a bit of time to quit apps
                        printlog "waiting 30 seconds for processes to quit"
                        sleep 30
                      fi
                      ;;
                    tell_user|tell_user_then_kill)
                      button=$(displaydialogContinue "Quit “$x” to continue updating? (This is an important update). Wait for notification of update before launching app again." "The application “$x” needs to be updated.")
                      printlog "telling app $x to quit"
                      runAsUser osascript -e "tell app \"$x\" to quit"
                      # give the user a bit of time to quit apps
                      printlog "waiting 30 seconds for processes to quit"
                      sleep 30
                      if [[ $i > 1 && $BLOCKING_PROCESS_ACTION = tell_user_then_kill ]]; then
                          printlog "Changing BLOCKING_PROCESS_ACTION to kill"
                          BLOCKING_PROCESS_ACTION=kill
                      fi
                      ;;
                    silent_fail)
                      appClosed=0
                      cleanupAndExit 12 "blocking process '$x' found, aborting" ERROR
                      ;;
                esac

                countedProcesses=$((countedProcesses + 1))
            fi
        done

    done

    if [[ $countedProcesses -ne 0 ]]; then
        cleanupAndExit 11 "could not quit all processes, aborting..." ERROR
    fi

    printlog "no more blocking processes, continue with update" REQ
}

reopenClosedProcess() {
    # If Installomator closed any processes, let's get the app opened again
    # credit: Søren Theilgaard (@theilgaard)

    # don't reopen if REOPEN is not "yes"
    if [[ $REOPEN != yes ]]; then
        printlog "REOPEN=no, not reopening anything"
        return
    fi

    # don't reopen in DEBUG mode 1
    if [[ $DEBUG -eq 1 ]]; then
        printlog "DEBUG mode 1, not reopening anything" DEBUG
        return
    fi

    if [[ $appClosed == 1 ]]; then
        printlog "Telling app $appName to open"
        #runAsUser osascript -e "tell app \"$appName\" to open"
        #runAsUser open -a "${appName}"
        reloadAsUser "open -a \"${appName}\""
        #reloadAsUser "open \"${(0)applist}\""
        processuser=$(ps aux | grep -i "${appName}" | grep -vi "grep" | awk '{print $1}')
        printlog "Reopened ${appName} as $processuser"
    else
        printlog "Installomator did not close any apps, so no need to reopen any apps." INFO
    fi
}

installAppWithPath() { # $1: path to app to install in $targetDir $2: path to folder (with app inside) to copy to $targetDir
    # modified by: Søren Theilgaard (@theilgaard)
    appPath=${1?:"no path to app"}
    # If $2 ends in "/" then a folderName has not been specified so don't set it.
    if [[ ! "${2}" == */ ]]; then
        folderPath="${2}"
    fi

    # check if app exists
    if [ ! -e "$appPath" ]; then
        cleanupAndExit 8 "could not find: $appPath" ERROR
    fi

    # check if folder path exists if it is set
    if [[ -n "$folderPath" ]] && [[ ! -e "$folderPath" ]]; then
        cleanupAndExit 8 "could not find folder: $folderPath" ERROR
    fi

    # verify with spctl
    printlog "Verifying: $appPath" INFO
    updateDialog "wait" "Verifying..."
    printlog "App size: $(du -sh "$appPath")" DEBUG
    appVerify=$(spctl -a -vv "$appPath" 2>&1 )
    appVerifyStatus=$(echo $?)
    teamID=$(echo $appVerify | awk '/origin=/ {print $NF }' | tr -d '()' )
    deduplicatelogs "$appVerify"

    if [[ $appVerifyStatus -ne 0 ]] ; then
    #if ! teamID=$(spctl -a -vv "$appPath" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()' ); then
        cleanupAndExit 4 "Error verifying $appPath error:\n$logoutput" ERROR
    fi
    printlog "Debugging enabled, App Verification output was:\n$logoutput" DEBUG
    printlog "Team ID matching: $teamID (expected: $expectedTeamID )" INFO

    if [ "$expectedTeamID" != "$teamID" ]; then
        cleanupAndExit 5 "Team IDs do not match" ERROR
    fi

    # app versioncheck
    appNewVersion=$(defaults read $appPath/Contents/Info.plist $versionKey)
    if [[ -n $appNewVersion && $appversion == $appNewVersion ]]; then
        printlog "Downloaded version of $name is $appNewVersion on versionKey $versionKey, same as installed."
        if [[ $INSTALL != "force" ]]; then
            message="$name, version $appNewVersion, is the latest version."
            if [[ $currentUser != "loginwindow" && $NOTIFY == "all" ]]; then
                printlog "notifying"
                displaynotification "$message" "No update for $name!"
            fi
            if [[ $DIALOG_CMD_FILE != "" ]]; then
                updateDialog "wait" "Latest version already installed..."
                sleep 2
            fi
            cleanupAndExit 0 "No new version to install" REG
        else
            printlog "Using force to install anyway."
        fi
    elif [[ -z $appversion ]]; then
        printlog "Installing $name version $appNewVersion on versionKey $versionKey."
    else
        printlog "Downloaded version of $name is $appNewVersion on versionKey $versionKey (replacing version $appversion)."
    fi

    # macOS versioncheck
    minimumOSversion=$(defaults read $appPath/Contents/Info.plist LSMinimumSystemVersion 2>/dev/null )
    if [[ -n $minimumOSversion && $minimumOSversion =~ '[0-9.]*' ]]; then
        printlog "App has LSMinimumSystemVersion: $minimumOSversion"
        if ! is-at-least $minimumOSversion $installedOSversion; then
            printlog "App requires higher System Version than installed: $installedOSversion"
            message="Cannot install $name, version $appNewVersion, as it is not compatible with the running system version."
            if [[ $currentUser != "loginwindow" && $NOTIFY == "all" ]]; then
                printlog "notifying"
                displaynotification "$message" "Error updating $name!"
            fi
            cleanupAndExit 15 "Installed macOS is too old for this app." ERROR
        fi
    fi

    # skip install for DEBUG 1
    if [ "$DEBUG" -eq 1 ]; then
        printlog "DEBUG mode 1 enabled, skipping remove, copy and chown steps" DEBUG
        return 0
    fi

    # skip install for DEBUG 2
    if [ "$DEBUG" -eq 2 ]; then
        printlog "DEBUG mode 2 enabled, not installing anything, exiting" DEBUG
        cleanupAndExit 0
    fi

    # Test if variable CLIInstaller is set
    if [[ -z $CLIInstaller ]]; then

        # remove existing application
        if [ -e "$targetDir/$appName" ]; then
            printlog "Removing existing $targetDir/$appName" WARN
            deleteAppOut=$(rm -Rfv "$targetDir/$appName" 2>&1)
            tempName="$targetDir/$appName"
            tempNameLength=$((${#tempName} + 10))
            deleteAppOut=$(echo $deleteAppOut | cut -c 1-$tempNameLength)
            deduplicatelogs "$deleteAppOut"
            printlog "Debugging enabled, App removing output was:\n$logoutput" DEBUG
        fi

        # copy app to /Applications
        printlog "Copy $appPath to $targetDir"
        if [[ -n $folderPath ]]; then
            copyAppOut=$(ditto -v "$folderPath" "$targetDir/$folderName" 2>&1)
        else
            copyAppOut=$(ditto -v "$appPath" "$targetDir/$appName" 2>&1)
        fi
        copyAppStatus=$(echo $?)
        deduplicatelogs "$copyAppOut"
        printlog "Debugging enabled, App copy output was:\n$logoutput" DEBUG
        if [[ $copyAppStatus -ne 0 ]] ; then
        #if ! ditto "$appPath" "$targetDir/$appName"; then
            cleanupAndExit 7 "Error while copying:\n$logoutput" ERROR
        fi

        # set ownership to current user
        if [[ "$currentUser" != "loginwindow" && $SYSTEMOWNER -ne 1 ]]; then
            printlog "Changing owner to $currentUser" WARN
            chown -R "$currentUser" "$targetDir/$appName"
        else
            printlog "No user logged in or SYSTEMOWNER=1, setting owner to root:wheel" WARN
            chown -R root:wheel "$targetDir/$appName"
        fi

    elif [[ ! -z $CLIInstaller ]]; then
        mountname=$(dirname $appPath)
        printlog "CLIInstaller exists, running installer command $mountname/$CLIInstaller $CLIArguments" INFO

        CLIoutput=$("$mountname/$CLIInstaller" "${CLIArguments[@]}" 2>&1)
        CLIstatus=$(echo $?)
        deduplicatelogs "$CLIoutput"

        if [ $CLIstatus -ne 0 ] ; then
            cleanupAndExit 16 "Error installing $mountname/$CLIInstaller $CLIArguments error:\n$logoutput" ERROR
        else
            printlog "Succesfully ran $mountname/$CLIInstaller $CLIArguments" INFO
        fi
        printlog "Debugging enabled, update tool output was:\n$logoutput" DEBUG
    fi

}

mountDMG() {
    # mount the dmg
    printlog "Mounting $tmpDir/$archiveName"
    # always pipe 'Y\n' in case the dmg requires an agreement
    dmgmountOut=$(echo 'Y'$'\n' | hdiutil attach "$tmpDir/$archiveName" -nobrowse -readonly )
    dmgmountStatus=$(echo $?)
    dmgmount=$(echo $dmgmountOut | tail -n 1 | cut -c 54- )
    deduplicatelogs "$dmgmountOut"

    if [[ $dmgmountStatus -ne 0 ]] ; then
    #if ! dmgmount=$(echo 'Y'$'\n' | hdiutil attach "$tmpDir/$archiveName" -nobrowse -readonly | tail -n 1 | cut -c 54- ); then
        cleanupAndExit 3 "Error mounting $tmpDir/$archiveName error:\n$logoutput" ERROR
    fi
    if [[ ! -e $dmgmount ]]; then
        cleanupAndExit 3 "Error accessing mountpoint for $tmpDir/$archiveName error:\n$logoutput" ERROR
    fi
    printlog "Debugging enabled, dmgmount output was:\n$logoutput" DEBUG

    printlog "Mounted: $dmgmount" INFO
}

installFromDMG() {
    mountDMG
    installAppWithPath "$dmgmount/$appName" "$dmgmount/$folderName"
}

installFromPKG() {
    # verify with spctl
    printlog "Verifying: $archiveName"
    updateDialog "wait" "Verifying..."
    printlog "File list: $(ls -lh "$archiveName")" DEBUG
    printlog "File type: $(file "$archiveName")" DEBUG
    spctlOut=$(spctl -a -vv -t install "$archiveName" 2>&1 )
    spctlStatus=$(echo $?)
    printlog "spctlOut is $spctlOut" DEBUG

    teamID=$(echo $spctlOut | awk -F '(' '/origin=/ {print $2 }' | tr -d '()' )
    # Apple signed software has no teamID, grab entire origin instead
    if [[ -z $teamID ]]; then
        teamID=$(echo $spctlOut | awk -F '=' '/origin=/ {print $NF }')
    fi

    deduplicatelogs "$spctlOut"

    if [[ $spctlStatus -ne 0 ]] ; then
    #if ! spctlout=$(spctl -a -vv -t install "$archiveName" 2>&1 ); then
        cleanupAndExit 4 "Error verifying $archiveName error:\n$logoutput" ERROR
    fi

    # Apple signed software has no teamID, grab entire origin instead
    if [[ -z $teamID ]]; then
        teamID=$(echo $spctlout | awk -F '=' '/origin=/ {print $NF }')
    fi

    printlog "Team ID: $teamID (expected: $expectedTeamID )"

    if [ "$expectedTeamID" != "$teamID" ]; then
        cleanupAndExit 5 "Team IDs do not match!" ERROR
    fi

    # Check version of pkg to be installed if packageID is set
    if [[ $packageID != "" && $appversion != "" ]]; then
        printlog "Checking package version."
        baseArchiveName=$(basename $archiveName)
        expandedPkg="$tmpDir/${baseArchiveName}_pkg"
        pkgutil --expand "$archiveName" "$expandedPkg"
        appNewVersion=$(cat "$expandedPkg"/Distribution | xpath "string(//installer-gui-script/pkg-ref[@id='$packageID'][@version]/@version)" 2>/dev/null )
        rm -r "$expandedPkg"
        printlog "Downloaded package $packageID version $appNewVersion"
        if [[ $appversion == $appNewVersion ]]; then
            printlog "Downloaded version of $name is the same as installed."
            if [[ $INSTALL != "force" ]]; then
                message="$name, version $appNewVersion, is the latest version."
                if [[ $currentUser != "loginwindow" && $NOTIFY == "all" ]]; then
                    printlog "notifying"
                    displaynotification "$message" "No update for $name!"
                fi
                if [[ $DIALOG_CMD_FILE != "" ]]; then
                    updateDialog "wait" "Latest version already installed..."
                    sleep 2
                fi
                cleanupAndExit 0 "No new version to install" REQ
            else
                printlog "Using force to install anyway."
            fi
        fi
    fi

    # skip install for DEBUG 1
    if [ "$DEBUG" -eq 1 ]; then
        printlog "DEBUG enabled, skipping installation" DEBUG
        return 0
    fi

    # skip install for DEBUG 2
    if [ "$DEBUG" -eq 2 ]; then
        cleanupAndExit 0 "DEBUG mode 2 enabled, exiting" DEBUG
    fi

    # install pkg
    printlog "Installing $archiveName to $targetDir"

    if [[ $DIALOG_CMD_FILE != "" ]]; then
        # pipe
        pipe="$tmpDir/installpipe"
        # initialise named pipe for installer output
        initNamedPipe create $pipe

        # run the pipe read in the background
        readPKGInstallPipe $pipe "$DIALOG_CMD_FILE" & installPipePID=$!
        printlog "listening to output of installer with pipe $pipe and command file $DIALOG_CMD_FILE on PID $installPipePID" DEBUG

        pkgInstall=$(installer -verboseR -pkg "$archiveName" -tgt "$targetDir" 2>&1 | tee $pipe)
        pkgInstallStatus=$pipestatus[1]
            # because we are tee-ing the output, we want the pipe status of the first command in the chain, not the most recent one
        killProcess $installPipePID

    else
        pkgInstall=$(installer -verbose -dumplog -pkg "$archiveName" -tgt "$targetDir" 2>&1)
        pkgInstallStatus=$(echo $?)
    fi



    sleep 1
    pkgEndTime=$(date "+$LogDateFormat")
    pkgInstall+=$(echo "\nOutput of /var/log/install.log below this line.\n")
    pkgInstall+=$(echo "----------------------------------------------------------\n")
    pkgInstall+=$(awk -v "b=$starttime" -v "e=$pkgEndTime" -F ',' '$1 >= b && $1 <= e' /var/log/install.log)
    deduplicatelogs "$pkgInstall"

    if [[ $pkgInstallStatus -ne 0 ]] && [[ $logoutput == *"requires Rosetta 2"* ]] && [[ $rosetta2 == no ]]; then
        printlog "Package requires Rosetta 2, Installing Rosetta 2 and Installing Package" INFO
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license
        rosetta2=yes
        installFromPKG
    fi

    if [[ $pkginstallstatus -ne 0 ]] ; then
    #if ! installer -pkg "$archiveName" -tgt "$targetDir" ; then
        cleanupAndExit 9 "Error installing $archiveName error:\n$logoutput" ERROR
    fi
    printlog "Debugging enabled, installer output was:\n$logoutput" DEBUG
}

installFromZIP() {
    # unzip the archive
    printlog "Unzipping $archiveName"

    # tar -xf "$archiveName"

    # note: when you expand a zip using tar in Mojave the expanded
    # app will never pass the spctl check

    # unzip -o -qq "$archiveName"

    # note: githubdesktop fails spctl verification when expanded
    # with unzip

    ditto -x -k "$archiveName" "$tmpDir"
    installAppWithPath "$tmpDir/$appName"
}

installFromTBZ() {
    # unzip the archive
    printlog "Unzipping $archiveName"
    tar -xf "$archiveName"
    installAppWithPath "$tmpDir/$appName"
}

installPkgInDmg() {
    mountDMG
    # locate pkg in dmg
    if [[ -z $pkgName ]]; then
        # find first file ending with 'pkg'
        findfiles=$(find "$dmgmount" -iname "*.pkg" -type f -maxdepth 1  )
        printlog "Found pkg(s):\n$findfiles" DEBUG
        filearray=( ${(f)findfiles} )
        if [[ ${#filearray} -eq 0 ]]; then
            cleanupAndExit 20 "couldn't find pkg in dmg $archiveName" ERROR
        fi
        archiveName="${filearray[1]}"
    else
        if [[ -s "$dmgmount/$pkgName" ]] ; then # was: $tmpDir
            archiveName="$dmgmount/$pkgName"
        else
            # try searching for pkg
            findfiles=$(find "$dmgmount" -iname "$pkgName") # was: $tmpDir
            printlog "Found pkg(s):\n$findfiles" DEBUG
            filearray=( ${(f)findfiles} )
            if [[ ${#filearray} -eq 0 ]]; then
                cleanupAndExit 20 "couldn't find pkg “$pkgName” in dmg $archiveName" ERROR
            fi
            # it is now safe to overwrite archiveName for installFromPKG
            archiveName="${filearray[1]}"
        fi
    fi
    printlog "found pkg: $archiveName"

    # installFromPkgs
    installFromPKG
}

installPkgInZip() {
    # unzip the archive
    printlog "Unzipping $archiveName"
    tar -xf "$archiveName"

    # locate pkg in zip
    if [[ -z $pkgName ]]; then
        # find first file ending with 'pkg'
        findfiles=$(find "$tmpDir" -iname "*.pkg" -type f -maxdepth 2  )
        printlog "Found pkg(s):\n$findfiles" DEBUG
        filearray=( ${(f)findfiles} )
        if [[ ${#filearray} -eq 0 ]]; then
            cleanupAndExit 21 "couldn't find pkg in zip $archiveName" ERROR
        fi
        # it is now safe to overwrite archiveName for installFromPKG
        archiveName="${filearray[1]}"
        printlog "found pkg: $archiveName"
    else
        if [[ -s "$tmpDir/$pkgName" ]]; then
            archiveName="$tmpDir/$pkgName"
        else
            # try searching for pkg
            findfiles=$(find "$tmpDir" -iname "$pkgName")
            filearray=( ${(f)findfiles} )
            if [[ ${#filearray} -eq 0 ]]; then
                cleanupAndExit 21 "couldn't find pkg “$pkgName” in zip $archiveName" ERROR
            fi
            # it is now safe to overwrite archiveName for installFromPKG
            archiveName="${filearray[1]}"
            printlog "found pkg: $archiveName"
        fi
    fi

    # installFromPkgs
    installFromPKG
}

installAppInDmgInZip() {
    # unzip the archive
    printlog "Unzipping $archiveName"
    tar -xf "$archiveName"

    # locate dmg in zip
    if [[ -z $pkgName ]]; then
        # find first file ending with 'dmg'
        findfiles=$(find "$tmpDir" -iname "*.dmg" -maxdepth 2  )
        filearray=( ${(f)findfiles} )
        if [[ ${#filearray} -eq 0 ]]; then
            cleanupAndExit 22 "couldn't find dmg in zip $archiveName" ERROR
        fi
        archiveName="$(basename ${filearray[1]})"
        # it is now safe to overwrite archiveName for installFromDMG
        printlog "found dmg: $tmpDir/$archiveName"
    else
        # it is now safe to overwrite archiveName for installFromDMG
        archiveName="$pkgName"
    fi

    # installFromDMG, DMG expected to include an app (will not work with pkg)
    installFromDMG
}

runUpdateTool() {
    printlog "Function called: runUpdateTool"
    if [[ -x $updateTool ]]; then
        printlog "running $updateTool $updateToolArguments"
        if [[ -n $updateToolRunAsCurrentUser ]]; then
            updateOutput=$(runAsUser $updateTool ${updateToolArguments} 2>&1)
            updateStatus=$(echo $?)
        else
            updateOutput=$($updateTool ${updateToolArguments} 2>&1)
            updateStatus=$(echo $?)
        fi
        sleep 1
        updateEndTime=$(date "+$updateToolLogDateFormat")
        deduplicatelogs $updateOutput
        if [[ -n $updateToolLog ]]; then
            updateOutput+=$(echo "Output of Installer log of $updateToolLog below this line.\n")
            updateOutput+=$(echo "----------------------------------------------------------\n")
            updateOutput+=$(awk -v "b=$updatestarttime" -v "e=$updateEndTime" -F ',' '$1 >= b && $1 <= e' $updateToolLog)
        fi

        if [[ $updateStatus -ne 0 ]]; then
            printlog "Error running $updateTool, Procceding with normal installation. Exit Status: $updateStatus Error:\n$logoutput" WARN
            return 1
            if [[ $type == updateronly ]]; then
                cleanupAndExit 77 "No Download URL Set, this is an update only application and the updater failed" ERROR
            fi
        elif [[ $updateStatus -eq 0 ]]; then
            printlog "Debugging enabled, update tool output was:\n$logoutput" DEBUG
        fi
    else
        printlog "couldn't find $updateTool, continuing normally" WARN
        return 1
    fi
    return 0
}

finishing() {
    printlog "Finishing..."

    sleep 3 # wait a moment to let spotlight catch up
    getAppVersion

    if [[ -z $appNewVersion ]]; then
        message="Installed $name"
    else
        message="Installed $name, version $appNewVersion"
    fi

    printlog "$message" REQ

    if [[ $currentUser != "loginwindow" && ( $NOTIFY == "success" || $NOTIFY == "all" ) ]]; then
        printlog "notifying"
        if [[ $updateDetected == "YES" ]]; then
            displaynotification "$message" "$name update complete!"
        else
            displaynotification "$message" "$name installation complete!"
        fi
    fi
}

# Detect if there is an app actively making a display sleep assertion, e.g.
# KeyNote, PowerPoint, Zoom, or Webex.
# See: https://developer.apple.com/documentation/iokit/iopmlib_h/iopmassertiontypes
hasDisplaySleepAssertion() {
    # Get the names of all apps with active display sleep assertions
    local apps="$(/usr/bin/pmset -g assertions | /usr/bin/awk '/NoDisplaySleepAssertion | PreventUserIdleDisplaySleep/ && match($0,/\(.+\)/) && ! /coreaudiod/ {gsub(/^.*\(/,"",$0); gsub(/\).*$/,"",$0); print};')"

    if [[ ! "${apps}" ]]; then
        # No display sleep assertions detected
        return 1
    fi

    # Create an array of apps that need to be ignored
    local ignore_array=("${(@s/,/)IGNORE_DND_APPS}")

    for app in ${(f)apps}; do
        if (( ! ${ignore_array[(Ie)${app}]} )); then
            # Relevant app with display sleep assertion detected
            printlog "Display sleep assertion detected by ${app}."
            return 0
        fi
    done

    # No relevant display sleep assertion detected
    return 1
}


initNamedPipe() {
    # create or delete a named pipe
    # commands are "create" or "delete"

    local cmd=$1
    local pipe=$2
    case $cmd in
        "create")
            if [[ -e $pipe ]]; then
                rm $pipe
            fi
            # make named pipe
            mkfifo -m 644 $pipe
            ;;
        "delete")
            # clean up
            rm $pipe
            ;;
        *)
            ;;
    esac
}

readDownloadPipe() {
    # reads from a previously created named pipe
    # output from curl with --progress-bar. % downloaded is read in and then sent to the specified log file
    local pipe=$1
    local log=${2:-$DIALOG_CMD_FILE}
    # set up read from pipe
    while IFS= read -k 1 -u 0 char; do
        if [[ $char =~ [0-9] ]]; then
            keep=1
        fi

        if [[ $char == % ]]; then
            updateDialog $progress "Downloading..."
            progress=""
            keep=0
        fi

        if [[ $keep == 1 ]]; then
            progress="$progress$char"
        fi
    done < $pipe
}

readPKGInstallPipe() {
    # reads from a previously created named pipe
    # output from installer with -verboseR. % install status is read in and then sent to the specified log file
    local pipe=$1
    local log=${2:-$DIALOG_CMD_FILE}
    local appname=${3:-$name}

    while read -k 1 -u 0 char; do
        if [[ $char == % ]]; then
            keep=1
        fi
        if [[ $char =~ [0-9] && $keep == 1 ]]; then
            progress="$progress$char"
        fi
        if [[ $char == . && $keep == 1 ]]; then
            updateDialog $progress "Installing..."
            progress=""
            keep=0
        fi
    done < $pipe
}

killProcess() {
    # will silently kill the specified PID
    builtin kill $1 2>/dev/null
}

updateDialog() {
    local state=$1
    local message=$2
    local listitem=${3:-$DIALOG_LIST_ITEM_NAME}
    local cmd_file=${4:-$DIALOG_CMD_FILE}
    local progress=""

    if [[ $state =~ '^[0-9]' \
       || $state == "reset" \
       || $state == "increment" \
       || $state == "complete" \
       || $state == "indeterminate" ]]; then
        progress=$state
    fi

    # when to cmdfile is set, do nothing
    if [[ $cmd_file == "" ]]; then
        return
    fi

    if [[ $listitem == "" ]]; then
        # no listitem set, update main progress bar and progress text
        if [[ $progress != "" ]]; then
            echo "progress: $progress" >> $cmd_file
        fi
        if [[ $message != "" ]]; then
            echo "progresstext: $message" >> $cmd_file
        fi
    else
        # list item has a value, so we update the progress and text in the list
        if [[ $progress != "" ]]; then
            echo "listitem: title: $listitem, statustext: $message, progress: $progress" >> $cmd_file
        else
            echo "listitem: title: $listitem, statustext: $message, status: $state" >> $cmd_file
        fi
    fi
}

# NOTE: check minimal macOS requirement
autoload is-at-least

installedOSversion=$(sw_vers -productVersion)
if ! is-at-least 10.14 $installedOSversion; then
    printlog "Installomator requires at least macOS 10.14 Mojave." ERROR
    exit 98
fi


# MARK: argument parsing
if [[ $# -eq 0 ]]; then
    if [[ -z $label ]]; then # check if label is set inside script
        printlog "no label provided, printing labels" REQ
        grep -E '^[a-z0-9\_-]*(\)|\|\\)$' "$0" | tr -d ')|\' | grep -v -E '^(broken.*|longversion|version|valuesfromarguments)$' | sort
        #grep -E '^[a-z0-9\_-]*(\)|\|\\)$' "${labelFile}" | tr -d ')|\' | grep -v -E '^(broken.*|longversion|version|valuesfromarguments)$' | sort
        exit 0
    fi
elif [[ $1 == "/" ]]; then
    # jamf uses sends '/' as the first argument
    printlog "shifting arguments for Jamf" REQ
    shift 3
fi

# first argument is the label
label=$1

# lowercase the label
label=${label:l}

# separate check for 'version' in order to print plain version number without any other information
if [[ $label == "version" ]]; then
    echo "$VERSION"
    exit 0
fi

# MARK: reading rest of the arguments
argumentsArray=()
while [[ -n $1 ]]; do
    if [[ $1 =~ ".*\=.*" ]]; then
        # if an argument contains an = character, send it to eval
        printlog "setting variable from argument $1" INFO
        argumentsArray+=( $1 )
        eval $1
    fi
    # shift to next argument
    shift 1
done
printlog "Total items in argumentsArray: ${#argumentsArray[@]}" INFO
printlog "argumentsArray: ${argumentsArray[*]}" INFO

# NOTE: Use proxy for network access if defined
if [[ -n $PROXY ]]; then
    printlog "Proxy defined: $PROXY, testing access to it" REQ
    proxyAddress=$(echo $PROXY | cut -d ":" -f1)
    portNumber=$(echo $PROXY | cut -d ":" -f2)
    printlog "Proxy: $proxyAddress, Port: $portNumber"
    if cmdOutput=$(! nc -z -v -G 10 ${proxyAddress} ${portNumber} 2>&1) ; then
        printlog "$cmdOutput" REQ
        printlog "ERROR : No proxy connection, skipping this." REQ
    else
        printlog "Proxy access detected, so using that." REQ
        export ALL_PROXY="$PROXY"
    fi
fi

# MARK: Logging
log_location="/private/var/log/Installomator.log"

# Check if we're in debug mode, if so then set logging to DEBUG, otherwise default to INFO
# if no log level is specified.
if [[ $DEBUG -ne 0 ]]; then
    LOGGING=DEBUG
elif [[ -z $LOGGING ]]; then
    LOGGING=INFO
    datadogLoggingLevel=INFO
fi

# Associate logging levels with a numerical value so that we are able to identify what
# should be removed. For example if the LOGGING=ERROR only printlog statements with the
# level REQ and ERROR will be displayed. LOGGING=DEBUG will show all printlog statements.
# If a printlog statement has no level set it's automatically assigned INFO.

declare -A levels=(DEBUG 0 INFO 1 WARN 2 ERROR 3 REQ 4)

# If we are able to detect an MDM URL (Jamf Pro) or another identifier for a customer/instance we grab it here, this is useful if we're centrally logging multiple MDM instances.
if [[ -f /Library/Preferences/com.jamfsoftware.jamf.plist ]]; then
    mdmURL=$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
elif [[ -n "$MDMProfileName" ]]; then
    mdmURL=$(sudo profiles show | grep -A3 "$MDMProfileName" | sed -n -e 's/^.*organization: //p')
else
    mdmURL="Unknown"
fi

# Generate a session key for this run, this is useful to idenify streams when we're centrally logging.
SESSION=$RANDOM

# MARK: START
printlog "################## Start Installomator v. $VERSION, date $VERSIONDATE" REQ
printlog "################## Version: $VERSION" INFO
printlog "################## Date: $VERSIONDATE" INFO
printlog "################## $label" INFO

# Check for DEBUG mode
if [[ $DEBUG -gt 0 ]]; then
    printlog "DEBUG mode $DEBUG enabled." DEBUG
fi

# How we get version number from app
if [[ -z $versionKey ]]; then
    versionKey="CFBundleShortVersionString"
fi

# get current user
currentUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')

# NOTE: check for root
if [[ "$(whoami)" != "root" && "$DEBUG" -eq 0 ]]; then
    # not running as root
    cleanupAndExit 6 "not running as root, exiting" ERROR
fi

# check Swift Dialog presence and version
DIALOG_CMD="/usr/local/bin/dialog"

if [[ ! -x $DIALOG_CMD ]]; then
    # Swift Dialog is not installed, clear cmd file variable to ignore
    printlog "SwiftDialog is not installed, clear cmd file var"
    DIALOG_CMD_FILE=""
fi

# MARK: labels in case statement
case $label in
longversion)
    # print the script version
    printlog "Installomater: version $VERSION ($VERSIONDATE)" REQ
    exit 0
    ;;
valuesfromarguments)
    # no action necessary, all values should be provided in arguments
    ;;

# label descriptions start here
1password8)
    name="1Password"
    type="pkg"
    downloadURL="https://downloads.1password.com/mac/1Password.pkg"
    appNewVersion=$(curl -s https://releases.1password.com/mac/stable/index.xml | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | tail -n1)
    expectedTeamID="2BUA8C4S2C"
    blockingProcesses=( "1Password Extension Helper" "1Password 7" "1Password 8" "1Password" "1PasswordNativeMessageHost" "1PasswordSafariAppExtension" )
    ;;
1passwordcli)
    name="1Password CLI"
    type="pkg"
    #packageID="com.1password.op"
    downloadURL=$(curl -fs https://app-updates.agilebits.com/product_history/CLI2 | grep -i op_apple_universal | grep -v -i beta | head -1 | cut -d'"' -f 2)
    appNewVersion=$(echo $downloadURL | sed -E 's/.*\/[a-zA-Z_]*([0-9.]*)\..*/\1/g')
    appCustomVersion(){ /usr/local/bin/op -v }
    expectedTeamID="2BUA8C4S2C"
    ;;
abetterfinderattributes7)
    name="A Better Finder Attributes 7"
    type="dmg"
    downloadURL="https://www.publicspace.net/download/ABFAX.dmg"
    versionKey="CFBundleVersion"
    appNewVersion=$(curl -s https://www.publicspace.net/ABetterFinderAttributes/download.html | grep -Eo 'Download A Better Finder Attributes [0-9.]+' | awk '{print $NF}' | sort -V | tail -n1)
    expectedTeamID="7Y9KW4ND8W"
    ;;

abetterfinderrename12)
    name="A Better Finder Rename 12"
    type="dmg"
    downloadURL="https://www.publicspace.net/download/ABFRX12.dmg"
    versionKey="CFBundleVersion"
    appNewVersion=$(curl -s https://www.publicspace.net/ABetterFinderRename/download.html | grep -Eo 'Download A Better Finder Rename [0-9.]+' | awk '{print $NF}' | sort -V | tail -n1)
    expectedTeamID="7Y9KW4ND8W"
    ;;

adobeacrobatprodc)
    name="Adobe Acrobat Pro DC"
    appName="Acrobat Distiller.app"
    type="pkgInDmg"
    pkgName="Acrobat/Acrobat DC Installer.pkg"
    packageID="com.adobe.acrobat.DC.viewer.app.pkg.MUI"
    downloadURL="https://trials.adobe.com/AdobeProducts/APRO/Acrobat_HelpX/osx10/Acrobat_DC_Web_WWMUI.dmg"
    releaseNotesURL="https://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/index.html"
    appNewVersion=$(curl -sfL "$releaseNotesURL" | grep -m6 "continuous/dccontinuous.*#" | awk '!/Optional update/ { if ($0 ~ /\(Windows Only\)/) next; else if (match($0, /[0-9]+\.[0-9]+\.[0-9]+ *\(Mac\)/)) {v=substr($0,RSTART,RLENGTH); sub(/ *\(Mac\)/,"",v); print v} else if (match($0, /[0-9]+\.[0-9]+\.[0-9]+/)) print substr($0,RSTART,RLENGTH) }' | head -n1)
    expectedTeamID="JQ525L2MZD"
    blockingProcesses=( "Acrobat Pro DC" )
    Company="Adobe"
    ;;
adobecreativeclouddesktop)
    name="Adobe Creative Cloud"
    appName="Creative Cloud.app"
    type="dmg"
    if pgrep -q "Adobe Installer"; then
        printlog "Adobe Installer is running, not a good time to update." WARN
        printlog "################## End $APPLICATION \n\n" INFO
        exit 75
    fi
    if [[ "$(arch)" == "arm64" ]]; then
        downloadURL=$(curl -fs "https://helpx.adobe.com/in/download-install/apps/download-install-apps/creative-cloud-apps/download-creative-cloud-desktop-app-using-direct-links.html" | grep -o 'https.*macarm64.*dmg' | head -1 | cut -d '"' -f1)
    else
        downloadURL=$(curl -fs "https://helpx.adobe.com/in/download-install/apps/download-install-apps/creative-cloud-apps/download-creative-cloud-desktop-app-using-direct-links.html" | grep -o 'https.*osx10.*dmg' | head -1 | cut -d '"' -f1)
    fi
    #appNewVersion=$(curl -fs "https://helpx.adobe.com/creative-cloud/release-note/cc-release-notes.html" | grep "mandatory" | head -1 | grep -o "Version *.* released" | cut -d " " -f2)
    appNewVersion=$(echo $downloadURL | grep -o '[^x]*$' | cut -d '.' -f 1 | sed 's/_/\./g')
    targetDir="/Applications/Utilities/Adobe Creative Cloud/ACC/"
    installerTool="Install.app"
    CLIInstaller="Install.app/Contents/MacOS/Install"
    CLIArguments=(--mode=silent)
    expectedTeamID="JQ525L2MZD"
    blockingProcesses=( "Creative Cloud" )
    Company="Adobe"
    ;;
adobereaderdc|\
adobereaderdc-install|\
adobereaderdc-update)
    name="Adobe Acrobat Reader"
    type="pkgInDmg"
    if [[ -d "/Applications/Adobe Acrobat Reader DC.app" ]]; then
      printlog "Found /Applications/Adobe Acrobat Reader DC.app - Setting readerPath" INFO
      readerPath="/Applications/Adobe Acrobat Reader DC.app"
      name="Adobe Acrobat Reader DC"
    elif [[ -d "/Applications/Adobe Acrobat Reader.app" ]]; then
      printlog "Found /Applications/Adobe Acrobat Reader.app - Setting readerPath" INFO
      readerPath="/Applications/Adobe Acrobat Reader.app"
    fi
    if ! [[ `defaults read "$readerPath/Contents/Resources/AcroLocale.plist"` ]]; then
      printlog "Missing locale data, this will cause the updater to fail.  Deleting Adobe Acrobat Reader DC.app and installing fresh." INFO
      rm -Rf "$readerPath"
      unset $readerPath
    fi
    if [[ -n $readerPath ]]; then
      mkdir -p "/Library/Application Support/Adobe/Acrobat/11.0"
      defaults write "/Library/Application Support/Adobe/Acrobat/11.0/com.adobe.Acrobat.InstallerOverrides.plist" ReaderAppPath "$readerPath"
      defaults write "/Library/Application Support/Adobe/Acrobat/11.0/com.adobe.Acrobat.InstallerOverrides.plist" BreakIfAppPathInvalid -bool false
      printlog "Adobe Reader Installed, running updater." INFO
      adobecurrent=$(curl -sL https://armmf.adobe.com/arm-manifests/mac/AcrobatDC/reader/current_version.txt)
      adobecurrentmod="${adobecurrent//.}"
      if [[ "${adobecurrentmod}" != <-> ]]; then
        printlog "Got an invalid response for the Adobe Reader Current Version: ${adobecurrent}" ERROR
        printlog "################## End $APPLICATION \n\n" INFO
        exit 50
      fi
      if pgrep -q "Acrobat Updater"; then
        printlog "Adobe Acrobat Updater Running, killing it to avoid any conflicts" INFO
        killall "Acrobat Updater"
      fi
      downloadURL=$(echo https://ardownload2.adobe.com/pub/adobe/reader/mac/AcrobatDC/"$adobecurrentmod"/AcroRdrDCUpd"$adobecurrentmod"_MUI.dmg)
      appNewVersion="${adobecurrent}"
    else
      printlog "Changing IFS for Adobe Reader" INFO
      SAVEIFS=$IFS
      IFS=$'\n'
      versions=( $( curl -s https://www.adobe.com/devnet-docs/acrobatetk/tools/ReleaseNotesDC/index.html | grep -Eo "[0-9]+\.[0-9]+\.[0-9]+"| head -n 30) )
      local version
      for version in $versions; do
        version="${version//.}"
        printlog "trying version: $version" INFO
        local httpstatus=$(curl -X HEAD -s "https://ardownload2.adobe.com/pub/adobe/reader/mac/AcrobatDC/${version}/AcroRdrDC_${version}_MUI.dmg" --write-out "%{http_code}")
        printlog "HTTP status for Adobe Reader full installer URL https://ardownload2.adobe.com/pub/adobe/reader/mac/AcrobatDC/${version}/AcroRdrDC_${version}_MUI.dmg is $httpstatus" DEBUG
        if [[ "${httpstatus}" == "200" ]]; then
          downloadURL="https://ardownload2.adobe.com/pub/adobe/reader/mac/AcrobatDC/${version}/AcroRdrDC_${version}_MUI.dmg"
          unset httpstatus
          break
        fi
      done
      unset version
      IFS=$SAVEIFS
    fi
    updateTool="/usr/local/bin/RemoteUpdateManager"
    updateToolArguments=( --productVersions=RDR )
    updateToolLog="/Users/$currentUser/Library/Logs/RemoteUpdateManager.log"
    updateToolLogDateFormat="%m/%d/%y %H:%M:%S"
    expectedTeamID="JQ525L2MZD"
    blockingProcesses=( "Acrobat Pro DC" "AdobeAcrobat" "AdobeReader" "Distiller" )
    Company="Adobe"
    ;;
airtable)
    name="Airtable"
    type="dmg"
    downloadURL="https://static.airtable.com/download/AirtableInstaller.dmg"
    expectedTeamID="E22RZMX62E"
    ;;
airtame)
    name="Airtame"
    type="dmg"
    downloadURL="$(curl -fs https://airtame.com/download/ | grep -i platform=mac | head -1 | grep -o -i -E "https.*" | cut -d '"' -f1)"
    appNewVersion="$(curl -fsIL "${downloadURL}" | grep -i ^location | sed -E 's/.*\/[a-zA-Z]*-([0-9.]*)\..*/\1/g')"
    expectedTeamID="4TPSP88HN2"
    ;;
airtamepkg)
    name="Airtame"
    type="pkg"
    packageID="com.airtame.airtame-application"
    appNewVersion="$(curl -fs https://airtame.com/download/ | grep -i platform=mac | head -1 | grep -o -i -E "https.*" | cut -d '"' -f1 | xargs curl -fsIL | grep -i ^location | sed -E 's/.*\/[a-zA-Z]*-([0-9.]*)\..*/\1/g')"
    downloadURL="https://airtame-app.b-cdn.net/app/latest/mac/Airtame-${appNewVersion}.pkg"
    expectedTeamID="4TPSP88HN2"
    ;;
alfred)
    # credit: AP Orlebeke (@apizz)
    name="Alfred"
    type="dmg"
    downloadURL=$(curl -fs https://www.alfredapp.com | awk -F '"' "/dmg/ {print \$2}" | head -1)
    appNewVersion=$(echo "${downloadURL}" | sed -E 's/.*Alfred_([0-9.]*)_.*/\1/')
    appName="Alfred 5.app"
    expectedTeamID="XZZXE9SED4"
    ;;
anaconda)
    name="Anaconda-Navigator"
    packageID="com.anaconda.io"
    type="pkg"
    if [[ "$(arch)" == "arm64" ]]; then
        archiveName=$( curl -sf https://repo.anaconda.com/archive/ | awk '/href=".*Anaconda.*MacOSX.*arm64.*\.pkg"/{gsub(/.*href="|".*/, ""); gsub(/.*\//, ""); print; exit}' )
    else
        archiveName=$( curl -sf https://repo.anaconda.com/archive/ | awk '/href=".*Anaconda.*MacOSX.*x86_64.*\.pkg"/{gsub(/.*href="|".*/, ""); gsub(/.*\//, ""); print; exit}' )
    fi
    downloadURL="https://repo.anaconda.com/archive/$archiveName"
    appNewVersion=$( awk -F'-' '{print $2}' <<< "$archiveName" )
    expectedTeamID="Z5788K4JT7"
    blockingProcesses=( "Anaconda-Navigator.app" )
    appCustomVersion() {
        if [ -e "/Users/$currentUser/opt/anaconda3/bin/conda" ]; then
            "/Users/$currentUser/opt/anaconda3/bin/conda" list -f ^anaconda$ | awk '/anaconda /{print $2}'
        fi
    }
    updateTool="/Users/$currentUser/opt/anaconda3/bin/conda"
    updateToolArguments=( install -y anaconda=$appNewVersion )
    updateToolRunAsCurrentUser=1
    ;;
appleprovideoformats)
    name="ProVideoFormats"
    type="pkgInDmg"
    downloadURL=$(curl -s "https://support.apple.com/en-us/106396" | grep -Eo 'https://updates\.cdn-apple\.com[^"]+ProVideoFormats\.dmg' | head -n 1)
    packageID="com.apple.pkg.ProVideoFormats"
    expectedTeamID="Software Update"
    ;;
asana)
    name="Asana"
    type="dmg"
    downloadURL="https://desktop-downloads.asana.com/darwin_universal/prod/latest/Asana.dmg"
    expectedTeamID="A679L395M8"
    ;;
aspera|\
ibmaspera)
    name="IBM Aspera"
    type="pkg"
    appNewVersion=$(curl -fsL https://downloads.ibmaspera.com/downloads/desktop/latest/stable/latest.json | jq -r '.entries.[] | select(.platform == "macos") | .version')
    downloadURL=$(curl -fsL https://downloads.ibmaspera.com/downloads/desktop/latest/stable/latest.json | jq -r '.entries.[] | select(.platform == "macos") | .url')
    expectedTeamID="PETKK2G752"
    ;;
asperaconnect)
    name="Aspera Connect"
    type="pkg"
    indexFilePath=$(curl -fsL https://ibmaspera.com/help/downloads/desktop | grep 'script type="module"' | grep -o "/.*.js")
    downloadBaseUrl="https:$(curl -fsL https://ibmaspera.com${indexFilePath} | grep versions.js | grep -o "var i=\"//.*downloads/connect" | sed -E 's/var i="//g')"
    appInfo=$(curl -fs ${downloadBaseUrl}/latest/versions.js | grep -o "{.*}")
    appNewVersion=$(echo ${appInfo} | jq -r '.entries.[] | select(.title == "Aspera Connect for macOS") | .version' | awk -F "." '{print$1"."$2"."$3}')
    downloadURL="${downloadBaseUrl}/latest/$(echo ${appInfo} | jq -r '.entries.[] | select(.title == "Aspera Connect for macOS").links.[] | select(.rel == "enclosure-one-click").href')"
    expectedTeamID="PETKK2G752"
    ;;
atlassiancompanion)
    name="Atlassian Companion"
    type="dmg"
    downloadURL=$(curl -fsL https://confluence.atlassian.com/display/DOC/Install+Atlassian+Companion | sed -nE 's/.*(https:.*\.dmg)\".*/\1/p')
    appNewVersion=$(getJSONValue "$(curl -fsL https://update-nucleus.atlassian.com/Atlassian-Companion/291cb34fe2296e5fb82b83a04704c9b4/darwin/x64/RELEASES.json)" "currentRelease" )
    expectedTeamID="UPXU4CQZ5P"
    ;;

audacity)
    name="Audacity"
    type="dmg"
    archiveName="audacity-macOS-[0-9.]*-universal.dmg"
    downloadURL=$(downloadURLFromGit audacity audacity)
    appNewVersion=$(versionFromGit audacity audacity)
    appCustomVersion(){ defaults read "/Applications/Audacity.app/Contents/Info.plist" CFBundleVersion | cut -d '.' -f 1-3 }
    expectedTeamID="AWEYX923UX"
    ;;
autodmg)
    # credit: Mischa van der Bent (@mischavdbent)
    name="AutoDMG"
    type="dmg"
    downloadURL=$(downloadURLFromGit MagerValp AutoDMG)
    appNewVersion=$(versionFromGit MagerValp AutoDMG)
    expectedTeamID="5KQ3D3FG5H"
    ;;
autopkgr)
    name="AutoPkgr"
    type="dmg"
    downloadURL=$(downloadURLFromGit lindegroup autopkgr)
    appNewVersion=$(versionFromGit lindegroup autopkgr)
    expectedTeamID="JVY2ZR6SEF"
    ;;
bbedit)
    name="BBEdit"
    type="dmg"
    downloadURL=$(curl -s https://versioncheck.barebones.com/BBEdit.xml | grep dmg | sort | tail -n1 | cut -d">" -f2 | cut -d"<" -f1)
    appNewVersion=$(curl -s https://versioncheck.barebones.com/BBEdit.xml | grep dmg | sort  | tail -n1 | sed -E 's/.*BBEdit_([0-9 .]*)\.dmg.*/\1/')
    expectedTeamID="W52GZAXT98"
    ;;
bbeditpkg)
    name="BBEdit"
    type="pkg"
    downloadURL=$(curl -s https://versioncheck.barebones.com/BBEdit.xml | grep dmg | sort | tail -n1 | cut -d">" -f2 | cut -d"<" -f1 | sed 's/dmg/pkg/')
    appNewVersion=$(curl -s https://versioncheck.barebones.com/BBEdit.xml | grep dmg | sort  | tail -n1 | sed -E 's/.*BBEdit_([0-9 .]*)\.dmg.*/\1/')
    expectedTeamID="W52GZAXT98"
    ;;
betterzip)
    name="BetterZip"
    type="zip"
    downloadURL="https://macitbetter.com/BetterZip.zip"
    appNewVersion=$(curl -Ls https://macitbetter.com/version-history/ | awk 'match($0,/Version[[:space:]]+[0-9]+(\.[0-9]+)+/){print substr($0,RSTART,RLENGTH)}' | head -n1 | awk '{print $2}')
    versionKey="CFBundleShortVersionString"
    expectedTeamID="79RR9LPM2N"
    ;;
bitwarden)
    name="Bitwarden"
    type="dmg"
    appNewVersion=$(curl -s "https://github.com/bitwarden/clients/releases?q\=desktop" | xmllint --html --xpath 'substring-after(string(//h2[starts-with(text(),"Desktop v")]), " v")' - 2>/dev/null)
    downloadURL="https://github.com/bitwarden/clients/releases/download/desktop-v${appNewVersion}/Bitwarden-${appNewVersion}-universal.dmg"
    expectedTeamID="LTZ2PFU5D6"
    ;;
blender)
    name="Blender"
    type="dmg"
    versionKey="CFBundleShortVersionString"
    baseVersion=$(curl -sf https://ftp.nluug.nl/pub/graphics/blender/release/ | grep -o 'Blender[0-9]\+\.[0-9]\+' | cut -d 'r' -f 2 | sort -V | tail -1)
    if [[ $(arch) == "arm64" ]]; then
        appNewVersion=$(curl -sf https://ftp.nluug.nl/pub/graphics/blender/release/Blender$baseVersion/ | grep -o 'blender-[0-9]\+\.[0-9]\+\.[0-9]\+-macos-arm64\.dmg' | sort -V | tail -1 | sed -E 's/[^0-9]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/' )
        archiveName=$(curl -sf "https://ftp.nluug.nl/pub/graphics/blender/release/Blender$baseVersion/"| grep -o 'blender-[0-9]\+\.[0-9]\+\.[0-9]\+-macos-arm64\.dmg' | sort -V | tail -1)
        downloadURL="https://ftp.nluug.nl/pub/graphics/blender/release/Blender$baseVersion/$archiveName"
    elif [[ $(arch) == "i386" ]]; then
        appNewVersion=$(curl -sf https://ftp.nluug.nl/pub/graphics/blender/release/Blender$baseVersion/ | grep -o 'blender-[0-9]\+\.[0-9]\+\.[0-9]\+-macos-x64\.dmg' | sort -V | tail -1 | sed -E 's/[^0-9]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/' )
        archiveName=$(curl -sf "https://ftp.nluug.nl/pub/graphics/blender/release/Blender$baseVersion/" | grep -o 'blender-[0-9]\+\.[0-9]\+\.[0-9]\+-macos-x64\.dmg' | sort -V | tail -1)
        downloadURL="https://ftp.nluug.nl/pub/graphics/blender/release/Blender$baseVersion/$archiveName"
    fi
    expectedTeamID="68UA947AUU"
    ;;
brave)
    name="Brave Browser"
    type="dmg"
    if [[ $(arch) != "i386" ]]; then
        printlog "Architecture: arm64 (not i386)"
        downloadURL=$(curl -fsIL https://laptop-updates.brave.com/latest/osxarm64/release | grep -i "^location" | sed -E 's/.*(https.*\.dmg).*/\1/g')
        appNewVersion="$(curl -fsL "https://updates.bravesoftware.com/sparkle/Brave-Browser/stable-arm64/appcast.xml" | xpath '//rss/channel/item[last()]/enclosure/@sparkle:version' 2>/dev/null  | cut -d '"' -f 2)"
        #appNewVersion="96.$(curl -fsL "https://updates.bravesoftware.com/sparkle/Brave-Browser/stable-arm64/appcast.xml" | xpath '//rss/channel/item[last()]/enclosure/@sparkle:shortVersionString' 2>/dev/null  | cut -d '"' -f 2 | cut -d "." -f1-3)"
    else
        printlog "Architecture: i386"
        downloadURL=$(curl -fsIL https://laptop-updates.brave.com/latest/osx/release | grep -i "^location" | sed -E 's/.*(https.*\.dmg).*/\1/g')
        appNewVersion="$(curl -fsL "https://updates.bravesoftware.com/sparkle/Brave-Browser/stable/appcast.xml" | xpath '//rss/channel/item[last()]/enclosure/@sparkle:version' 2>/dev/null  | cut -d '"' -f 2)"
        #appNewVersion="96.$(curl -fsL "https://updates.bravesoftware.com/sparkle/Brave-Browser/stable/appcast.xml" | xpath '//rss/channel/item[last()]/enclosure/@sparkle:shortVersionString' 2>/dev/null  | cut -d '"' -f 2 | cut -d "." -f1-3)"
    fi
    versionKey="CFBundleVersion"
#    downloadURL=$(curl -fsL "https://updates.bravesoftware.com/sparkle/Brave-Browser/stable/appcast.xml" | xpath '//rss/channel/item[last()]/enclosure/@url' 2>/dev/null  | cut -d '"' -f 2)
    expectedTeamID="KL8N8XSYF4"
    ;;
bravepkg)
    name="Brave Browser"
    type="pkg"
    downloadURL="https://referrals.brave.com/latest/Brave-Browser.pkg" # Universal
        # https://referrals.brave.com/latest/Brave-Browser-arm64.pkg - ARM64
    appNewVersion="$(curl -fsL "https://updates.bravesoftware.com/sparkle/Brave-Browser/stable/appcast.xml" | xpath '//rss/channel/item[last()]/enclosure/@sparkle:version' 2>/dev/null  | cut -d '"' -f 2)"
    versionKey="CFBundleVersion"
    expectedTeamID="KL8N8XSYF4"
    ;;
burpsuitecommunityedition)
    name="Burp Suite Community Edition"
    type="dmg"
    appNewVersion=$(curl -s https://portswigger.net/burp/releases | grep 'releases/professional-community' | head -n 1 | sed 's/.*href="//' | sed 's/".*//' | cut -d '/' -f4 | cut -d '-' -f3-6 | sed -r 's/-/./g')
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://portswigger.net/burp/releases/startdownload/?product=community&version&="$appNewVersion"&type=macosarm64"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://portswigger.net/burp/releases/startdownload/?product=community&version&="$appNewVersion"&type=macosx"
    fi
    expectedTeamID="N82YM748DZ"
    ;;
burpsuiteprofessional)
    name="Burp Suite Professional"
    type="dmg"
    appNewVersion=$(curl -s https://portswigger.net/burp/releases | grep 'releases/professional-community' | head -n 1 | sed 's/.*href="//' | sed 's/".*//' | cut -d '/' -f4 | cut -d '-' -f3-6 | sed -r 's/-/./g')
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://portswigger.net/burp/releases/startdownload/?product=pro&version&="$appNewVersion"&type=macosarm64"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://portswigger.net/burp/releases/startdownload/?product=pro&version&="$appNewVersion"&type=macosx"
    fi
    expectedTeamID="N82YM748DZ"
    ;;
calibriteprofiler)
    name="calibrite PROFILER"
    type="dmg"
    downloadURL="$(downloadURLFromGit LUMESCA calibrite-profiler-releases)"
    appNewVersion="$(versionFromGit LUMESCA calibrite-profiler-releases)"
    expectedTeamID="5C392763F5"
    ;;
camtasia2024)
    name="Camtasia"
    type="dmg"
    sparkleData=$(curl -fsL -H 'User-Agent: Camtasia/2024.0.0' 'https://www.techsmith.com/redirect.asp?target=sparkleappcast&product=camtasiamac&ver=2024.0.0&lang=enu&os=mac')
    appNewVersion=$(
        echo "$sparkleData" | \
        xmllint -xpath 'string(//*[local-name()="item"][last()]/*[local-name()="shortVersionString"]/text())' -
    )
    downloadURL=$(
        echo "$sparkleData" | \
        xmllint -xpath 'string(//*[local-name()="item"][last()]/enclosure/@url)' -
    )
    expectedTeamID="7TQL462TU8"
    ;;
camtasia2025)
    name="Camtasia"
    type="dmg"
    sparkleData=$(curl -fsL -H 'User-Agent: Camtasia/2025.0.0' 'https://www.techsmith.com/redirect.asp?target=sparkleappcast&product=camtasiamac&ver=2025.0.0&lang=enu&os=mac')
    appNewVersion=$(
        echo "$sparkleData" | \
        xmllint -xpath 'string(//*[local-name()="item"][last()]/*[local-name()="shortVersionString"]/text())' -
    )
    downloadURL=$(
        echo "$sparkleData" | \
        xmllint -xpath 'string(//*[local-name()="item"][last()]/enclosure/@url)' -
    )
    expectedTeamID="7TQL462TU8"
    ;;
camtasia|\
camtasia2026)
    name="Camtasia"
    type="dmg"
    sparkleData=$(curl -H 'user-agent: Camtasia/2026.0.7 Sparkle/2.8.0' -fsL 'https://sparkle.cloud.techsmith.com/api/v1/AppcastManifest/?version=26.0.0&utm_source=product&utm_medium=cmac&utm_campaign=cm26&ipc_item_name=cmac&ipc_platform=macos')
    appNewVersion=$( <<<"$sparkleData" xpath '//*[local-name()="shortVersionString"] [starts-with(.,"2026.")] /text()' | tr ' ' '\n' | sort -V | tail -n1)
    downloadURL=$( <<<"$sparkleData" xpath 'string( //*[local-name()="item"] [./*[local-name()="shortVersionString"] = "'"$appNewVersion"'"] /*[local-name()="enclosure"]/@url)')
    expectedTeamID="7TQL462TU8"
    ;;
canva)
    name="Canva"
    type="dmg"
        downloadURL=https://desktop-release.canva.com/Canva-latest.dmg
        appNewVersion=$( curl -fsLI -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Safari/605.1.15" -H "accept-encoding: gzip, deflate, br" -H "Referrer Policy: strict-origin-when-cross-origin" -H "upgrade-insecure-requests: 1" -H "sec-fetch-dest: document" -H "sec-gpc: 1" -H "sec-fetch-user: ?1" -H "accept-language: en-US,en;q=0.9" -H "accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9" -H "sec-fetch-mode: navigate" "https://www.canva.com/download/mac/intel/canva-desktop/" | grep -i "^location" | cut -d " " -f2 | tr -d '\r' | sed -E 's/.*\/[a-zA-Z]*-([0-9.]*)-*.*\.dmg/\1/g' )

    expectedTeamID="5HD2ARTBFS"
    ;;
captureone|captureonepro)
    name="Capture One"
    type="dmg"
    captureoneSparkle=$(curl -fsL "https://www.captureone.com/update/capture-one-mac.xml")
    downloadURL=$(echo "${captureoneSparkle}" | xmllint --xpath "string(//item[1]/enclosure/@url)" - 2>/dev/null)
    appNewVersion=$(echo "${downloadURL}" | sed -E 's/.*Mac\.([0-9.]+)\.dmg/\1/')
    expectedTeamID="5WTDB5F65L"
    ;;
carboncopycloner)
    name="Carbon Copy Cloner"
    type="zip"
    downloadURL=$(curl -fsIL "https://api.bombich.com/download/ccc?v=latest" | grep -i ^location | sed -E 's/.*(https.*\.zip).*/\1/g')
    appNewVersion=$(sed -E 's/.*-([0-9.]*)\.zip/\1/g' <<< $downloadURL | sed 's/\.[^.]*$//')
    expectedTeamID="L4F2DED5Q7"
    ;;
chatgpt)
    name="ChatGPT"
    type="dmg"
    downloadURL="https://persistent.oaistatic.com/sidekick/public/ChatGPT_Desktop_public_latest.dmg"
    appNewVersion="$(curl -fs "https://persistent.oaistatic.com/sidekick/public/sparkle_public_appcast.xml" | xpath '(//rss/channel/item/title)[1]/text()' 2>/dev/null)"
    expectedTeamID="2DC432GLL2"
    ;;
chromeremotedesktop)
    name="chromeremotedesktop"
    type="pkgInDmg"
    packageID="com.google.pkg.ChromeRemoteDesktopHost"
    downloadURL="https://dl.google.com/chrome-remote-desktop/chromeremotedesktop.dmg"
    appNewVersion=""
    expectedTeamID="EQHXZ8M8AV"
    ;;
chronoagent)
    name="ChronoAgent"
    type="pkgInDmg"
    # packageID="com.econtechnologies.preference.chronoagent"
    # versionKey="CFBundleVersion"
    # None of the above can read out the installed version
    releaseURL="https://www.econtechnologies.com/UC/updatecheck.php?prod=ChronoAgent&lang=en&plat=mac&os=10.14.1&hw=i64&req=1&vers=#"
    appNewVersion=$(curl -sf $releaseURL | sed -r 's/.*VERSION=([^<]+).*/\1/')
    downloadURL="https://downloads.econtechnologies.com/CA_Mac_Download.dmg"
    expectedTeamID="9U697UM7YX"
    ;;
chronosync)
    name="ChronoSync"
    type="pkgInDmg"
    releaseURL="https://www.econtechnologies.com/UC/updatecheck.php?prod=ChronoSync&lang=en&plat=mac&os=10.14.1&hw=i64&req=1&vers=#"
    appNewVersion=$(curl -sf $releaseURL | sed -r 's/.*VERSION=([^<]+).*/\1/')
    downloadURL="https://downloads.econtechnologies.com/CS4_Download.dmg"
    expectedTeamID="9U697UM7YX"
    ;;
citrixworkspace)
    name="Citrix Workspace"
    type="pkg"
    parseURL=$(curl -fs "https://downloadplugins.citrix.com/ReceiverUpdates/Prod/catalog_macos.xml" | xmllint --xpath 'string(//Installer/DownloadURL)' -)
    downloadURL=https://downloadplugins.citrix.com/ReceiverUpdates/Prod/$parseURL
    appNewVersion=$(curl -fs "https://downloadplugins.citrix.com/ReceiverUpdates/Prod/catalog_macos.xml" | xmllint --xpath 'string(//Installer/Version)' -)
    versionKey="CitrixVersionString"
    expectedTeamID="S272Y5R93J"
    ;;
claudedesktop)
    name="Claude"
    type="zip"
    appNewVersion=$(curl -fs "https://downloads.claude.ai/releases/darwin/universal/RELEASES.json" | grep -o '"currentRelease":"[^"]*"' | cut -d'"' -f4)
    downloadURL=$(curl -fs "https://downloads.claude.ai/releases/darwin/universal/RELEASES.json" | grep -o '"url":"[^"]*"' | cut -d'"' -f4)
    expectedTeamID="Q6L2SF6YDW"
    blockingProcesses=( "Claude" "Claude Helper" )
    ;;
clickshare)
    name="ClickShare"
    type="zip"
    json_feed=$(curl -fsL "https://assets.cloud.barco.com/clickshare/release/release.mac")
    appNewVersion=$(getJSONValue "${json_feed}" 'version')
    file_name=$(getJSONValue "${json_feed}" 'name')
    downloadURL="https://assets.cloud.barco.com/clickshare/release/${file_name}"
    expectedTeamID="P6CDJZR997"
    ;;
clickup)
	name="ClickUp"
	type="dmg"
	if [[ $(arch) == "arm64" ]]; then
		appNewVersion=$(curl -sD /dev/stdout https://desktop.clickup.com/mac/dmg/arm64 | grep filename | sed 's/^.*[^0-9]\([0-9]*\.[0-9]*\.[0-9]*\).*$/\1/')
		downloadURL="https://desktop.clickup.com/mac/dmg/arm64"
	elif [[ $(arch) == "i386" ]]; then
        appNewVersion=$(curl -sD /dev/stdout https://desktop.clickup.com/mac | grep filename | sed 's/^.*[^0-9]\([0-9]*\.[0-9]*\.[0-9]*\).*$/\1/')
        downloadURL="https://desktop.clickup.com/mac"
	fi
	expectedTeamID="5RJWFAUGXQ"
	;;
cmake)
    name="CMake"
    type="dmg"
    downloadURL=$(downloadURLFromGit Kitware CMake)
    appNewVersion=$(versionFromGit Kitware CMake)
    expectedTeamID="W38PE5Y733"
    ;;
coconutbattery)
    name="coconutBattery"
    type="zip"
    downloadURL="https://www.coconut-flavour.com/downloads/coconutBattery_4_latest.zip"
    appNewVersion=$(curl -fs https://www.coconut-flavour.com/coconutbattery/ | grep "<body" | sed -E 's/.*Download v([0-9+\.?]+).*/\1/')
    expectedTeamID="R5SC3K86L5"
    ;;
code42)
    name="Code42"
    type="pkgInDmg"
    if [[ $(arch) == i386 ]]; then
       downloadURL="https://download-preservation.code42.com/installs/agent/latest-mac.dmg"
    elif [[ $(arch) == arm64 ]]; then
       downloadURL="https://download-preservation.code42.com/installs/agent/latest-mac-arm64.dmg"
    fi
    expectedTeamID="9YV9435DHD"
    blockingProcesses=( NONE )
    ;;
crashplan)
    name="CrashPlan"
    type="pkgInDmg"
    downloadURL="https://download.crashplan.com/installs/agent/latest-mac.dmg"
    appNewVersion=$( curl -sfI https://download.crashplan.com/installs/agent/latest-mac.dmg | awk -F'/' '/Location: /{print $7}' )
    archiveName=$( curl -sfI https://download.crashplan.com/installs/agent/latest-mac.dmg | awk -F'/' '/Location: /{print $NF}' )
    expectedTeamID="UGHXR79U6M"
    pkgName="Install CrashPlan.pkg"
    packageID="com.crashplan.app.pkg"
    ;;
crashplansmb)
    name="CrashPlan"
    type="pkgInDmg"
    pkgName="Install Crashplan.pkg"
    downloadURL="https://download.crashplan.com/installs/agent/latest-smb-mac.dmg"
    appNewVersion=$( curl https://download.crashplan.com/installs/agent/latest-smb-mac.dmg  -s -L -I -o /dev/null -w '%{url_effective}' | cut -d "/" -f7 )
    expectedTeamID="UGHXR79U6M"
    blockingProcesses=( NONE )
    ;;
cursorai)
    name="Cursor"
    type="dmg"
    updateFeed=$(curl -fsL  "https://www.cursor.com/api/download?platform=darwin-universal&releaseTrack=latest")
    appNewVersion=$(getJSONValue "${updateFeed}" "version")
    downloadURL=$(getJSONValue "${updateFeed}" "downloadUrl")
    expectedTeamID="VDXQ22DGB9"
    versionKey="CFBundleVersion"
    ;;
cyberduck)
    name="Cyberduck"
    type="zip"
    changeLOG="$( curl -fs https://version.cyberduck.io/changelog.rss )"
    downloadURL=$( echo "$changeLOG" | sed 's/sparkle://g' | xmllint --xpath 'string(//item/enclosure/@url)' - 2>/dev/null)
    appNewVersion=$( echo "$changeLOG" | sed 's/sparkle://g' | xmllint --xpath 'string(//item/enclosure/@shortVersionString)' - 2>/dev/null)
    expectedTeamID="G69SCX94XU"
    ;;
daisydisk)
    name="DaisyDisk"
    type="zip"
    downloadURL="https://daisydiskapp.com/downloads/DaisyDisk.zip"
    appNewVersion=$( curl -fs 'https://daisydiskapp.com/downloads/appcastReleaseNotes.php?appEdition=Standard' | grep Version | head -1 | sed -E 's/.*Version ([0-9.]*).*/\1/g' )
    expectedTeamID="4CBU3JHV97"
    ;;
darktable)
    # credit: Søren Theilgaard (@theilgaard)
    name="darktable"
    type="dmg"
    downloadURL=$(downloadURLFromGit darktable-org darktable)
    appNewVersion=$(versionFromGit darktable-org darktable)
    expectedTeamID="85Q3K4KQRY"
    ;;
dialog|\
swiftdialog)
    name="Dialog"
    type="pkg"
    packageID="au.csiro.dialogcli"
    downloadURL="$(downloadURLFromGit swiftDialog swiftDialog)"
    appNewVersion="$(versionFromGit swiftDialog swiftDialog)"
    expectedTeamID="PWA5E9TQ59"
    ;;
discord)
    name="Discord"
    type="dmg"
    downloadURL="https://discordapp.com/api/download?platform=osx"
    appNewVersion="$(curl -fsL -o /dev/null -w %{url_effective} "${downloadURL}" | awk -F'/' '{print $(NF-1)}')"
    expectedTeamID="53Q6R32WPB"
    ;;
diskdrill)
    name="Disk Drill"
    type="dmg"
    appname="Disk Drill.app"
    downloadURL="https://dl.cleverfiles.com/diskdrill.dmg"
    appNewVersion=$( curl -fsL "https://www.cleverfiles.com/releases/auto-update/dd5-newestr.xml" | xpath 'string(//rss/channel/item/enclosure/@sparkle:version)' 2>/dev/null)
    expectedTeamID="A3W62KZY8Z"
    ;;
displaylinkmanager)
    name="DisplayLink Manager"
    type="pkg"
    #packageID="com.displaylink.displaylinkmanagerapp"
    downloadURL=https://www.synaptics.com$(redirect=$(curl -sfL https://www.synaptics.com/products/displaylink-graphics/downloads/macos | grep -m 1 'class="download-link">Download' | sed 's/.*href="//' | sed 's/".*//') && curl -sfL "https://www.synaptics.com$redirect" | grep 'class="no-link"' | awk -F 'href="' '{print $2}' | awk -F '"' '{print $1}')
    appNewVersion=$(curl -sfL https://www.synaptics.com/products/displaylink-graphics/downloads/macos | grep -m 1 "Release:" | cut -d ' ' -f2)
    expectedTeamID="73YQY62QM3"
    ;;
docker)
    name="Docker"
    type="dmg"
    if [[ "$(arch)" == arm64 ]]; then
        downloadURL="https://desktop.docker.com/mac/stable/arm64/Docker.dmg"
        appNewVersion=$( curl -fs "https://desktop.docker.com/mac/main/arm64/appcast.xml" | xpath '(//rss/channel/item/enclosure/@sparkle:shortVersionString)[last()]' 2>/dev/null | cut -d '"' -f2 )
    elif [[ "$(arch)" == i386 ]]; then
        downloadURL="https://desktop.docker.com/mac/stable/amd64/Docker.dmg"
        appNewVersion=$( curl -fs "https://desktop.docker.com/mac/main/amd64/appcast.xml" | xpath '(//rss/channel/item/enclosure/@sparkle:shortVersionString)[last()]' 2>/dev/null | cut -d '"' -f2 )
    fi
    CLIInstaller="Docker.app/Contents/MacOS/install"
    CLIArguments=(--accept-license)
    if [[ "${currentUser}" != "loginwindow" ]];then
        CLIArguments+=(--user "${currentUser}")
    fi
    expectedTeamID="9BNSXJN65R"
    blockingProcesses=( "Docker Desktop" )
    ;;
dockutil)
    name="dockutil"
    type="pkg"
    packageID="dockutil.cli.tool"
    downloadURL=$(downloadURLFromGit "kcrawford" "dockutil")
    appNewVersion=$(versionFromGit "kcrawford" "dockutil")
    expectedTeamID="Z5J8CJBUWC"
    blockingProcesses=( NONE )
    ;;
dragonframe2024)
    name="DragonFrame 2024"
    type="pkg"
    curlOptions=( -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Safari/605.1.15" )
    appNewVersion=$(curl -s -A "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Safari/605.1.15" https://www.dragonframe.com/downloads/ | grep -o 'Dragonframe_2024\.[0-9]\+\.[0-9]\+\.pkg' | sed -E 's/Dragonframe_//; s/\.pkg$//' | head -n 1)
    downloadURL="https://www.dragonframe.com/download/Dragonframe_${appNewVersion}.pkg"
    appName="Applications/Dragonframe 2024/Dragonframe 2024.app"
    versionKey="CFBundleShortVersionString"
    expectedTeamID="PG7SM8SD8M"
    ;;
    
dragonframe2025)
    name="DragonFrame 2025"
    type="pkg"
    curlOptions=( -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Safari/605.1.15" )
    appNewVersion=$(curl -s -A "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Safari/605.1.15" https://www.dragonframe.com/downloads/ | grep -o 'Dragonframe [0-9]\+\.[0-9]\+\.[0-9]\+' | sed 's/Dragonframe //' | head -n 1)
    downloadURL="https://www.dragonframe.com/download/Dragonframe_${appNewVersion}.pkg"
    appName="Applications/Dragonframe 2025/Dragonframe 2025.app"
    versionKey="CFBundleShortVersionString"
    expectedTeamID="PG7SM8SD8M"
    ;;

dragonframe5)
    name="DragonFrame 5"
    type="pkg"
    packageID="com.dzed.Dragonframe5"
    expectedTeamID="PG7SM8SD8M"
    curlOptions=( -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Safari/605.1.15" )
    downloadURL="$( curl -s "https://www.dragonframe.com/downloads/" $curlOptions | tr '"' '\n' | grep -m1 "_5.*pkg" )"
    appNewVersion="$( echo "$downloadURL" | cut -d '_' -f 2 | cut -d '.' -f 1-3 )"
    ;;
drawio)
    name="draw.io"
    type="dmg"
    archiveName="draw.io-universal-[0-9.]*.dmg"
    downloadURL="$(downloadURLFromGit jgraph drawio-desktop)"
    appNewVersion="$(versionFromGit jgraph drawio-desktop)"
    expectedTeamID="UZEUFB4N53"
    blockingProcesses=( draw.io )
    ;;
dropbox)
    name="Dropbox"
    type="dmg"
    # Handling differens on Apple Silicon and Intel arch
    if [[ $(arch) = "arm64" ]]; then
        printlog "Architecture: arm64"
        downloadURL="https://www.dropbox.com/download?plat=mac&full=1&arch=arm64"
    else
        printlog "Architecture: i386 (not arm64)"
        downloadURL="https://www.dropbox.com/download?plat=mac&full=1"
    fi
    appNewVersion=$(curl -fsIL "$downloadURL" | grep -i "^location" | sed -E 's/.*%20([0-9.]*)\.[arm64.]*dmg/\1/g' | tr -d '[:cntrl:]' )
    expectedTeamID="G7HH3F8CAK"
    ;;
dropboxenterprise)
    name="Dropbox Enterprise"
    appName="Dropbox.app"
    type="pkg"
    # Handling differens on Apple Silicon and Intel arch
    if [[ $(arch) = "arm64" ]]; then
        printlog "Architecture: arm64"
        downloadURL="https://client.dropbox.com/desktop/desktop-dropbox/requestdownload?install_type=enterprise_install&platform=mac&arch=arm64"
    else
        printlog "Architecture: i386 (not arm64)"
        downloadURL="https://client.dropbox.com/desktop/desktop-dropbox/requestdownload?install_type=enterprise_install&platform=mac&arch=x86_64"
    fi
    appNewVersion=$(curl -fsIL "$downloadURL" | grep -o "Dropbox.*.pkg"  | sed -E 's/.*%20([0-9.]*)\.([x86_64.]|[arm64.])*pkg/\1/g' | tr -d '[:cntrl:]' )
    expectedTeamID="G7HH3F8CAK"
    ;;
duckduckgo)
    name="DuckDuckGo"
    type="dmg"
    #downloadURL="https://staticcdn.duckduckgo.com/macos-desktop-browser/duckduckgo.dmg"
    downloadURL=$(curl -fs https://staticcdn.duckduckgo.com/macos-desktop-browser/appcast.xml | xpath '(//rss/channel/item/enclosure/@url)[last()]' 2>/dev/null | cut -d '"' -f2)
    #downloadURL=$(curl -fs https://staticcdn.duckduckgo.com/macos-desktop-browser/appcast.xml | xpath '(//rss/channel/item/enclosure/@url)[1]' 2>/dev/null | cut -d '"' -f2)
    appNewVersion=$(curl -fs https://staticcdn.duckduckgo.com/macos-desktop-browser/appcast.xml | xpath '(//rss/channel/item/enclosure/@sparkle:version)[last()]' 2>/dev/null | cut -d '"' -f2)
    #appNewVersion=$(curl -fs https://staticcdn.duckduckgo.com/macos-desktop-browser/appcast.xml | xpath '(//rss/channel/item/sparkle:shortVersionString)[1]' 2>/dev/null | cut -d ">" -f2 | cut -d "<" -f1)
    expectedTeamID="HKE973VLUW"
    ;;
easeusdatarecoverywizard)
    # credit: Søren Theilgaard (@theilgaard)
    name="EaseUS Data Recovery Wizard"
    type="dmg"
    downloadURL=$( curl -fsIL https://down.easeus.com/product/mac_drw_free_setup | grep -i "^location" | awk '{print $2}' | tr -d '\r\n' )
    #appNewVersion=""
    expectedTeamID="DLLVW95FSM"
    ;;
easyfind)
    name="EasyFind"
    type="zip"
    downloadURL="$(curl -fs "https://www.devontechnologies.com/apps/freeware" | grep -o "http.*download.*.zip" | grep -i easyfind)"
    appNewVersion="$(echo $downloadURL | sed -E 's/.*\/([0-9.]*)\/.*/\1/g')"
    expectedTeamID="679S2QUWR8"
    ;;
epicgameslauncher)
	name="Epic Games Launcher"
	type="dmg"
	downloadURL="https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncher.dmg"
	appNewVersion=$( curl -s "https://trello.com/b/GXLc34hk.json" | jq -r '.cards[] | select(.name | test("Epic Games Launcher [0-9]+\\.[0-9]+(\\.[0-9]+)?")) | .name' | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | sort -V | tail -n 1 )
	versionKey="CFBundleShortVersionString"
	expectedTeamID="96DBZ92D3Y"
	;;
facebookmessenger)
    name="Messenger"
    type="dmg"
    downloadURL="https://www.messenger.com/messenger/desktop/downloadV2/?platform=mac"
    appNewVersion=$(curl -I "${downloadURL}" | awk -F': ' '/^location/ {print $2}' | grep -oE 'Messenger.*\.dmg' | sed 's/Messenger\.//;s/\.dmg//')
    expectedTeamID="V9WTTPBFK9"
    ;;
figma)
    name="Figma"
    type="zip"
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://desktop.figma.com/mac-arm/Figma.zip"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://desktop.figma.com/mac/Figma.zip"
    fi
    appNewVersion="$(getJSONValue "$(curl -fs https://desktop.figma.com/mac/RELEASE.json)" "version")"
    expectedTeamID="T8RA8NE3B7"
    ;;
filemakerpro)
    name="FileMaker Pro"
    type="dmg"
    versionKey="BuildVersion"
    downloadURL=$(curl -fs https://www.filemaker.com/redirects/ss.txt | grep '\"PRO..MAC\"' | tail -1 | sed "s|.*url\":\"\(.*\)\".*|\\1|")
    appNewVersion=$(curl -fs https://www.filemaker.com/redirects/ss.txt | grep '\"PRO..MAC\"' | tail -1 | sed "s|.*fmp_\(.*\).dmg.*|\\1|")
    expectedTeamID="J6K4T76U7W"
    ;;
filemakerpro20)
    name="FileMaker Pro"
    type="dmg"
    versionKey="BuildVersion"
    downloadURL=$(curl -fs https://www.filemaker.com/redirects/ss.txt | grep '\"PRO20MAC\"' | tail -1 | sed "s|.*url\":\"\(.*\)\".*|\\1|")
    appNewVersion=$(curl -fs https://www.filemaker.com/redirects/ss.txt | grep '\"PRO20MAC\"' | tail -1 | sed "s|.*fmp_\(.*\).dmg.*|\\1|")
    expectedTeamID="J6K4T76U7W"
    ;;
filemakerpro21)
    name="FileMaker Pro"
    type="dmg"
    versionKey="BuildVersion"
    downloadURL=$(curl -fs https://www.filemaker.com/redirects/ss.txt | grep '\"PRO21MAC\"' | tail -1 | sed "s|.*url\":\"\(.*\)\".*|\\1|")
    appNewVersion=$(curl -fs https://www.filemaker.com/redirects/ss.txt | grep '\"PRO21MAC\"' | tail -1 | sed "s|.*fmp_\(.*\).dmg.*|\\1|")
    expectedTeamID="J6K4T76U7W"
    ;;
filemakerpro22)
    name="FileMaker Pro"
    type="dmg"
    versionKey="BuildVersion"
    downloadURL=$(curl -fs https://www.filemaker.com/redirects/ss.txt | grep '\"PRO22MAC\"' | tail -1 | sed "s|.*url\":\"\(.*\)\".*|\\1|")
    appNewVersion=$(curl -fs https://www.filemaker.com/redirects/ss.txt | grep '\"PRO22MAC\"' | tail -1 | sed "s|.*fmp_\(.*\).dmg.*|\\1|")
    expectedTeamID="J6K4T76U7W"
    ;;
finalcutprocontent)
    name="FCPContent"
    type="pkgInDmg"
    downloadURL=$(curl -s "https://support.apple.com/en-us/106574" | grep -Eo 'https://updates\.cdn-apple\.com[^"]+FCPContent\.dmg' | head -n 1)
    packageID="com.apple.pkg.FCPContent"
    expectedTeamID="Software Update"
    ;;
finaldraft11)
    name="Final Draft 11"
    type="pkgInZip"
    downloadURL="https://www.finaldraft.com"
    downloadURL+=$(curl -fs "https://www.finaldraft.com/support/install-final-draft/install-final-draft-11-macintosh/" | xmllint --html --format - 2>/dev/null | grep -o "/downloads/finaldraft.*.zip")
    appNewVersion=$(echo $downloadURL | cut -d 't' -f5 | cut -f1 -d "M")
    expectedTeamID="7XUZ8R5736"
    ;;
finaldraft12)
    name="Final Draft 12"
    type="appInDmgInZip"
    downloadURL="https://www.finaldraft.com"
    downloadURL+=$(curl -fs "https://www.finaldraft.com/support/install-final-draft/install-final-draft-12-macintosh/" | xmllint --html --format - 2>/dev/null | grep -o "/downloads/finaldraft.*.zip")
    appNewVersion=$(echo $downloadURL | cut -d 't' -f5 | cut -f1 -d "M")
    expectedTeamID="7XUZ8R5736"
    ;;
finaldraft13)
    #credit to @adamcodega on Slack for helping to fix the curl
    name="Final Draft 13"
    type="appInDmgInZip"
    downloadURL="https://www.finaldraft.com$(curl -fs "https://www.finaldraft.com/support/install-final-draft/install-final-draft-13-macintosh/" | xmllint --html --format - 2>/dev/null | grep -o "/downloads/finaldraft.*.zip" | head -n 1)"
    appNewVersion=$(echo $downloadURL | cut -d 't' -f5 | cut -f1 -d "M")
    versionKey="CFBundleShortVersionString"
    expectedTeamID="7XUZ8R5736"
    ;;
firefoxpkg|\
firefox)
    name="Firefox"
    type="pkg"
    downloadURL="https://download.mozilla.org/?product=firefox-pkg-latest-ssl&os=osx&lang=en-US"
    firefoxVersions=$(curl -fs "https://product-details.mozilla.org/1.0/firefox_versions.json")
    appNewVersion=$(getJSONValue "$firefoxVersions" "LATEST_FIREFOX_VERSION")
    expectedTeamID="43AQ936H96"
    blockingProcesses=( firefox )
    ;;
flux)
    name="Flux"
    type="zip"
    appNewVersion=$(curl -fsL "https://justgetflux.com/mac/macflux.xml" | xpath 'string(//rss/channel/item/enclosure/@sparkle:version)' 2>/dev/null)
    downloadURL="https://justgetflux.com/mac/Flux.zip"
    expectedTeamID="VZKSA7H9J9"
    ;;
fontbase)
    name="FontBase"
    type="dmg"
    appNewVersion=$(curl -s https://releases.fontba.se/mac/latest-mac.yml | grep version: | awk -F ':' '{print $2}' | sed -e 's/^ *//' -e 's/ *$//')
    downloadURL="https://releases.fontba.se/mac/FontBase-$appNewVersion.dmg"
    expectedTeamID="457B89RFCZ"
    ;;
fontexplorer)
    name="FontExplorer X Pro"
    type="dmg"
    packageID="com.linotype.FontExplorerX"
    downloadURL="http://www.fontexplorerx.com/download/free-trial/Mac/"
    appNewVersion=$( curl -fsL http://fex.linotype.com/update/client/mac/pro/version.plist | grep string | tail -n 1 | sed 's/[^0-9.]//g' )
    expectedTeamID="2V7G2B7WG4"
    ;;

garminexpress)
    name="Garmin Express"
    blockingProcesses=( "Garmin Express" "Garmin Express Service" )
    type="pkgInDmg"
    downloadURL="https://download.garmin.com/omt/express/GarminExpress.dmg"
    garminJSON="$(curl -fsL https://support.garmin.com/en-US/\?faq\=4QVp7mKSIA1LDk5fc1OHX8 | grep latest | grep -o "{.*}")"
    appNewVersion="$(getJSONValue "$garminJSON" "apiData" "faq" "content" | xmllint --html - 2>/dev/null | grep -o "for Mac: .* as" | grep -o "[0-9].*[0-9]").0"
    expectedTeamID="72ES32VZUA"
    ;;
googlegemini)
    name="Gemini"
    type="dmg"
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://dl.google.com/release2/j33ro/release/Gemini.dmg"
    else
        printlog "Gemini is only compatible with Apple Silicon (arm64) Macs." ERROR
        cleanupAndExit 95 "Gemini requires Apple Silicon" ERROR
    fi
    json=$(curl -Ssf 'https://update.googleapis.com/service/update2/json' -X POST --data-raw '{"request":{"@updater":"GoogleUpdater","domainjoined":true,"protocol":"4.0","dlpref":"cacheable","dedup":"cr","os":{"platform":"MacOSX","version":"26.0.0","arch":"arm64"},"@os":"mac","arch":"arm64","acceptformat":"crx3,download,puff,run,xz,zucc","apps":[{"ap":"m1-prod","enabled":true,"version":"1.00.0.000","updatecheck":{},"appid":"com.google.GeminiMacOS"}]}}' | /usr/bin/tail -c +6)
    appNewVersion=$(echo "$json" | /usr/bin/plutil -extract response.apps.0.updatecheck.nextversion raw -o - -)
    expectedTeamID="EQHXZ8M8AV"
    ;;
ghostty)
    name="ghostty"
    type="dmg"
    appNewVersion="$(curl -fs "https://ghostty.org/download" | grep -E -io 'href="[^\"]+"' | grep -e "Ghostty.dmg" | awk -F\" '{print$2}' | sed -E 's/.*\/([0-9.]*)\/.*/\1/g')"
    downloadURL="https://release.files.ghostty.org/$appNewVersion/Ghostty.dmg"
    expectedTeamID="24VZTF6M5V"
    ;;
gimp)
    name="GIMP"
    type="dmg"
    gimpDetails="$(curl -fs "https://www.gimp.org/gimp_versions.json")"
    appNewVersion="$(getJSONValue "$gimpDetails" "STABLE[0].version")"
    dlVersion="$(echo "${appNewVersion}" | cut -d'.' -f1-2)"
    [[ "$(getJSONValue "$gimpDetails" "STABLE[0].macos[0].filename")" == *"x86_64"* ]] && gimpDmgx86_64="$(getJSONValue "$gimpDetails" "STABLE[0].macos[0].filename")" && gimpDmgArm64="$(getJSONValue "$gimpDetails" "STABLE[0].macos[1].filename")"
    [[ "$(getJSONValue "$gimpDetails" "STABLE[0].macos[0].filename")" == *"arm64"* ]] && gimpDmgArm64="$(getJSONValue "$gimpDetails" "STABLE[0].macos[0].filename")" && gimpDmgx86_64="$(getJSONValue "$gimpDetails" "STABLE[0].macos[1].filename")"
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://download.gimp.org/gimp/v${dlVersion}/macos/${gimpDmgArm64}"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://download.gimp.org/gimp/v${dlVersion}/macos/${gimpDmgx86_64}"
    fi
    expectedTeamID="T25BQ8HSJF"
    ;;
gimpdev)
    name="GIMP"
    type="dmg"
    gimpDetails="$(curl -fs "https://www.gimp.org/gimp_versions.json")"
    appNewVersion="$(getJSONValue "$gimpDetails" "DEVELOPMENT[0].version")"
    dlVersion="$(echo "${appNewVersion}" | cut -d'.' -f1-2)"
    [[ "$(getJSONValue "$gimpDetails" "DEVELOPMENT[0].macos[0].filename")" == *"x86_64"* ]] && gimpDmgx86_64="$(getJSONValue "$gimpDetails" "DEVELOPMENT[0].macos[0].filename")" && gimpDmgArm64="$(getJSONValue "$gimpDetails" "DEVELOPMENT[0].macos[1].filename")"
    [[ "$(getJSONValue "$gimpDetails" "DEVELOPMENT[0].macos[0].filename")" == *"arm64"* ]] && gimpDmgArm64="$(getJSONValue "$gimpDetails" "DEVELOPMENT[0].macos[0].filename")" && gimpDmgx86_64="$(getJSONValue "$gimpDetails" "DEVELOPMENT[0].macos[1].filename")"
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://download.gimp.org/gimp/v${dlVersion}/macos/${gimpDmgArm64}"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://download.gimp.org/gimp/v${dlVersion}/macos/${gimpDmgx86_64}"
    fi
    expectedTeamID="T25BQ8HSJF"
    ;;
githubdesktop)
    name="GitHub Desktop"
    type="zip"
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://central.github.com/deployments/desktop/desktop/latest/darwin-arm64"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://central.github.com/deployments/desktop/desktop/latest/darwin"
    fi
    appNewVersion=$(curl -fsL https://central.github.com/deployments/desktop/desktop/changelog.json | awk -F '{' '/"version"/ { print $2 }' | sed -E 's/.*,\"version\":\"([0-9.]*)\".*/\1/g')
    expectedTeamID="VEKTX9H2N7"
    ;;
golang)
    name="GoLang"
    type="pkg"
    packageID="org.golang.go"
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://go.dev$(curl -fs "https://go.dev/dl/" | grep -i "downloadBox" | grep "darwin-arm" | tr '"' '\n' | grep "pkg")"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://go.dev$(curl -fs "https://go.dev/dl/" | grep -i "downloadBox" | grep "darwin-amd" | tr '"' '\n' | grep "pkg")"
    fi
    appNewVersion="$( echo "${downloadURL}" | sed -E 's/.*\/(go[0-9.]*)\..*/\1/g' )" # Version includes letters "go" in the beginning
    expectedTeamID="EQHXZ8M8AV"
    blockingProcesses=( NONE )
    ;;
googleadseditor)
    name="Google Ads Editor"
    type="dmg"
    downloadURL="https://dl.google.com/adwords_editor/google_ads_editor.dmg"
    appNewVersion="$(curl -s "https://support.google.com/google-ads/editor/topic/13728" | grep -Eo 'Google Ads Editor version [0-9]+(\.[0-9]+)*' | head -1 | grep -Eo '[0-9]+(\.[0-9]+)*')"
    appCustomVersion(){cat /Applications/Google\ Ads\ Editor.app/Contents/Versions/*/Google\ Ads\ Editor.app/Contents/locale/content/welcome1/welcome1-en-US.htm | grep -o -E " about version.{0,4}" | tail -c 4}
    expectedTeamID="EQHXZ8M8AV"
    ;;
googlechromepkg)
    name="Google Chrome"
    type="pkg"
    #
    # Note: this url acknowledges that you accept the terms of service
    # https://support.google.com/chrome/a/answer/9915669
    #
    downloadURL="https://dl.google.com/chrome/mac/stable/accept_tos%3Dhttps%253A%252F%252Fwww.google.com%252Fintl%252Fen_ph%252Fchrome%252Fterms%252F%26_and_accept_tos%3Dhttps%253A%252F%252Fpolicies.google.com%252Fterms/googlechrome.pkg"
    appNewVersion=$(getJSONValue "$(curl -fsL "https://versionhistory.googleapis.com/v1/chrome/platforms/mac/channels/stable/versions/all/releases?filter=fraction%3E0.01,endtime=none&order_by=version%20desc" )" "releases[0].version" )
    expectedTeamID="EQHXZ8M8AV"
    updateTool="/Library/Google/GoogleSoftwareUpdate/GoogleSoftwareUpdate.bundle/Contents/Resources/GoogleSoftwareUpdateAgent.app/Contents/MacOS/GoogleSoftwareUpdateAgent"
    updateToolArguments=( -runMode oneshot -userInitiated YES )
    updateToolRunAsCurrentUser=1
    ;;
googledrive|\
googledrivefilestream)
    # credit: Isaac Ordonez, Mann consulting (@mannconsulting)
    name="Google Drive File Stream"
    type="pkgInDmg"
    if [[ $(arch) == "arm64" ]]; then
       packageID="com.google.drivefs.arm64"
    elif [[ $(arch) == "i386" ]]; then
       packageID="com.google.drivefs.x86_64"
    fi
    appNewVersion=$(curl -s "https://community.chocolatey.org/packages/googledrive" | xmllint --html --xpath 'substring-after(string(//h1[@class="mb-0 text-center"]), "Google Drive")' - 2> /dev/null)
    downloadURL="https://dl.google.com/drive-file-stream/GoogleDriveFileStream.dmg" # downloadURL="https://dl.google.com/drive-file-stream/GoogleDrive.dmg"
    blockingProcesses=( "Google Docs" "Google Drive" "Google Sheets" "Google Slides" )
    appName="Google Drive.app"
    expectedTeamID="EQHXZ8M8AV"
    ;;
googledrivebackupandsync)
    name="Backup and Sync"
    type="dmg"
    downloadURL="https://dl.google.com/drive/InstallBackupAndSync.dmg"
    expectedTeamID="EQHXZ8M8AV"
    ;;
googleearth)
    name="Google Earth Pro"
    type="pkgInDmg"
    downloadURL="https://dl.google.com/earth/client/advanced/current/GoogleEarthProMac-Intel.dmg"
    expectedTeamID="EQHXZ8M8AV"
    ;;
googlesoftwareupdate)
    name="Install Google Software Update"
    type="pkgInDmg"
    pkgName="Install Google Software Update.app/Contents/Resources/GSUInstall.pkg"
    downloadURL="https://dl.google.com/mac/install/googlesoftwareupdate.dmg"
    blockingProcesses=( NONE )
    expectedTeamID="EQHXZ8M8AV"
    ;;
googlewebdesigner)
    name="Google Web Designer"
    type="dmg"
    downloadURL="https://dl.google.com/webdesigner/mac/shell/googlewebdesigner_mac.dmg"
    appNewVersion=$(curl -fs https://support.google.com/webdesigner/topic/6350071\?hl\=en | tr '<' '\n' |  grep -o "Shell Build.*$" | grep -o "[0-9].*[0-9]" | sort --version-sort | tail -1)
    expectedTeamID="EQHXZ8M8AV"
    ;;
gotiengviet)
    name="GoTiengViet"
    type="dmg"
    downloadURL="https://www.trankynam.com/gotv/downloads/GoTiengViet.dmg"
    appNewVersion=""
    expectedTeamID="KHEMQ2FD9E"
    ;;
gotomeeting)
    # credit: @matins
    name="GoToMeeting"
    type="dmg"
    downloadURL="https://link.gotomeeting.com/latest-dmg"
    expectedTeamID="GFNFVT632V"
    ;;
gotowebinar)
    name="GoTo"
    type="dmg"
    downloadURL="https://goto-desktop.goto.com/GoTo-arm64.dmg"
    appNewVersion=""
    expectedTeamID="GFNFVT632V"
    ;;
gpgsuite)
    # credit: Micah Lee (@micahflee)
    name="GPG Suite"
    type="pkgInDmg"
    pkgName="Install.pkg"
    downloadURL=$(curl -s https://gpgtools.com/ | grep https://releases.gpgtools.com/GPG_Suite- | grep Download | cut -d'"' -f4)
    appNewVersion=$(echo $downloadURL | cut -d "-" -f 2 | cut -d "." -f 1-2)
    expectedTeamID="PKV8ZPD836"
    blockingProcesses=( "GPG Keychain" )
    appCustomVersion(){ defaults read /Library/Application\ Support/GPGTools/version.plist CFBundleShortVersionString }
    ;;
gpgsync)
    name="GPG Sync"
    type="pkg"
    packageID="org.firstlook.gpgsync"
    downloadURL="$(downloadURLFromGit firstlookmedia gpgsync)"
    appNewVersion="$(versionFromGit firstlookmedia gpgsync)"
    expectedTeamID="P24U45L8P5"
    ;;
grammarly)
     name="Grammarly Desktop"
     type="dmg"
     packageID="com.grammarly.ProjectLlama"
     downloadURL="https://download-mac.grammarly.com/Grammarly.dmg"
     expectedTeamID="W8F64X92K3"
     # appName="Grammarly Installer.app"
     installerTool="Grammarly Installer.app"
     CLIInstaller="Grammarly Installer.app/Contents/MacOS/Grammarly Desktop"
;;
graphicconverter10)
    name="GraphicConverter 10"
    type="zip"
    downloadURL=$(curl -fs "https://www.lemkesoft.info/sparkle/graphicconverter/graphicconverter10.xml" | grep -i 'enclosure url=' | grep -m 1 ".zip" | cut -d '"' -f 2)
    appNewVersion=$(curl -fs "https://www.lemkesoft.info/sparkle/graphicconverter/graphicconverter10.xml" | grep -i 'enclosure url=' | grep -m 1 ".zip" | cut -d '"' -f 6 | sed 's/.*"\(.*\)".*/\1/')
    expectedTeamID="FAVZJT8J4U"
    versionKey="CFBundleShortVersionString"
    ;;
gyazo)
    # credit: @matins
    name="Gyazo"
    type="dmg"
    appNewVersion=$(curl -is "https://formulae.brew.sh/cask/gyazo" | grep 'Current version:' | grep -o "Gyazo.*dmg" | cut -d "-" -f 2 | awk -F ".dmg" '{print $1}')
    downloadURL="https://files.gyazo.com/setup/Gyazo-${appNewVersion}.dmg"
    expectedTeamID="9647Y3B7A4"
    ;;
gyazogif)
    # credit: @matins
    # This is identical to gyazo, but the download contains two apps on the DMG
    name="Gyazo GIF"
    type="dmg"
    appNewVersion=$(curl -is "https://formulae.brew.sh/cask/gyazo" | grep 'Current version:' | grep -o "Gyazo.*dmg" | cut -d "-" -f 2 | awk -F ".dmg" '{print $1}')
    downloadURL="https://files.gyazo.com/setup/Gyazo-${appNewVersion}.dmg"
    expectedTeamID="9647Y3B7A4"
    ;;
handbrake)
    name="HandBrake"
    type="dmg"
    downloadURL=$(downloadURLFromGit HandBrake HandBrake )
    appNewVersion=$(versionFromGit HandBrake HandBrake )
    expectedTeamID="5X9DE89KYV"
    ;;
homebrew)
    name="Homebrew"
    type="pkg"
    packageID="sh.brew.homebrew"
    downloadURL="$(downloadURLFromGit Homebrew brew)"
    appNewVersion="$(versionFromGit Homebrew brew)"
    expectedTeamID="927JGANW46"
    archiveName="Homebrew.pkg"
    ;;
i1profiler)
    name="i1Profiler"
    type="pkgInZip"
    downloadURL=$(curl -fs "https://downloads.xrite.com/downloads/autoupdate/i1profiler_mac_appcast.xml" | xmllint --xpath '//rss/channel/item[1]/enclosure/@url' - | sed -E 's/.*url="([^"]+)".*/\1/')
    appNewVersion=$(curl -fs "https://downloads.xrite.com/downloads/autoupdate/i1profiler_mac_appcast.xml" | xmllint --xpath '//rss/channel/item[1]/enclosure/@sparkle:shortVersionString' - | sed -E 's/.*shortVersionString="([^"]+)".*/\1/')
    expectedTeamID="2K7GT73B4R"
    ;;
ibarcoder)
    name="iBarcoder"
    type="dmg"
    downloadURL="https://cristallight.com/Downloads/mac/ibarcoder.dmg"
    appNewVersion="$(curl -fs "https://cristallight.com/iBarcoder/" | grep -i version: | head -1 | awk '{print $2}')"
    expectedTeamID="JAXVB9AH9M"
    ;;
imageoptim)
    name="imageoptim"
    type="tbz"
    packageID="net.pornel.ImageOptim"
    downloadURL="https://imageoptim.com/ImageOptim.tbz2"
    appNewVersion=$( curl -fsL https://imageoptim.com/appcast.xml | grep "title" | tail -n 1 | sed 's/[^0-9.]//g' )
    expectedTeamID="59KZTZA4XR"
    blockingProcesses=( NONE )
    ;;
inkscape)
    name="Inkscape"
    type="dmg"
    appCustomVersion() { /Applications/Inkscape.app/Contents/MacOS/inkscape --version | cut -d " " -f2 }
    appNewVersion=$(curl -fsL https://inkscape.org/release/  | grep "<title>" | grep -o -e "[0-9.]*")
    if [[ $(arch) == arm64 ]]; then
        downloadURL="https://media.inkscape.org/dl/resources/file/$(curl -fsL https://inkscape.org/release/inkscape-{$appNewVersion}/mac-os-x/dmg-arm64/dl/ | grep -o -m1 "Inkscape-.*.dmg")"
    elif [[ $(arch) == i386 ]]; then
        downloadURL="https://media.inkscape.org/dl/resources/file/$(curl -fsL https://inkscape.org/release/inkscape-{$appNewVersion}/mac-os-x/dmg/dl/ | grep -o -m1 "Inkscape-.*.dmg")"
    fi
    expectedTeamID="SW3D6BB6A6"
    ;;
iterm2)
    name="iTerm"
    type="zip"
    downloadURL="https://iterm2.com/downloads/stable/latest"
    appNewVersion=$(curl -is https://iterm2.com/downloads/stable/latest | grep location: | grep -o "iTerm2.*zip" | cut -d "-" -f 2 | cut -d '.' -f1 | sed 's/_/./g')
    expectedTeamID="H7V7XYVQ7D"
    blockingProcesses ( "iTerm" "iTerm2" )
    ;;
jabradirect)
    name="Jabra Direct"
    type="pkgInDmg"
    # packageID="com.jabra.directonline"
    versionKey="CFBundleVersion"
    downloadURL="https://jabraxpressonlineprdstor.blob.core.windows.net/jdo/JabraDirectSetup.dmg"
    #appNewVersion=$(curl -fs https://www.jabra.com/Support/release-notes/release-note-jabra-direct | grep -oe "Release version:.*[0-9.]*<" | head -1 | cut -d ">" -f2 | cut -d "<" -f1 | sed 's/ //g')
    appNewVersion=$(curl -fs "https://jabraexpressonlinejdo.jabra.com/jdo/jdo.json" | grep -i MacVersion | cut -d '"' -f4)
    expectedTeamID="55LV32M29R"
    ;;
jdk17)
    name="Java SE Development Kit 17"
    type="pkgInDmg"
    versionKey="CFBundleShortVersionString"
    appNewVersion=$(curl -sf https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html | grep -m 1 "Java SE Development Kit" | sed "s|.*Kit \(.*\)\<.*|\\1|")
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://download.oracle.com/java/17/archive/jdk-"$appNewVersion"_macos-aarch64_bin.dmg"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://download.oracle.com/java/17/archive/jdk-"$appNewVersion"_macos-x64_bin.dmg"
    fi
    appCustomVersion(){ java --version | grep java | awk '{print $2}' }
    expectedTeamID="VB5E2TV963"
    ;;
jdk18)
    name="Java SE Development Kit 18"
    type="pkgInDmg"
    versionKey="CFBundleShortVersionString"
    appNewVersion=$(curl -sf https://www.oracle.com/java/technologies/javase/jdk18-archive-downloads.html | grep -m 1 "Java SE Development Kit" | sed "s|.*Kit \(.*\)\<.*|\\1|")
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://download.oracle.com/java/18/archive/jdk-"$appNewVersion"_macos-aarch64_bin.dmg"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://download.oracle.com/java/18/archive/jdk-"$appNewVersion"_macos-x64_bin.dmg"
    fi
    appCustomVersion(){ java --version | grep java | awk '{print $2}' }
    expectedTeamID="VB5E2TV963"
    ;;
jdk19)
    name="Java SE Development Kit 19"
    type="pkgInDmg"
    versionKey="CFBundleShortVersionString"
    appNewVersion=$(curl -sf https://www.oracle.com/java/technologies/javase/jdk19-archive-downloads.html | grep -m 1 "Java SE Development Kit" | sed "s|.*Kit \(.*\)\<.*|\\1|")
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://download.oracle.com/java/19/archive/jdk-"$appNewVersion"_macos-aarch64_bin.dmg"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://download.oracle.com/java/19/archive/jdk-"$appNewVersion"_macos-x64_bin.dmg"
    fi
    appCustomVersion(){ java --version | grep java | awk '{print $2}' }
    expectedTeamID="VB5E2TV963"
    ;;
jdk20)
    name="Java SE Development Kit 20"
    type="pkgInDmg"
    versionKey="CFBundleShortVersionString"
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://download.oracle.com/java/20/latest/jdk-20_macos-aarch64_bin.dmg"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://download.oracle.com/java/20/latest/jdk-20_macos-x64_bin.dmg"
    fi
    appCustomVersion(){ java --version | grep java | awk '{print $2}' }
    expectedTeamID="VB5E2TV963"
    ;;
jetbrainswebstorm)
    name="Webstorm"
    type="dmg"
    jetbrainscode="WS"
    jetbrainsdistribution="mac"
    if [[ $(arch) == arm64 ]]; then
        jetbrainsdistribution="macM1"
    fi
    downloadURL="https://download.jetbrains.com/product?code=${jetbrainscode}&latest&distribution=${jetbrainsdistribution}"
    appNewVersion=$( curl -fsIL "${downloadURL}" | grep -i "location" | tail -1 | sed -E 's/.*-([0-9.]+)[-.].*/\1/g' )
    expectedTeamID="2ZEFAR8TH3"
    ;;
jre8)
    name="Java Runtime Environment 8"
    type="pkgInDmg"
    versionKey="CFBundleVersion"
    versionURL=$(curl -fs "https://javadl-esd-secure.oracle.com/update/mac/map-mac-1.8.0.xml" | xpath '( //java-update-map/mapping/url)[last()]' 2>/dev/null | cut -d\> -f2 | cut -d\< -f1)
    appNewVersion=$(curl -fs "${versionURL}" | xpath '(//rss/channel/item/enclosure/@sparkle:version)' 2>/dev/null | cut -d '"' -f 2)
    appBuildVersion=$(echo $appNewVersion | cut -d. -f3)
    downloadURL="$(curl -fs "${versionURL}" | xpath '(//rss/channel/item/enclosure/@url)[last()]' 2>/dev/null | cut -d '"' -f 2)"
    pkgName="Java 8 Update ${appBuildVersion}.app/Contents/Resources/JavaAppletPlugin.pkg"
    appCustomVersion(){ defaults read "/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Info.plist" "${versionKey}" 2>/dev/null }
    expectedTeamID="VB5E2TV963"
    ;;
knockknock)
    name="KnockKnock"
    type="zip"
    downloadURL="$(downloadURLFromGit objective-see KnockKnock)"
    appNewVersion="$(versionFromGit objective-see KnockKnock)"
    expectedTeamID="VBG97UB4TA"
    ;;
kommodo|\
kommodoscreenrecorder)
    name="Kommodo Screen Recorder"
    type="pkg"
    archiveName="KommodoScreenRecorder.pkg"
    if [[ $(arch) == "arm64" ]]; then
        appNewVersion=$(curl -fs "https://api.prod.komododecks.com/api/v2/releases/arm64/latest-mac.yml" | awk '/^version:/ {print $2}')
        downloadURL="https://releases.komododecks.com/prod/electron/${appNewVersion}/kommodo-screen-recorder-${appNewVersion}-arm.pkg"
    elif [[ $(arch) == "i386" ]]; then
        appNewVersion=$(curl -fs "https://api.prod.komododecks.com/api/v2/releases/x64/latest-mac.yml" | awk '/^version:/ {print $2}')
        downloadURL="https://releases.komododecks.com/prod/electron/${appNewVersion}/kommodo-screen-recorder-${appNewVersion}-intel.pkg"
    fi
    expectedTeamID="3M6U87VP9P"
    ;;
krisp)
    name="Krisp"
    type="pkg"
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://download.krisp.ai/mac?package=package_arm"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://download.krisp.ai/mac?package=package_64"
    fi
    appNewVersion="$(curl -fsIL $downloadURL | grep -i "^location" | tail -1 | awk -F'/' '{ print $(NF-2) }')"
    expectedTeamID="U5R26XM5Z2"
    ;;
lastpass)
    name="LastPass"
    type="dmg"
    downloadURL="https://download.cloud.lastpass.com/mac/LastPass.dmg"
    appNewVersion="$(curl -fs "https://download.cloud.lastpass.com/mac/AppCast.xml" | xpath 'string(//rss/channel/item/title)' 2>/dev/null)"
    expectedTeamID="N24REP3BMN"
    ;;
libreoffice)
    name="LibreOffice"
    type="dmg"
    appNewVersion="$(curl -s https://download.documentfoundation.org/libreoffice/stable/ | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | tail -1)"
    if [[ $(arch) == "arm64" ]]; then
    	downloadURL="https://download.documentfoundation.org/libreoffice/stable/${appNewVersion}/mac/aarch64/LibreOffice_${appNewVersion}_MacOS_aarch64.dmg"
    elif [[ $(arch) == "i386" ]]; then
    	downloadURL="https://download.documentfoundation.org/libreoffice/stable/${appNewVersion}/mac/x86_64/LibreOffice_${appNewVersion}_MacOS_x86-64.dmg"
    fi
    versionKey="CFBundleVersion"
    expectedTeamID="7P5S3ZLCN7"
    blockingProcesses=( soffice )
    ;;
libreofficelanguagepack_intl)
    name="LibreOffice Language Pack"
    # appName="LibreOffice.app"
    #
    # Reads the primary language of the system and installs the appropriate language pack for the latest LibreOffice STABLE version
    # There is no language pack for the US English language and no installation is required other than the LibreOffice software itself.
    # Use in combination and after installing Libre Office (STABLE Version)
    # This label requires user interaction to complete the installation
    #
    type="dmg"
    packageID="org.libreoffice.script.langpack"
    userLanguage=$(runAsUser defaults read .GlobalPreferences AppleLanguages | head -2 | tail -1 | tr -dc "[:alnum:]\-")
    if [[ "$userLanguage" == "en-US" ]]; then
        cleanupAndExit 0 "No installation of a language pack is necessary for the US-English language."
    fi
    appNewVersion="$(curl -Ls https://www.libreoffice.org/download/download-libreoffice/ | grep dl_version_number | head -n 1 | cut -d'>' -f3 | cut -d'<' -f1)"
    releaseURL="https://download.documentfoundation.org/libreoffice/stable/"$appNewVersion"/mac/aarch64/"
    until curl -fs $releaseURL | grep -q "_$userLanguage.dmg"; do
        if [ ${#userLanguage} -eq 2 ]; then
            break
        fi
        printlog "No locale matching '$userLanguage', trying '${userLanguage:0:2}'"
        userLanguage=${userLanguage:0:2}
    done
    printlog "Using language '$userLanguage' for download."
    # downloadURL="https://downloadarchive.documentfoundation.org/libreoffice/old/latest/mac/aarch64/"
    # if ! curl -sfL --output /dev/null -r 0-0 $downloadURL; then
    #     printlog "Download not found for '$userLanguage', exiting."
    #     exit
    # fi
    # appNewVersion=$(curl -sf $releaseURL | grep -m 1 "_langpack_$userLanguage.dmg" | sed "s|.*LibreOffice_\(.*\)_MacOS.*|\\1|")
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://download.documentfoundation.org/libreoffice/stable/"$appNewVersion"/mac/aarch64/LibreOffice_"$appNewVersion"_MacOS_aarch64_langpack_"$userLanguage".dmg"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://download.documentfoundation.org/libreoffice/stable/"$appNewVersion"/mac/x86_64/LibreOffice_"$appNewVersion"_MacOS_x86-64_langpack_"$userLanguage".dmg"
    fi
    installerTool="LibreOffice Language Pack.app"
    CLIInstaller="LibreOffice Language Pack.app/Contents/LibreOffice Language Pack"
    expectedTeamID="7P5S3ZLCN7"
    # blockingProcesses=( soffice )
    ;;
lifesize)
    name="Lifesize"
    type="dmg"
    downloadURL="https://download.lifesizecloud.com/$(curl -fsL "https://download.lifesizecloud.com/" | xpath '//ListBucketResult/Contents/Key' 2>/dev/null | grep -oE '<Key>(.*\.dmg)</Key>' | sed 's/<Key>\(.*\)<\/Key>/\1/' | tail -1)"
    appNewVersion="$(echo "$downloadURL" | sed 's~https://download\.lifesizecloud\.com/~~;s/Lifesize-//;s/\.dmg//')"
    expectedTeamID="L57M4NT7Y7"
    ;;
lightburn)
    name="LightBurn"
    type="dmg"
    downloadURL="$(downloadURLFromGit LightBurnSoftware deployment)"
    appNewVersion="$(versionFromGit LightBurnSoftware deployment)"
    expectedTeamID="UWZQ3LL82C"
    ;;
lightkey)
    name="Lightkey"
    type="pkgInZip"
    blockingProcesses=( "Lightkey" "Lightkey Graphics and Media" "Lightkey Networking" "Lightkey Web Content" )
    downloadURL="https://lightkeyapp.com/en/download"
    appNewVersion="$(curl -fsIL ${downloadURL} | grep -i ^location | cut -d "/" -f7 | sed 's/Lightkey-//' | tr '-' '.')"
    expectedTeamID="9466VHH352"
    ;;
linear)
    name="Linear"
    type="dmg"
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://desktop.linear.app/mac/dmg/arm64"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://desktop.linear.app/mac/dmg"
    fi
    appNewVersion=$(curl -sIkL $downloadURL | sed -r '/filename=/!d;s/.*filename=(.*)$/\1/' | awk '{print $2}')
    expectedTeamID="7VZ2S3V9RV"
    versionKey="CFBundleShortVersionString"
    appName="Linear.app"
    blockingProcesses=( "Linear" )
    ;;
    
linearmouse)
    name="LinearMouse"
    type="dmg"
    downloadURL="$(downloadURLFromGit linearmouse linearmouse)"
    appNewVersion="$(versionFromGit linearmouse linearmouse)"
    expectedTeamID="C5686NKYJ7"
    ;;
livereplayer)
    name="LiveReplayer"
    type="pkg"
    downloadURL=$(curl -fsL https://fsm-livereplayer.s3.amazonaws.com/update/stable/latest.json | grep package-url | grep -o "https:.*.pkg")
    appNewVersion=$(echo ${downloadURL} | grep -o "LiveReplayer-.*" | grep -o "[0-9].*[0-9]")
    expectedTeamID="2H7P9E934F"
    ;;
lmstudio)
    name="LM Studio"
    type="dmg"
    appNewVersion=$(curl -fsL "https://versions-prod.lmstudio.ai/update/darwin/arm64/latest" | plutil -extract version raw -)
    appBuild=$(curl -fsL "https://versions-prod.lmstudio.ai/update/darwin/arm64/${appNewVersion}" | plutil -extract build raw -)
    downloadURL="https://installers.lmstudio.ai/darwin/arm64/${appNewVersion}-${appBuild}/LM-Studio-${appNewVersion}-${appBuild}-arm64.dmg"
    expectedTeamID="D65G88RHWN"
    ;;
logitechghub|\
logighub)
    name="Logi G-HUB"
    appName="lghub.app"
    archiveName="lghub_installer.zip"
    installerTool="lghub_installer.app"
    type="zip"
    versionKey="CFBundleVersion"
    onlineHTMLinfo=$(curl -fs https://support.logi.com/api/v2/help_center/en-us/articles.json\?label_names\=webcontent\=productdownload,webproduct\=b972df0c-7db0-11e9-b911-fb4b2d0df96c,webos\=mac-macos-x-15.0 | jq -r '.articles|sort_by(.id)|map(select(.name=="Logitech G HUB")).[].body')
    downloadURL=$(echo ${onlineHTMLinfo} | xmllint --html --xpath 'string(//div/div/ul/div/a/@href)' -)
    appNewVersion=$(echo ${onlineHTMLinfo} | grep "Software Version" | grep -o "[0-9].*[0-9]" | sort | tail -1)
    CLIInstaller="lghub_installer.app/Contents/MacOS/lghub_installer"
    CLIArguments=(--silent)
    expectedTeamID="QED4VVPZWA"
    ;;
logioptions|\
logitechoptions)
    name="Logi Options"
    type="pkgInZip"
    #downloadURL=$(curl -fs "https://support.logi.com/api/v2/help_center/en-us/articles.json?label_names=webcontent=productdownload,webos=mac-macos-x-11.0" | tr "," "\n" | grep -A 10 "macOS" | grep -oie "https.*/.*/options/.*\.zip" | head -1)
    downloadURL="https://download01.logi.com/web/ftp/pub/techsupport/options/options_installer.zip"
    appNewVersion=$(curl -fs "https://support.logi.com/api/v2/help_center/en-us/articles.json?label_names=webcontent=productdownload,webos=mac-macos-x-11.0" | tr "," "\n" | grep -A 10 "macOS" | grep -B 5 -ie "https.*/.*/options/.*\.zip" | grep "Software Version" | sed 's/\\u[0-9a-z][0-9a-z][0-9a-z][0-9a-z]//g' | grep -ioe "Software Version.*[0-9.]*" | tr "/" "\n" | grep -oe "[0-9.]*" | head -1)
    #pkgName="LogiMgr Installer "*".app/Contents/Resources/LogiMgr.pkg"
    pkgName=LogiMgr.pkg
    expectedTeamID="QED4VVPZWA"
    ;;
logitechoptionsplus)
    name="Logi Options+"
    appName="logioptionsplus.app"
    archiveName="logioptionsplus_installer.zip"
    installerTool="logioptionsplus_installer.app"
    type="zip"
    downloadURL="https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer.zip"
    # Latest version of Logi Options+ requires macOS 13+
    # If older macOS is specified in the url for appNewVersion, it will never correspond to the installed version
    appNewVersion=$(curl -fs "https://support.logi.com/api/v2/help_center/en-us/articles.json?label_names=webcontent=productdownload,webos=mac-macos-x-13.0" | tr "," "\n" | grep -A 10 "macOS" | grep -B 5 -ie "https.*/.*/optionsplus/.*\.zip" | grep "Software Version" | sed 's/\\u[0-9a-z][0-9a-z][0-9a-z][0-9a-z]//g' | grep -ioe "Software Version.*[0-9.]*" | tr "/" "\n" | grep -oe "[0-9.]*" | head -1)
    CLIInstaller="logioptionsplus_installer.app/Contents/MacOS/logioptionsplus_installer"
    CLIArguments=(--quiet)
    expectedTeamID="QED4VVPZWA"
    ;;
logitechoptionsplusoffline)
    name="Logi Options+"
    appName="logioptionsplus.app"
    archiveName="logioptionsplus_installer_offline.zip"
    installerTool="logioptionsplus_installer_offline.app"
    type="zip"
    downloadURL="https://download01.logi.com/web/ftp/pub/techsupport/optionsplus/logioptionsplus_installer_offline.zip"
    # Latest version of Logi Options+ requires macOS 13+
    # If older macOS is specified in the url for appNewVersion, it will never correspond to the installed version
    appNewVersion=$(curl -fs "https://support.logi.com/api/v2/help_center/en-us/articles.json?label_names=webcontent=productdownload,webos=mac-macos-x-13.0" | tr "," "\n" | grep -A 10 "macOS" | grep -B 5 -ie "https.*/.*/optionsplus/.*\.zip" | grep "Software Version" | sed 's/\\u[0-9a-z][0-9a-z][0-9a-z][0-9a-z]//g' | grep -ioe "Software Version.*[0-9.]*" | tr "/" "\n" | grep -oe "[0-9.]*" | head -1)
    CLIInstaller="logioptionsplus_installer_offline.app/Contents/MacOS/logioptionsplus_installer"
    CLIArguments=(--quiet)
    expectedTeamID="QED4VVPZWA"
    ;;
logitune)
    name="LogiTune"
    archiveName="LogiTuneInstaller.dmg"
    appName="LogiTuneInstaller.app"
    type="dmg"
    downloadURL="https://software.vc.logitech.com/downloads/tune/LogiTuneInstaller.dmg"
    appNewVersion=$(curl -fs "https://support.logi.com/api/v2/help_center/en-us/articles.json?label_names=webcontent=productdownload,webos=mac-macos-x-11.0" | tr "," "\n" | grep -A 10 "macOS" | grep -B 5 -ie "https.*/.*/optionsplus/.*\.zip" | grep "Software Version" | sed 's/\\u[0-9a-z][0-9a-z][0-9a-z][0-9a-z]//g' | grep -ioe "Software Version.*[0-9.]*" | tr "/" "\n" | grep -oe "[0-9.]*" | head -1)
    CLIInstaller="LogiTuneInstaller.app/Contents/MacOS/LogiTuneInstaller"
    CLIArguments=(-silent)
    expectedTeamID="QED4VVPZWA"
    ;;
lucidlink)
    name="LucidLink"
    # https://www.lucidlink.com/download
    type="pkg"
    downloadURL="https://www.lucidlink.com/download/new-ll-latest/macos/stable/"
    appNewVersion=$( curl -fsIL "${downloadURL}" | grep -i "^location" | tail -1 | awk '{print $2}' | sed -E 's/.*\/[a-zA-Z]*-([0-9.]*)\..*/\1/g' )
    expectedTeamID="Y4KMJPU2B4"
    blockingProcesses=( "LucidLink" )
    ;;
lucidlinkclassic)
    name="Lucid"
    # https://www.lucidlink.com/download#other-platforms-classic
    type="pkg"
    downloadURL="https://www.lucidlink.com/download/latest/osx/stable/"
    appNewVersion=$( curl -fsIL "${downloadURL}" | grep -i "^location" | tail -1 | awk '{print $2}' | sed -E 's/.*\/[a-zA-Z]*-([0-9.]*)\..*/\1/g' )
    expectedTeamID="Y4KMJPU2B4"
    blockingProcesses=( "Lucid" )
    ;;
macfuse)
    name="FUSE for macOS"
    type="pkgInDmg"
    pkgName="Install macFUSE.pkg"
    downloadURL=$(downloadURLFromGit osxfuse osxfuse)
    appNewVersion=$(versionFromGit osxfuse osxfuse)
    appCustomVersion(){ if [ -f "/Library/Filesystems/macfuse.fs/Contents/Info.plist" ]; then defaults read /Library/Filesystems/macfuse.fs/Contents/Info.plist CFBundleShortVersionString; fi}
    expectedTeamID="3T5GSNBU6W"
    ;;
masterfader)
#credit: @sintichn macadmins slack
name="MasterFader"
type="dmg"
appNewVersion="$(curl -sf https://mackie.com/en/products/mixers/master-fader/master_fader.html | grep -m 1 "macOS" | sed -n 's/.*Fader \([0-9]\)\.\([0-9]\).*/\1_\2_/p')"
downloadURL="https://mackie.com/img/file_resources/Master_Fader_v"$appNewVersion"Setup.dmg"
expectedTeamID="6X5AC85L48"
;;
macports)
    name="MacPorts"
    type="pkg"
    #buildVersion=$(uname -r | cut -d '.' -f 1)
    case $(uname -r | cut -d '.' -f 1) in
        25)
            archiveName="Tahoe.pkg"
            ;;
	    24)
	        archiveName="Sequoia.pkg"
	        ;;
        23)
            archiveName="Sonoma.pkg"
            ;;
        22)
            archiveName="Ventura.pkg"
            ;;
        21)
            archiveName="Monterey.pkg"
            ;;
        20)
            archiveName="BigSur.pkg"
            ;;
        19)
            archiveName="Catalina.pkg"
            ;;
        *)
            cleanupAndExit 98 "Mac Ports label does not support this version of darwin."
            ;;
    esac
    downloadURL=$(downloadURLFromGit macports macports-base)
    appNewVersion=$(versionFromGit macports macports-base)
    appCustomVersion(){ if [ -x /opt/local/bin/port ]; then /opt/local/bin/port version | awk '{print $2}'; fi }
    updateTool="/opt/local/bin/port"
    updateToolArguments="selfupdate"
    expectedTeamID="QTA3A3B7F3"
    ;;
maxonapp)
    name="Maxon"
    type="dmg"
    versionKey="CFBundleShortVersionString"
    appNewVersion="$(curl -s "https://packages.maxon.net/manifests?platform=macos&org=maxon&type=products&family=fuse" | tr '{' '\n' | tr ',' '\n' | tr '}' '\n' | grep "version" | awk -F'"' '{print $4}' | sort -gr | head -n 1)"
    downloadURL="https://mx-app-blob-prod.maxon.net/mx-package-production/website/macos/maxon/maxonapp/releases/${appNewVersion}/Maxon_App_${appNewVersion}_Mac.dmg"
    installerTool="Maxon App Installer.app"
    CLIInstaller="Maxon App Installer.app/Contents/MacOS/installbuilder.sh"
    CLIArguments=(--mode unattended --unattendedmodeui none)
    expectedTeamID="4ZY22YGXQG"
    ;;
microsoft365copilot)
    name="Microsoft 365 Copilot"
    type="pkg"
    downloadURL="https://go.microsoft.com/fwlink/?linkid=2325438"
    versionKey="CFBundleVersion"
    appNewVersion=$(curl -fsIL "$downloadURL" | grep -i location: | grep -o "/Microsoft_365_Copilot.*pkg" | sed -E 's/.*_([0-9]+\.[0-9]+\.[0-9]+)_.*\.pkg/\1/')
    expectedTeamID="UBF8T346G9"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps MSCP10 )
    ;;
microsoftautoupdate)
    name="Microsoft AutoUpdate"
    type="pkg"
    downloadURL="https://go.microsoft.com/fwlink/?linkid=830196"
    versionKey="CFBundleVersion"
    appNewVersion=$(curl -fsIL "$downloadURL" | grep -i location: | grep -o "Microsoft_AutoUpdate.*pkg" | sed -E 's/[a-zA-Z_]*_([0-9.]*)_.*/\1/g')
    expectedTeamID="UBF8T346G9"
    # commented the updatetool for MSAutoupdate, because when Autoupdate is really
    # old or broken, you want to force a new install
    #updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    #updateToolArguments=( --install --apps MSau04 )
    ;;
microsoftazuredatastudio|\
azuredatastudio)
    name="Azure Data Studio"
    type="zip"
    downloadURL=$( curl -sL https://github.com/microsoft/azuredatastudio/releases/latest | grep 'Universal' | grep -Eo "(http|https)://[a-zA-Z0-9./?=_%:-]*" | head -1 )
    appNewVersion=$(versionFromGit microsoft azuredatastudio )
    expectedTeamID="UBF8T346G9"
    ;;
microsoftazurestorageexplorer)
    name="Microsoft Azure Storage Explorer"
    type="zip"
    if [[ $(arch) == arm64 ]]; then
        archiveName="StorageExplorer-darwin-arm64.zip"
    elif [[ $(arch) == i386 ]]; then
        archiveName="StorageExplorer-darwin-x64.zip" 
    fi
    downloadURL=$(downloadURLFromGit microsoft AzureStorageExplorer )
    appNewVersion=$(versionFromGit microsoft AzureStorageExplorer )
    expectedTeamID="UBF8T346G9"
    ;;
microsoftcompanyportal)
    name="Company Portal"
    type="pkg"
    MAUSource="https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409IMCP01.xml"
    downloadURL=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Location"]/following-sibling::string[1]/text()' - | sed 's/-Upgrade/-Installer/' 2>/dev/null)
    appNewVersion=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Update Version"]/following-sibling::string[1]/text()' - 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    versionKey="CFBundleVersion"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps IMCP01 )
    ;;
microsoftdefender|\
microsoftdefenderatp)
    name="Microsoft Defender"
    type="pkg"
    MAUSource="https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409WDAV00.xml"
    downloadURL=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Location"]/following-sibling::string[1]/text()' - | sed 's/-upgrade//' 2>/dev/null)
    appNewVersion=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Update Version"]/following-sibling::string[1]/text()' - 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps WDAV00 )
    ;;
microsoftedge|\
microsoftedgeconsumerstable|\
microsoftedgeenterprisestable)
    name="Microsoft Edge"
    type="pkg"
    downloadURL="https://go.microsoft.com/fwlink/?linkid=2093504"
    appNewVersion=$(curl -fsIL "$downloadURL" | grep -i location: | grep -o "/MicrosoftEdge.*pkg" | sed -E 's/.*\/[a-zA-Z]*-([0-9.]*)\..*/\1/g')
    expectedTeamID="UBF8T346G9"
    ;;
microsoftexcel)
    name="Microsoft Excel"
    type="pkg"
    MAUSource="https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409XCEL2019.xml"
    downloadURL=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="FullUpdaterLocation"]/following-sibling::string[1]/text()' - | sed 's/_Updater/_Installer/' 2>/dev/null)
    appNewVersion=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Update Version"]/following-sibling::string[1]/text()' - 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    versionKey="CFBundleVersion"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    blockingProcesses=( "Microsoft Excel" )
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps XCEL2019 )
    ;;
microsoftexcelreset)
    name="Microsoft Excel Reset"
    type="pkg"
    packageID="com.microsoft.reset.Excel"
    downloadURL="https://office-reset.com"$(curl -fs https://office-reset.com/macadmins/ | grep -o -i "href.*\".*\"*Excel_Reset.*.pkg" | cut -d '"' -f2)
    expectedTeamID="QGS93ZLCU7"
    ;;
microsoftlicenseremovaltool)
    # credit: Isaac Ordonez (@isaac) macadmins slack
    name="Microsoft License Removal Tool"
    type="pkg"
    downloadURL="https://go.microsoft.com/fwlink/?linkid=849815"
    expectedTeamID="QGS93ZLCU7"
    appNewVersion=$(curl -is "$downloadURL" | grep ocation: | grep -o "Microsoft_.*pkg" | cut -d "_" -f 5 | cut -d "." -f1-2)
    Company="Microsoft"
    ;;
microsoftlicensereset)
    name="Microsoft License Reset"
    type="pkg"
    packageID="com.microsoft.reset.Credentials"
    downloadURL="https://office-reset.com"$(curl -fs https://office-reset.com/macadmins/ | grep -o -i "href.*\".*\"*License_Reset.*.pkg" | cut -d '"' -f2)
    expectedTeamID="QGS93ZLCU7"
    ;;
microsoftoffice365)
    name="MicrosoftOffice365"
    type="pkg"
    packageID="com.microsoft.pkg.licensing"
    downloadURL="https://go.microsoft.com/fwlink/?linkid=525133"
    appNewVersion=$(curl -fsIL "$downloadURL" | grep -i location: | grep -o "/Microsoft_.*pkg" | cut -d "_" -f 5)
    expectedTeamID="UBF8T346G9"
    # using MS PowerPoint as the 'stand-in' for the entire suite
    #appName="Microsoft PowerPoint.app"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    blockingProcesses=( "Microsoft AutoUpdate" "Microsoft Word" "Microsoft PowerPoint" "Microsoft Excel" "Microsoft OneNote" "Microsoft Outlook" "OneDrive" )
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install )
    ;;
microsoftofficebusinesspro)
    name="MicrosoftOfficeBusinessPro"
    type="pkg"
    downloadURL="https://go.microsoft.com/fwlink/?linkid=2009112"
    appNewVersion=$(curl -fsIL "$downloadURL" | grep -i location: | grep -o "/Microsoft_.*pkg" | cut -d "_" -f 3)
    expectedTeamID="UBF8T346G9"
    # using MS PowerPoint as the 'stand-in' for the entire suite
    appName="Microsoft PowerPoint.app"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    blockingProcesses=( "Microsoft AutoUpdate" "Microsoft Word" "Microsoft PowerPoint" "Microsoft Excel" "Microsoft OneNote" "Microsoft Outlook" "OneDrive" "Teams")
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install )
    ;;
microsoftofficefactoryreset)
    name="Microsoft Office Factory Reset"
    type="pkg"
    packageID="com.microsoft.reset.Factory"
    downloadURL="https://office-reset.com"$(curl -fs https://office-reset.com/macadmins/ | grep -o -i "href.*\".*\"*Factory_Reset.*.pkg" | cut -d '"' -f2)
    expectedTeamID="QGS93ZLCU7"
    ;;
microsoftofficeremoval)
    name="Microsoft Office Removal"
    type="pkg"
    packageID="com.microsoft.remove.Office"
    downloadURL="https://office-reset.com"$(curl -fs https://office-reset.com/macadmins/ | grep -o -i "href.*\".*\"*Office_Removal.*.pkg" | cut -d '"' -f2)
    expectedTeamID="QGS93ZLCU7"
    ;;
microsoftonedrive-deferred)
    # This version should match the Enterprise (Deferred) version setting of OneDrive update channel. So only use this label if that is the channel you use for OneDrive. For default update settings use label “microsoftonedrive”.
    # https://support.microsoft.com/en-us/office/onedrive-release-notes-845dcf18-f921-435e-bf28-4e24b95e5fc0#OSVersion=Mac
    name="OneDrive"
    type="pkg"
    downloadURL="https://go.microsoft.com/fwlink/?linkid=861009"
    #appNewVersion=$(curl -fs https://macadmins.software/latest.xml | xpath '//latest/package[id="com.microsoft.onedrive.standalone"]/cfbundleshortversionstring' 2>/dev/null | sed -E 's/<cfbundleshortversionstring>([0-9.]*)<.*/\1/')
    appNewVersion=$(curl -fsIL "$downloadURL" | grep -i location: | cut -d "/" -f 6 | cut -d "." -f 1-3)
    expectedTeamID="UBF8T346G9"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps ONDR18 )
    ;;
microsoftonedrive-rollingout)
    # This version is the Rolling out version of OneDrive. Not sure what channel in OneDrive update it matches, maybe Insiders.
    # https://support.microsoft.com/en-us/office/onedrive-release-notes-845dcf18-f921-435e-bf28-4e24b95e5fc0#OSVersion=Mac
    name="OneDrive"
    type="pkg"
    downloadURL="https://go.microsoft.com/fwlink/?linkid=861011"
    #appNewVersion=$(curl -fs https://macadmins.software/latest.xml | xpath '//latest/package[id="com.microsoft.onedrive.standalone"]/cfbundleshortversionstring' 2>/dev/null | sed -E 's/<cfbundleshortversionstring>([0-9.]*)<.*/\1/')
    appNewVersion=$(curl -fsIL "$downloadURL" | grep -i location: | cut -d "/" -f 6 | cut -d "." -f 1-3)
    expectedTeamID="UBF8T346G9"
    #if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
    #    printlog "Running msupdate --list"
    #    "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    #fi
    #updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    #updateToolArguments=( --install --apps ONDR18 )
    ;;
microsoftonedrive-rollingoutdeferred)
    # This version is the Rolling out Deferred version of OneDrive. Not sure what channel in OneDrive update it matches.
    # https://support.microsoft.com/en-us/office/onedrive-release-notes-845dcf18-f921-435e-bf28-4e24b95e5fc0#OSVersion=Mac
    name="OneDrive"
    type="pkg"
    downloadURL="https://go.microsoft.com/fwlink/?linkid=861010"
    #appNewVersion=$(curl -fs https://macadmins.software/latest.xml | xpath '//latest/package[id="com.microsoft.onedrive.standalone"]/cfbundleshortversionstring' 2>/dev/null | sed -E 's/<cfbundleshortversionstring>([0-9.]*)<.*/\1/')
    appNewVersion=$(curl -fsIL "$downloadURL" | grep -i location: | cut -d "/" -f 6 | cut -d "." -f 1-3)
    expectedTeamID="UBF8T346G9"
    #if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
    #    printlog "Running msupdate --list"
    #    "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    #fi
    #updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    #updateToolArguments=( --install --apps ONDR18 )
    ;;
microsoftonedrive)
    # This version match the Last Released Production version setting of OneDrive update channel. It’s default if no update channel setting for OneDrive updates has been specified. Enterprise (Deferred) is also supported with label “microsoftonedrive-deferred”.
    # https://support.microsoft.com/en-us/office/onedrive-release-notes-845dcf18-f921-435e-bf28-4e24b95e5fc0#OSVersion=Mac
    name="OneDrive"
    type="pkg"
    MAUSource="https://oneclient.sfx.ms/Mac/Prod/b9de6823d5a66c7cc845b2dbf90f4935c002aeaf.xml"
    downloadURL=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="UniversalPkgBinaryURL"]/following-sibling::string[1]/text()' - 2>/dev/null)
    appNewVersion=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="CFBundleShortVersionString"]/following-sibling::string[1]/text()' - 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    ;;
microsoftonedrivereset)
    name="Microsoft OneDrive Reset"
    type="pkg"
    packageID="com.microsoft.reset.OneDrive"
    downloadURL="https://office-reset.com"$(curl -fs https://office-reset.com/macadmins/ | grep -o -i "href.*\".*\"*OneDrive_Reset.*.pkg" | cut -d '"' -f2)
    expectedTeamID="QGS93ZLCU7"
    ;;
microsoftonedrivesuinsiders)
    # This label uses the same XML feed that the OneDrive StandaloneUpdater tool uses to find the Insiders version of OneDrive updates.
    # Microsoft OneDrive StandaloneUpdater Insiders
    name="OneDrive"
    type="pkg"
    onedriveFeed="https://g.live.com/0USSDMC_W5T/MacODSUInsiders"
    downloadURL="$(curl -fsL "${onedriveFeed}" | grep -A1 "UniversalPkgBinaryURL" | tail -1 | cut -d'>' -f2 | cut -d'<' -f1)"
    appNewVersion="$(curl -fsL "${onedriveFeed}" | grep -A1 "CFBundleShortVersionString" | tail -1 | cut -d'>' -f2 | cut -d'<' -f1)"
    expectedTeamID="UBF8T346G9"
    ;;
microsoftonedrivesuprod)
    # This label uses the same XML feed that the OneDrive StandaloneUpdater tool uses to find the production version of OneDrive updates.
    # Microsoft OneDrive StandaloneUpdater Production
    name="OneDrive"
    type="pkg"
    onedriveFeed="https://g.live.com/0USSDMC_W5T/MacODSUProduction"
    downloadURL="$(curl -fsL "${onedriveFeed}" | grep -A1 "UniversalPkgBinaryURL" | tail -1 | cut -d'>' -f2 | cut -d'<' -f1)"
    appNewVersion="$(curl -fsL "${onedriveFeed}" | grep -A1 "CFBundleShortVersionString" | tail -1 | cut -d'>' -f2 | cut -d'<' -f1)"
    expectedTeamID="UBF8T346G9"
    ;;
microsoftonenote)
    name="Microsoft OneNote"
    type="pkg"
    MAUSource="https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409ONMC2019.xml"
    downloadURL=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="FullUpdaterLocation"]/following-sibling::string[1]/text()' - 2>/dev/null)
    appNewVersion=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Update Version"]/following-sibling::string[1]/text()' - 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    versionKey="CFBundleVersion"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    blockingProcesses=( "Microsoft OneNote" )
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps ONMC2019 )
    ;;
microsoftonenotereset)
    name="Microsoft OneNote Reset"
    type="pkg"
    packageID="com.microsoft.reset.OneNote"
    downloadURL="https://office-reset.com"$(curl -fs https://office-reset.com/macadmins/ | grep -o -i "href.*\".*\"*OneNote_Reset.*.pkg" | cut -d '"' -f2)
    expectedTeamID="QGS93ZLCU7"
    ;;
microsoftoutlook-monthly)
    name="Microsoft Outlook"
    # As macadmin.software has provided a link to a monthly edition of Outlook, I have created this label.
    # Not sure about the requirements for this label, nor if the call to msupdate should be there or not.
    type="pkg"
    downloadURL="https://go.microsoft.com/fwlink/?linkid=2228510"
    #appNewVersion=$(curl -fs https://macadmins.software/latest.xml | xpath '//latest/package[id="com.microsoft.outlook.standalone.365"]/cfbundleshortversionstring' 2>/dev/null | sed -E 's/<cfbundleshortversionstring>([0-9.]*)<.*/\1/')
    appNewVersion=$(curl -fsIL "$downloadURL" | grep -i location: | grep -o "/Microsoft_.*pkg" | cut -d "_" -f 3 | cut -d "." -f 1-2)
    expectedTeamID="UBF8T346G9"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps OPIM2019 )
    ;;
microsoftoutlook)
    name="Microsoft Outlook"
    type="pkg"
    MAUSource="https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409OPIM2019.xml"
    downloadURL=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="FullUpdaterLocation"]/following-sibling::string[1]/text()' - | sed 's/_Updater/_Installer/' 2>/dev/null)
    appNewVersion=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Update Version"]/following-sibling::string[1]/text()' - 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    versionKey="CFBundleVersion"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    blockingProcesses=( "Microsoft Outlook" )
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps OPIM2019 )
    ;;
microsoftoutlookdataremoval)
    name="Microsoft Outlook Data Removal"
    type="pkg"
    packageID="com.microsoft.remove.Outlook.Data"
    downloadURL="https://office-reset.com"$(curl -fs https://office-reset.com/macadmins/ | grep -o -i "href.*\".*\"*Outlook_Data_Removal.*.pkg" | cut -d '"' -f2)
    expectedTeamID="QGS93ZLCU7"
    ;;
microsoftoutlookreset)
    name="Microsoft Outlook Reset"
    type="pkg"
    packageID="com.microsoft.reset.Outlook"
    downloadURL="https://office-reset.com"$(curl -fs https://office-reset.com/macadmins/ | grep -o -i "href.*\".*\"*Outlook_Reset.*.pkg" | cut -d '"' -f2)
    expectedTeamID="QGS93ZLCU7"
    ;;
microsoftpowerpoint)
    name="Microsoft PowerPoint"
    type="pkg"
    MAUSource="https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409PPT32019.xml"
    downloadURL=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="FullUpdaterLocation"]/following-sibling::string[1]/text()' - | sed 's/_Updater/_Installer/' 2>/dev/null)
    appNewVersion=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Update Version"]/following-sibling::string[1]/text()' - 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    versionKey="CFBundleVersion"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    blockingProcesses=( "Microsoft PowerPoint" )
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps PPT32019 )
    ;;
microsoftpowerpointreset)
    name="Microsoft PowerPoint Reset"
    type="pkg"
    packageID="com.microsoft.reset.PowerPoint"
    downloadURL="https://office-reset.com"$(curl -fs https://office-reset.com/macadmins/ | grep -o -i "href.*\".*\"*PowerPoint_Reset.*.pkg" | cut -d '"' -f2)
    expectedTeamID="QGS93ZLCU7"
    ;;
microsoftremotehelp)
    name="Microsoft Remote Help"
    type="pkg"
    downloadURL="https://aka.ms/downloadremotehelpmacos"
    versionKey="CFBundleVersion"
    appNewVersion=$(curl -fsIL "${downloadURL}" | grep -i location: | grep -o "Microsoft_Remote_Help.*pkg" | sed -E 's/[a-zA-Z_]*_([0-9.]*)_.*/\1/g')
    expectedTeamID="UBF8T346G9"
    ;;
microsoftsharepointplugin)
    # Microsoft has marked this "oldpackage", should probably not be used anymore
    name="MicrosoftSharePointPlugin"
    type="pkg"
    downloadURL="https://go.microsoft.com/fwlink/?linkid=800050"
    #appNewVersion=$(curl -fs https://macadmins.software/latest.xml | xpath '//latest/oldpackage[id="com.microsoft.sharepointplugin.standalone"]/version' 2>/dev/null | sed -E 's/<version>([0-9.]*) .*/\1/')
    expectedTeamID="UBF8T346G9"
    # TODO: determine blockingProcesses for SharePointPlugin
    ;;
microsoftskypeforbusiness)
    name="Skype for Business"
    type="pkg"
    downloadURL="https://go.microsoft.com/fwlink/?linkid=832978"
    #appNewVersion=$(curl -fs https://macadmins.software/latest.xml | xpath '//latest/package[id="com.microsoft.skypeforbusiness.standalone"]/cfbundleshortversionstring' 2>/dev/null | sed -E 's/<cfbundleshortversionstring>([0-9.]*)<.*/\1/')
    appNewVersion=$(curl -fsIL "$downloadURL" | grep -i location: | sed -E 's/.*\/[a-zA-Z]*-([0-9.]*)\..*/\1/g')
    expectedTeamID="UBF8T346G9"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps MSFB16 )
    ;;
microsoftskypeforbusinessremovaltool)
    name="Skype for Business Removal"
    type="pkg"
    packageID="com.microsoft.remove.SkypeForBusiness"
    downloadURL="https://office-reset.com"$(curl -fs https://office-reset.com/macadmins/ | grep -o -i "href.*\".*\"*SkypeForBusiness_Removal.*.pkg" | cut -d '"' -f2)
    expectedTeamID="QGS93ZLCU7"
    ;;
microsoftteams-rollingout)
    name="Microsoft Teams"
    type="pkg"
    packageID="com.microsoft.teams2"
    # Fetch the latest version number from the Microsoft documentation page
    appNewVersion=$(curl -s https://learn.microsoft.com/en-us/officeupdates/teams-app-versioning | awk '/<h4 id="mac">Mac<\/h4>/,/<\/table>/' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
    downloadURL="https://statics.teams.cdn.office.net/production-osx/${appNewVersion}/MicrosoftTeams.pkg"
    expectedTeamID="UBF8T346G9"
    blockingProcesses=( Teams MSTeams "Microsoft Teams" "Microsoft Teams WebView" "Microsoft Teams WebView Helper" "Microsoft Teams Launcher" "Microsoft Teams (work preview)" "Microsoft Teams classic Helper" "com.microsoft.teams2.respawn")
    # msupdate requires a PPPC profile pushed out from Jamf to work, https://github.com/pbowden-msft/MobileConfigs/tree/master/Jamf-MSUpdate
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps TEAMS21 ) # --wait 600
    ;;
microsoftteamsclassic|\
microsoftteams)
    name="Microsoft Teams classic"
    type="pkg"
    #packageID="com.microsoft.teams"
    downloadURL="https://go.microsoft.com/fwlink/?linkid=869428"
    appNewVersion=$(curl -fsIL "${downloadURL}" | grep -i "^location" | tail -1 | cut -d "/" -f5)
    versionKey="CFBundleGetInfoString"
    expectedTeamID="UBF8T346G9"
    blockingProcesses=( Teams "Microsoft Teams classic Helper" )
    # msupdate requires a PPPC profile pushed out from Jamf to work, https://github.com/pbowden-msft/MobileConfigs/tree/master/Jamf-MSUpdate
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps TEAMS10 ) # --wait 600 #TEAM01
    ;;
microsoftteamsnew)
    name="Microsoft Teams"
    type="pkg"
    MAUSource="https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409TEAMS21.xml"
    downloadURL=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Location"]/following-sibling::string[1]/text()' - 2>/dev/null )
    appNewVersion=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Update Version"]/following-sibling::string[1]/text()' - 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    blockingProcesses=( MSTeams "Microsoft Teams" "Microsoft Teams WebView" "Microsoft Teams Launcher" "Microsoft Teams (work preview)")
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps TEAMS21 )
    ;;
microsoftteamsreset)
    name="Microsoft Teams Reset"
    type="pkg"
    packageID="com.microsoft.reset.Teams"
    downloadURL="https://office-reset.com"$(curl -fs https://office-reset.com/macadmins/ | grep -o -i "href.*\".*\"*Teams_Reset.*.pkg" | cut -d '"' -f2)
    expectedTeamID="QGS93ZLCU7"
    ;;
microsoftwindowsapp|\
microsoftremotedesktop)
    name="Windows App"
    type="pkg"
    MAUSource="https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409MSRD10.xml"
    downloadURL=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Location"]/following-sibling::string[1]/text()' - | sed 's/_updater/_installer/' 2>/dev/null)
    appNewVersion=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Title"]/following-sibling::string[1]/text()' - | grep -oE '[\.0-9]*' 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" && $DEBUG -eq 0 ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps MSRD10 )
    ;;
microsoftword)
    name="Microsoft Word"
    type="pkg"
    MAUSource="https://res.public.onecdn.static.microsoft/mro1cdnstorage/C1297A47-86C4-4C1F-97FA-950631F94777/MacAutoupdate/0409MSWD2019.xml"
    downloadURL=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="FullUpdaterLocation"]/following-sibling::string[1]/text()' - | sed 's/_Updater/_Installer/' 2>/dev/null)
    appNewVersion=$(curl -fsL $MAUSource | xmllint --xpath '//array/dict[1]/key[text()="Update Version"]/following-sibling::string[1]/text()' - 2>/dev/null)
    expectedTeamID="UBF8T346G9"
    versionKey="CFBundleVersion"
    if [[ -x "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" && $INSTALL != "force" ]]; then
        printlog "Running msupdate --list"
        "/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate" --list
    fi
    blockingProcesses=( "Microsoft Word" )
    updateTool="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/msupdate"
    updateToolArguments=( --install --apps MSWD2019 )
    ;;
microsoftwordreset)
    name="Microsoft Word Reset"
    type="pkg"
    packageID="com.microsoft.reset.Word"
    downloadURL="https://office-reset.com"$(curl -fs https://office-reset.com/macadmins/ | grep -o -i "href.*\".*\"*Word_Reset.*.pkg" | cut -d '"' -f2)
    expectedTeamID="QGS93ZLCU7"
    ;;
miniconda)
    type="pkg"
	packageID="io.continuum.pkg.prepare_installation io.continuum.pkg.run_installation io.continuum.pkg.pathupdate"
    if [[ $(arch) == arm64 ]]; then
		name="Miniconda3-latest-MacOSX-arm64"
		downloadURL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.pkg"
	elif [[ $(arch) == i386 ]]; then
		name="Miniconda3-latest-MacOSX-x86_64"
		downloadURL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.pkg"
	fi
    expectedTeamID="Z5788K4JT7"
    ;;
miro)
    # credit: @matins
    name="Miro"
    type="dmg"
    if [[ $(arch) == arm64 ]]; then
        downloadURL="https://desktop.miro.com/platforms/darwin-arm64/Install-Miro.dmg"
    elif [[ $(arch) == i386 ]]; then
        downloadURL="https://desktop.miro.com/platforms/darwin/Install-Miro.dmg"
    fi
    expectedTeamID="M3GM7MFY7U"
    ;;
motion)
    name="Motion"
    type="zip"
    downloadURL="$(downloadURLFromGit usemotion desktopapp)"
    appNewVersion="$(versionFromGit usemotion desktopapp)"
    expectedTeamID="6J5V225MV6"
    ;;
mountainduck)
    name="Mountain Duck"
    type="zip"
    downloadURL=$(curl -fs https://version.mountainduck.io/changelog.rss | xpath '//rss/channel/item/enclosure/@url' 2>/dev/null | cut -d '"' -f 2)
    appNewVersion=$(curl -fs https://version.mountainduck.io/changelog.rss | xpath '//rss/channel/item/enclosure/@sparkle:shortVersionString' 2>/dev/null | cut -d '"' -f 2)
    expectedTeamID="G69SCX94XU"
    ;;
nodejs)
    name="nodejs"
    type="pkg"
    appNewVersion=$(curl -s -L https://nodejs.org/dist/latest/ | sed -nE 's|.*>node-(.*)\.pkg</a>.*|\1|p')
    appCustomVersion(){/usr/local/bin/node -v}
    downloadURL="https://nodejs.org/dist/latest/node-$(curl -s -L https://nodejs.org/dist/latest/ | sed -nE 's|.*>node-(.*)\.pkg</a>.*|\1|p').pkg"
    expectedTeamID="HX7739G8FX"
    ;;
nodejslts)
    name="nodejs"
    type="pkg"
    appNewVersion=$(curl -fsL https://nodejs.org/en | xmllint --html --xpath '//a[contains(text(),"LTS")]/@href' - 2>/dev/null | grep -oE 'v[0-9]+(\.[0-9]+)*' | head -1)
    downloadURL="https://nodejs.org/dist/$appNewVersion/node-$appNewVersion.pkg"
    appCustomVersion(){/usr/local/bin/node -v}
    expectedTeamID="HX7739G8FX"
    ;;
notion)
    name="Notion"
    type="dmg"
    downloadURL="https://www.notion.so/desktop/mac/download"
    appNewVersion=$(curl -fsIL "https://www.notion.so/desktop/mac/download" | grep -i "^location" | awk '{print $2}' | sed -e 's/.*Notion-\(.*\).dmg.*/\1/' | cut -d '-' -f 1)
    expectedTeamID="LBQJ96FQ8D"
    ;;
omnigraffle7)
    name="OmniGraffle"
    type="dmg"
    downloadURL=$(curl -fs "https://update.omnigroup.com/appcast/com.omnigroup.OmniGraffle7" | xpath '(//rss/channel/item/enclosure/@url)[1]' 2>/dev/null | cut -d '"' -f 2)
    appNewVersion=$( echo "${downloadURL}" | sed -E 's/.*\/[a-zA-Z]*-([0-9.]*)\..*/\1/g' )
    expectedTeamID="34YW5XSRB7"
    ;;
openvpnconnect)
    # credit: Erik Stam (@erikstam)
    name="OpenVPN"
    type="pkgInDmg"
    pkgName="OpenVPN_Connect_Installer_signed.pkg"
    downloadURL="https://openvpn.net/downloads/openvpn-connect-v2-macos.dmg"
    expectedTeamID="ACV7L3WCD8"
    ;;
openvpnconnectv3)
    # credit: @lotnix
    name="OpenVPN Connect"
    type="pkgInDmg"
    if [[ $(arch) == "arm64" ]]; then
        pkgName="OpenVPN_Connect_[0-9_()]*_arm64_Installer_signed.pkg"
    elif [[ $(arch) == "i386" ]]; then
        pkgName="OpenVPN_Connect_[0-9_()]*_x86_64_Installer_signed.pkg"
    fi
    appNewVersion=$(curl -fs "https://openvpn.net/vpn-server-resources/openvpn-connect-for-macos-change-log/" | grep -i ">Release notes for " | grep -v beta | head -n 1 | sed "s|.*for \(.*\) .*|\\1|")
    downloadURL="https://openvpn.net/downloads/openvpn-connect-v3-macos.dmg"
    curlOptions=( -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Safari/605.1.15" )
    expectedTeamID="ACV7L3WCD8"
    ;;
opera)
    name="Opera"
    type="dmg"
    downloadURL="$(curl -fsIL $(curl -fsL $(curl -fsI "https://download.opera.com/download/get/?partner=www&opsys=MacOS" | grep -i "^location" | awk '{print $2}' | tr -d '\r') | grep -oE "https:\/\/download\.opera\.com\/[^\"]*" | sed 's/\&amp\;/\&/g') | grep -i "^location" | awk '{print $2}' | tr -d '\r')"
    appNewVersion="$(printf "$downloadURL" | sed -E 's/https.*\/([0-9.]*)\/mac\/.*/\1/')"
	versionKey="CFBundleVersion"
    expectedTeamID="A2P9LX4JPN"
    ;;
orcaslicer)
    name="OrcaSlicer"
    type="dmg"
    if [[ $(arch) == "arm64" ]]; then
       downloadURL="$(downloadURLFromGit SoftFever OrcaSlicer)"
       appNewVersion="$(versionFromGit SoftFever OrcaSlicer)"
       archiveName="OrcaSlicer_Mac_arm64_*.dmg"
    elif [[ $(arch) == "i386" ]]; then
      downloadURL="$(downloadURLFromGit SoftFever OrcaSlicer)"
      appNewVersion="$(versionFromGit SoftFever OrcaSlicer)"
      archiveName="OrcaSlicer_Mac_x86_64_*.dmg"
    fi
    expectedTeamID="XQK7C38HH5"
    ;;
    
pandoc)
    name="Pandoc"
    type="pkg"
    packageID="net.johnmacfarlane.pandoc"
    downloadURL=$(downloadURLFromGit jgm pandoc )
    appNewVersion=$(versionFromGit jgm pandoc )
    archiveName="mac.pkg"
    expectedTeamID="5U2WKE6DES"
    ;;
parsec)
    name="Parsec"
    type="pkg"
    downloadURL="https://builds.parsecgaming.com/package/parsec-macos.pkg"
    appNewVersion=$(curl -fsL https://parsec.app/changelog.xml | xmllint -xpath '//*[local-name()="build"]/text()' - | grep -oE '\d+-\d+$' | head -1 | sed -r 's/([0-9]+)-([0-9]+)/\1.\2.0/')
    expectedTeamID="Y9MY52XZDB"
    ;;
postman)
    name="Postman"
    type="zip"
    curlOptions=( -H "accept-encoding: gzip, deflate, br")
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://dl.pstmn.io/download/latest/osx_arm64"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://dl.pstmn.io/download/latest/osx_64"
    fi
    appNewVersion=$(getJSONValue "$(curl -fsL 'https://mkt.cdn.postman.com/www-next/release-notes/app-release-notes.json')" 'notes[0].version')
    expectedTeamID="H7H8Q7M5CK"
    ;;
raycast)
    name="Raycast"
    type="dmg"
    downloadURL="https://www.raycast.com/download"
    appNewVersion="$( curl -fsIL "https://www.raycast.com/download" | grep -i ^location | grep Raycast_ | sed 's/^.*[^0-9]\([0-9]*\.[0-9]*\.[0-9]*\).*$/\1/' )"
    expectedTeamID="SY64MV22J9"
    ;;
realvncviewer)
    name="Real VNC Viewer"
    appName="VNC Viewer.app"
    type="dmg"
    downloadURL="https://downloads.realvnc.com/download/file/viewer.files/VNC-Viewer-Latest-MacOSX-universal.dmg"
    appNewVersion="$(curl -sL https://realvnc.zendesk.com/api/v2/help_center/en-us/articles/5835892358941.json | sed -n 's/.*VNC-Viewer-\([0-9.]*\)-MacOSX.*/\1/p')"
    expectedTeamID="ZNCQ8JEH7X"
    ;;
redgiant)
    name="Red Giant"
    type="dmg"
    downloadURL=$(curl -fsL https://www.maxon.net/en/downloads | grep -oE '[^"]*redgiant/releases[^"]*\.dmg' | head -1)
    appNewVersion=$(sed -E 's/.*-([0-9.]*)-Mac\.dmg/\1/g' <<< "${downloadURL}")
    expectedTeamID="4ZY22YGXQG"
    appCustomVersion(){
        infoPlist="/Applications/Red Giant/Red Giant/uninstall.app/Contents/Info.plist"
        if [ -f "${infoPlist}" ];then
            defaults read "${infoPlist}" CFBundleVersion
        fi
    }
    installerTool="Red Giant Installer.app"
    CLIInstaller="Red Giant Installer.app/Contents/MacOS/installbuilder.sh"
    CLIArguments=( --mode unattended --unattendedmodeui none )
    ;;
redshift)
    name="redshift"
    blockingProcesses=( "Cinema 4D" )
    type="pkg"
    packageID="com.redshift3d.redshift"
    expectedTeamID="4ZY22YGXQG"
    downloadURL=$(curl -fsL https://www.maxon.net/en/downloads | grep -oE '[^"]*redshift[^"]*\.pkg' | head -1)
    appNewVersion=$(sed -n 's/.*redshift_\([^_]*\).*/\1/p' <<< "${downloadURL}")
    ;;
redshiftlite)
    name="redshift"
    blockingProcesses=( "Cinema 4D" )
    type="pkg"
    packageID="com.redshift3d.redshift"
    expectedTeamID="4ZY22YGXQG"
    downloadURL=$(curl -fsL https://www.maxon.net/en/downloads | grep -oE '[^"]*redshift[^"]*min\.pkg' | head -1)
    appNewVersion=$(sed -n 's/.*redshift_\([^_]*\).*/\1/p' <<< "${downloadURL}")
    ;;
royaltsx)
    name="Royal TSX"
    type="dmg"
    downloadURL=$(curl -fs https://royaltsx-v6.royalapps.com/updates_stable | xpath '//rss/channel/item[1]/enclosure/@url'  2>/dev/null | cut -d '"' -f 2)
    appNewVersion=$(curl -fs https://royaltsx-v6.royalapps.com/updates_stable | xpath '//rss/channel/item[1]/enclosure/@sparkle:shortVersionString'  2>/dev/null | cut -d '"' -f 2)
    expectedTeamID="VXP8K9EDP6"
    ;;
screamingfrogseospider)
    name="Screaming Frog SEO Spider"
    type="dmg"
    if [[ $(arch) == i386 ]]; then
        platform="x86_64"
    elif [[ $(arch) == arm64 ]]; then
        platform="aarch64"
    fi
    appNewVersion=$(curl -fs "https://download.screamingfrog.co.uk/products/seo-spider/getlatestversion.php")
    downloadURL="https://download.screamingfrog.co.uk/products/seo-spider/ScreamingFrogSEOSpider-${appNewVersion}-${platform}.dmg"
    expectedTeamID="CAHEVC3HZC"
    ;;
signiantapp)
    name="Signiant App"
    type="dmg"
    downloadURL="https://updates.signiant.com/signiant_app/$(curl -fs "https://updates.signiant.com/signiant_app/signiant-app-info-mac.json" | grep -o '"file": *"[^"]*"' | awk -F '"' '{print $4}')"
    appNewVersion="$(echo $downloadURL | sed -E 's/.*Signiant_App_([0-9]+(\.[0-9]+)*)\.dmg/\1/')"
    expectedTeamID="U6ZZ4QLU4Q"
    ;;
sketch)
    name="Sketch"
    type="zip"
    downloadURL=$(curl -sf https://www.sketch.com/downloads/mac/ | grep -m 1 'href="https://download.sketch.com' | tr '"' "\n" | grep -E "https.*.zip")
    appNewVersion=$(echo "$downloadURL" | awk -F'-' '{ print $2 }')
    expectedTeamID="WUGMZZ5K46"
    ;;
sketchup2024)
    name="SketchUp 2024"
    type="dmg"
    downloadURL="$(curl -s https://sketchup.trimble.com/en/download/all | grep -o 'https://download.sketchup.com/SketchUp-2024[^"]*.dmg')"
    folderName="SketchUp 2024"
    appName="${folderName}/SketchUp.app"
    appNewVersion=$(echo "$downloadURL" | grep -o 'SketchUp-20[0-9][0-9]-[0-9]*-[0-9]*' | awk -F '-' '{year=substr($2, 3, 2); if (year >= 24) printf "%d.0.%s", year, $NF; else printf "%d.%s", year+2000, $NF}')
    versionKey="CFBundleVersion"
    expectedTeamID="J8PVMCY7KL"
    ;;
sketchup2025)
    name="SketchUp 2025"
    type="dmg"
    downloadURL="$(curl -s https://sketchup.trimble.com/en/download/all | grep -o 'https://download.sketchup.com/SketchUp-2025[^"]*.dmg')"
    folderName="SketchUp 2025"
    appName="${folderName}/SketchUp.app"
    appNewVersion=$(echo "$downloadURL" | grep -o 'SketchUp-20[0-9][0-9]-[0-9]*-[0-9]*' | awk -F '-' '{year=substr($2, 3, 2); if (year >= 24) printf "%d.0.%s", year, $NF; else printf "%d.%s", year+2000, $NF}')
    versionKey="CFBundleVersion"
    expectedTeamID="J8PVMCY7KL"
    ;;
sketchup2026)
    name="SketchUp 2026"
    type="dmg"
    downloadURL="$(curl -s https://sketchup.trimble.com/en/download/all | grep -o 'https://download.sketchup.com/SketchUp-2026[^"]*.dmg')"
    folderName="SketchUp 2026"
    appName="${folderName}/SketchUp.app"
    appNewVersion=$(echo "$downloadURL" | grep -o 'SketchUp-20[0-9][0-9]-[0-9]*-[0-9]*' | awk -F '-' '{year=substr($2, 3, 2); if (year >= 24) printf "%d.0.%s", year, $NF; else printf "%d.%s", year+2000, $NF}')
    versionKey="CFBundleVersion"
    expectedTeamID="J8PVMCY7KL"
    ;;
sketchupviewer)
    name="SketchUpViewer"
    type="dmg"
    downloadURL="$(curl -Lfs https://www.sketchup.com/en/sketchup-viewer/downloads | grep -o 'https://download.sketchup.com/SketchUpViewer[0-9\-]*.dmg')"
    expectedTeamID="J8PVMCY7KL"
    ;;
slack)
    name="Slack"
    type="pkg"
    downloadURL="https://slack.com/api/desktop.latestRelease?redirect=1&variant=pkg&arch=universal"
    appNewVersion=$( curl -fsIL "${downloadURL}" | grep -i "^location" | cut -d "/" -f7 )
    expectedTeamID="BQR82RBBHL"
    ;;
snagit2024)
    name="Snagit"
    type="dmg"
    sparkleData=$(curl -fsL -H 'User-Agent: Snagit/2024.0.0' 'https://www.techsmith.com/redirect.asp?target=sufeedurl&product=snagitmac&ver=2024.0.0&lang=enu&os=mac')
    appNewVersion=$(
        echo "$sparkleData" | \
        xmllint -xpath 'string(//*[local-name()="item"][last()]/*[local-name()="shortVersionString"]/text())' -
    )
    downloadURL=$(
        echo "$sparkleData" | \
        xmllint -xpath 'string(//*[local-name()="item"][last()]/enclosure/@url)' -
    )
    expectedTeamID="7TQL462TU8"
    ;;
snagit2025)
    name="Snagit"
    type="dmg"
    sparkleData=$(curl -fsL -H 'User-Agent: Snagit/2025.0.0' 'https://www.techsmith.com/redirect.asp?target=sparkleappcast&product=snagitmac&ver=2025.0.0&lang=enu&os=mac')
    appNewVersion=$(
        echo "$sparkleData" | \
        xmllint -xpath 'string(//*[local-name()="item"][last()]/*[local-name()="shortVersionString"]/text())' -
    )
    downloadURL=$(
        echo "$sparkleData" | \
        xmllint -xpath 'string(//*[local-name()="item"][last()]/enclosure/@url)' -
    )
    expectedTeamID="7TQL462TU8"
    ;;
snagit|\
snagit2026)
    name="Snagit"
    type="dmg"
    sparkleData=$(curl -H 'user-agent: Snagit/2026.0.0 Sparkle/2.8.0' -fsL 'https://sparkle.cloud.techsmith.com/api/v1/AppcastManifest/?version=26.0.1&utm_source=product&utm_medium=snagit&utm_campaign=sm2026&ipc_item_name=snagit&ipc_platform=macos')
    appNewVersion=$( <<<"$sparkleData" xpath '//*[local-name()="shortVersionString"] [starts-with(.,"2026.")] /text()' | tr ' ' '\n' | sort -V | tail -n1)
    downloadURL=$( <<<"$sparkleData" xpath 'string( //*[local-name()="item"] [./*[local-name()="shortVersionString"] = "'"$appNewVersion"'"] /*[local-name()="enclosure"]/@url)')
    expectedTeamID="7TQL462TU8"
    ;;
sonos|\
sonoss1)
    # credit: Erik Stam (@erikstam)
    name="Sonos S1 Controller"
    type="dmg"
    downloadURL="https://www.sonos.com/redir/controller_software_mac"
    expectedTeamID="2G4LW83Q3E"
    ;;
sonoss2)
    name="Sonos"
    type="dmg"
    downloadURL="https://www.sonos.com/redir/controller_software_mac2"
    expectedTeamID="2G4LW83Q3E"
    ;;
splashtopbusiness)
    name="Splashtop Business"
    type="pkgInDmg"
    splashtopbusinessVersions=$(curl -fsL "https://www.splashtop.com/wp-content/themes/responsive/downloadx.php?product=stb&platform=mac-client")
    downloadURL=$(curl -Ls -w %{url_effective} -o /dev/null $(getJSONValue "$splashtopbusinessVersions" "url"))
    appNewVersion="${${downloadURL#*INSTALLER_v}%*.dmg}"
    expectedTeamID="CPQQ3AW49Y"
    ;;
splashtopsos)
    name="Splashtop SOS"
    type="dmg"
    downloadURL="https://download.splashtop.com/sos/SplashtopSOS.dmg"
    expectedTeamID="CPQQ3AW49Y"
    ;;
splashtopstreamer)
    name="Splashtop Streamer"
    type="pkgInDmg"
    downloadURL=$(curl -fsLI "https://my.splashtop.com/csrs/mac" | grep -i '^location:' | tail -n 1 | cut -d ' ' -f 2 | tr -d '\r')
    appNewVersion=$(echo $downloadURL | sed -E 's/.*_v([0-9.]+).dmg/\1/')
    expectedTeamID="CPQQ3AW49Y"
    ;;
spotify)
    name="Spotify"
    type="dmg"
    if [[ $(arch) == arm64 ]]; then
        downloadURL="https://download.scdn.co/SpotifyARM64.dmg"
    elif [[ $(arch) == i386 ]]; then
        downloadURL="https://download.scdn.co/Spotify.dmg"
    fi
    expectedTeamID="2FNC3A47ZF"
    ;;
sublimemerge)
    # Home: https://www.sublimemerge.com
    # Description: Git Client, done Sublime. Line-by-line Staging. Commit Editing. Unmatched Performance.
    name="Sublime Merge"
    type="zip"
    downloadURL="$(curl -fs "https://www.sublimemerge.com/download_thanks?target=mac#direct-downloads" | grep -io "https://download.*_mac.zip" | head -1)"
    appNewVersion=$(curl -fs https://www.sublimemerge.com/download | grep -i -A 4 "id.*changelog" | grep -io "Build [0-9]*")
    expectedTeamID="Z6D26JE4Y4"
    ;;
sublimetext)
    # credit: Søren Theilgaard (@theilgaard)
    name="Sublime Text"
    type="zip"
    downloadURL="$(curl -fs "https://www.sublimetext.com/download_thanks?target=mac#direct-downloads" | grep -io "https://download.*_mac.zip" | head -1)"
    appNewVersion=$(curl -fs https://www.sublimetext.com/download | grep -i -A 4 "id.*changelog" | grep -io "Build [0-9]*")
    expectedTeamID="Z6D26JE4Y4"
    ;;
suspiciouspackage)
    name="Suspicious Package"
    type="dmg"
    downloadURL="https://mothersruin.com/software/downloads/SuspiciousPackage.dmg"
    appNewVersion=$(curl -fs "https://www.mothersruin.com/software/SuspiciousPackage/data/SuspiciousPackageVersionInfo.plist" | grep -A1 CFBundleShortVersionString | tail -1 | sed -E 's/.*>([0-9.]*)<.*/\1/g')
    expectedTeamID="936EB786NH"
    ;;
swiftruntimeforcommandlinetools)
    # Note: this installer will error on macOS versions later than 10.14.3
    name="SwiftRuntimeForCommandLineTools"
    type="pkgInDmg"
    downloadURL="https://updates.cdn-apple.com/2019/cert/061-41823-20191025-5efc5a59-d7dc-46d3-9096-396bb8cb4a73/SwiftRuntimeForCommandLineTools.dmg"
    expectedTeamID="Software Update"
    ;;
synologyactivebackupforbusinessagent)
    name="Synology Active Backup for Business Agent"
    type="pkgInDmg"
    packageID="com.synology.activebackup-agent"
    versionKey="CFBundleVersion"
    downloadURL=$(appVersion=`curl -sf https://archive.synology.com/download/Utility/ActiveBackupBusinessAgent | grep -m 1 /download/Utility/ActiveBackupBusinessAgent/ | sed "s|.*>\(.*\)<.*|\\1|"` && appShortVersion=`sed 's#.*-\(\)#\1#' <<< $appVersion` && echo https://global.download.synology.com/download/Utility/ActiveBackupBusinessAgent/"$appVersion"/Mac/x86_64/Synology%20Active%20Backup%20for%20Business%20Agent-"$appVersion".dmg)
    # appNewVersion=$(appVersionP1=`curl -sf https://archive.synology.com/download/Utility/ActiveBackupBusinessAgent | grep -m 1 /download/Utility/ActiveBackupBusinessAgent/ | sed "s|.*>\(.*\)-.*|\\1|"` && sed 's/\(.\{0\}\)./\17/' <<< $appVersionP1)
    appNewVersion=$(curl -sf https://archive.synology.com/download/Utility/ActiveBackupBusinessAgent | grep -m 1 /download/Utility/ActiveBackupBusinessAgent/ | sed "s|.*>\(.*\)<.*|\\1|" | sed "s#.*-\(\)#\1#")
    expectedTeamID="X85BAK35Y4"
    ;;
synologyassistant)
    name="SynologyAssistant"
    type="dmg"
    packageID="com.synology.DSAssistant"
    appNewVersion="$(curl -sf https://archive.synology.com/download/Utility/Assistant | grep -m 1 /download/Utility/Assistant/ | sed "s|.*>\(.*\)<.*|\\1|")"
    downloadURL="https://global.download.synology.com/download/Utility/Assistant/${appNewVersion}/Mac/synology-assistant-${appNewVersion}.dmg"
    appCustomVersion(){ strings /Applications/SynologyAssistant.app/Contents/MacOS/DSAssistant | awk '/src\/CAsstGlobalSetting.cpp/,/%1 %2/ { if ($0 !~ /src\/CAsstGlobalSetting.cpp/ && $0 !~ /%1 %2/) print }' }
    expectedTeamID="X85BAK35Y4"
    ;;
synologydriveclient)
    name="Synology Drive Client"
    type="pkgInDmg"
    # packageID="com.synology.CloudStation"
    versionKey="CFBundleVersion"
    downloadURL=$(appVersion=`curl -sf https://archive.synology.com/download/Utility/SynologyDriveClient | grep -m 1 /download/Utility/SynologyDriveClient/ | sed "s|.*>\(.*\)<.*|\\1|"` && appShortVersion=`sed 's#.*-\(\)#\1#' <<< $appVersion` && echo https://global.download.synology.com/download/Utility/SynologyDriveClient/"$appVersion"/Mac/Installer/synology-drive-client-"${appShortVersion}".dmg)
    # appNewVersion=$(appVersionP1=`curl -sf https://archive.synology.com/download/Utility/SynologyDriveClient | grep -m 1 /download/Utility/SynologyDriveClient/ | sed "s|.*>\(.*\)-.*|\\1|"` && sed 's/\(.\{0\}\)./\17/' <<< $appVersionP1)
    appNewVersion=$(curl -sf https://archive.synology.com/download/Utility/SynologyDriveClient | grep -m 1 /download/Utility/SynologyDriveClient/ | sed "s|.*>\(.*\)<.*|\\1|" | sed "s#.*-\(\)#\1#")
    expectedTeamID="X85BAK35Y4"
    ;;
tabby)
    name="Tabby"
    type="dmg"
    downloadURL="$(downloadURLFromGit Eugeny tabby)"
    appNewVersion="$(versionFromGit Eugeny tabby)"
    expectedTeamID="V4JSMC46SY"
    ;;
tableplus)
    name="TablePlus"
    type="dmg"
    downloadURL="https://tableplus.com/release/osx/tableplus_latest"
    appNewVersion=$(curl -fs https://tableplus.com/release/osx/tableplus_latest | grep -oE '[0-9]+/[^"]*TablePlus\.dmg' | grep -oE '^[0-9]+')
    versionKey="CFBundleVersion"
    expectedTeamID="3X57WP8E8V"
    ;;
    
tailscale)
    name="Tailscale"
    type="zip"
    appNewVersion="$(curl -s https://pkgs.tailscale.com/stable/ | awk -F- '/Tailscale.*macos.zip/ {print $2}')"
    downloadURL="https://pkgs.tailscale.com/stable/Tailscale-${appNewVersion}-macos.zip"
    expectedTeamID="W5364U7YZB"
    versionKey="CFBundleShortVersionString"
    ;;
teamviewer)
    name="TeamViewer"
    type="pkgInDmg"
    # packageID="com.teamviewer.teamviewer"
    versionKey="CFBundleShortVersionString"
    pkgName="Install TeamViewer.app/Contents/Resources/Install TeamViewer.pkg"
    downloadURL="https://download.teamviewer.com/download/TeamViewer.dmg"
    appNewVersion=$(curl -fs "https://www.teamviewer.com/en/download/macos/" | grep 'data-json' | grep 'full' | awk -F '"' '{ print $4 }' | sed 's/&quot;/"/g' | plutil -extract "data.0.versionNumber" raw -o - -)
    expectedTeamID="H7UGFBUGV6"
    ;;
teamviewerqs)
    # credit: Søren Theilgaard (@theilgaard)
    name="TeamViewerQS"
    type="dmg"
    downloadURL="https://download.teamviewer.com/download/TeamViewerQS.dmg"
    appNewVersion=$(curl -fs "https://www.teamviewer.com/en/download/macos/" | grep "Current version" | awk -F': ' '{ print $2 }' | sed 's/<[^>]*>//g')
    appName="TeamViewerQS.app"
    expectedTeamID="H7UGFBUGV6"
    ;;
techsmithcapture)
    # credit Elena Ackley (@elenaelago)
    name="TechSmith Capture"
    type="dmg"
    downloadURL="https://cdn.cloud.techsmith.com/techsmithcapture/mac/TechSmithCapture.dmg"
    expectedTeamID="7TQL462TU8"
    ;;
theunarchiver)
    name="The Unarchiver"
    type="dmg"
    downloadURL="https://dl.devmate.com/com.macpaw.site.theunarchiver/TheUnarchiver.dmg"
    appNewVersion="$(curl -fs "https://theunarchiver.com" | grep -i "Latest version" | head -1 | sed -E 's/.*> ([0-9.]*) .*/\1/g')"
    expectedTeamID="S8EX82NJP6"
    ;;
thunderbird)
    name="Thunderbird"
    type="dmg"
    versionKey="CFBundleShortVersionString"
    appNewVersion=$(curl -s "https://www.thunderbird.net/en-US/thunderbird/releases/atom.xml" | xmllint --xpath "//*[local-name()='entry']/*[local-name()='title'][not(contains(text(), 'esr'))]/text()" - | head -1 | awk '{ print $2 }')
    downloadURL="https://download.mozilla.org/?product=thunderbird-${appNewVersion}-SSL&os=osx&lang=en-US"
    expectedTeamID="43AQ936H96"
    ;;
thunderbird_intl)
    # This label will try to figure out the selected language of the user,
    # and install corrosponding version of Thunderbird
    name="Thunderbird"
    type="dmg"
    userLanguage=$(if [ -e "/Applications/${name}.app/Contents/Resources/locale.ini" ]; then tail -1 "/Applications/${name}.app/Contents/Resources/locale.ini" | grep "locale=" | awk -F'=' '{ print $2 }'; else runAsUser defaults read .GlobalPreferences AppleLocale | tr '_' '-'; fi)
    printlog "Found language $userLanguage to be used for $name."
    releaseURL="https://ftp.mozilla.org/pub/thunderbird/releases/latest/README.txt"
    until curl -fs $releaseURL | grep -q "=$userLanguage"; do
        if [ ${#userLanguage} -eq 2 ]; then
            break
        fi
        printlog "No locale matching '$userLanguage', trying '${userLanguage:0:2}'"
        userLanguage=${userLanguage:0:2}
    done
    printlog "Using language '$userLanguage' for download."
    downloadURL="https://download.mozilla.org/?product=thunderbird-latest&os=osx&lang=$userLanguage"
    if ! curl -sfL --output /dev/null -r 0-0 $downloadURL; then
        printlog "Download not found for '$userLanguage', using default ('en-US')."
        downloadURL="https://download.mozilla.org/?product=thunderbird-latest&os=osx"
    fi
    appNewVersion=$(curl -fsIL $downloadURL | awk -F releases/ '/Location:/ {split($2,a,"/"); print a[1]}')
    expectedTeamID="43AQ936H96"
    blockingProcesses=( thunderbird )
    ;;
thunderbirdesr)
    name="Thunderbird"
    type="dmg"
    versionKey="CFBundleShortVersionString"
    appNewVersion=$(curl -s "https://www.thunderbird.net/en-US/thunderbird/releases/atom.xml" | xmllint --xpath "//*[local-name()='entry']/*[local-name()='title'][contains(text(), 'esr')]/text()" - | head -1 | awk '{ print $2 }' | tr -d 'esr')
    downloadURL="https://download.mozilla.org/?product=thunderbird-${appNewVersion}esr-SSL&os=osx&lang=en-US"
    expectedTeamID="43AQ936H96"
    ;;
tidal)
    name="TIDAL"
    type="dmg"
    if [[ $(arch) == i386 ]]; then
        downloadURL=https://download.tidal.com/desktop/TIDAL.x64.dmg
    elif [[ $(arch) == arm64 ]]; then
        downloadURL=https://download.tidal.com/desktop/TIDAL.arm64.dmg
    fi
    appNewVersion=$(curl -fs https://support.datajar.co.uk/hc/en-us/articles/360010333638-Jamf-Auto-Update-Application-Catalog | grep -ozpEi ">TIDAL<\/td>\n<td>(.*)<" | grep -oE "((?:[0-9]+\.?)+)" | head -1)
    expectedTeamID="GK2243L7KB"
    ;;
todoist)
    name="Todoist"
    type="dmg"
    downloadURL="https://todoist.com/mac_app"
    appNewVersion="$(curl -fsIL https://todoist.com/mac_app | grep -i ^location | sed -E 's/.*\/[a-zA-Z]*-([0-9.]*)\..*/\1/g')"
    expectedTeamID="S3DD273774"
    ;;
toonboomharmonypremium2024)
    name="Harmony 24 Premium"
    type="dmg"
    # appNewVersion=$(curl -s https://docs.toonboom.com/help/harmony-24/premium/release-notes/harmony/harmony-24-release-notes.html | grep -oE 'build [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | awk '{print $2}')
    appNewVersion=$(release_notes_url=$(curl -s "https://docs.toonboom.com/help/harmony-24/premium/book/index.html" | \
    grep -o 'href="[^"]*release-notes/harmony/harmony-24[^"]*"' | \
    head -n 1 | sed -E 's/href="([^"]*)"/\1/')
    curl -s "https://docs.toonboom.com/help/harmony-24/premium/book/$release_notes_url" | \
    grep -oE 'Harmony [0-9]+\.[0-9]+\.[0-9]+, build [0-9]+' | \
    sed 's/,//g' | awk '{print $2 "." $4}')
    version=$(echo "$appNewVersion" | awk -F'.' '{print $1"."$2"."$3}')
    build=$(echo "$appNewVersion" | awk -F'.' '{print $4}')
    downloadURL="https://fileshare.toonboom.com/wl/?id=idRIztLvVCq0EZ00x01BJa6R2EqKp01R&path=${version}%2FHAR24-PRM-mac-${build}.dmg&mode=list&download=1"
    folderName="Toon Boom Harmony 24 Premium"
    appName="${folderName}/Harmony 24 Premium.app"
    versionKey="CFBundleVersion"
    expectedTeamID="U5LPYJSPQ3"
    ;;
    
toonboomharmonypremium2025)
    name="Harmony 25 Premium"
    type="dmg"
    version=$(curl -s "https://fileshare.toonboom.com/wl/?id=jyhyaYQFJ86iE6daFDh3JJv2g6OFBDza" | grep -oE '25\.[0-9]+\.[0-9]+' | sort -V | tail -1)
    build=$(curl -s "https://docs.toonboom.com/help/harmony-25/premium/release-notes/harmony/harmony-25-release-notes.html" | grep -iEo 'build[^0-9]*([0-9]{4,6})' | grep -oE '[0-9]{4,6}')
    appNewVersion=${version}${build}
    downloadURL="https://fileshare.toonboom.com/wl/?id=jyhyaYQFJ86iE6daFDh3JJv2g6OFBDza&path=${version}%2FHAR25-PRM-mac-${build}.dmg&mode=list&download=1"
    folderName="Toon Boom Harmony 25 Premium"
    appName="${folderName}/Harmony 25 Premium.app"
    versionKey="CFBundleVersion"
    expectedTeamID="U5LPYJSPQ3"
    ;;

toonboomstoryboardpro2024)
    name="Storyboard Pro 24"
    type="dmg"
    downloadURL=$(curl -s "https://updates.toonboom.com/updates.php?p=sboardPro&v=24.0.0&b=00000" | sed -n 's/.*<package platform="macos" open_in_browser="false">\([^<]*\).*/\1/p')
    folderName="Toon Boom Storyboard Pro 24"
    appName="${folderName}/Storyboard Pro 24.app"
    appNewVersion=$(curl -s "https://updates.toonboom.com/updates.php?p=sboardPro&v=24.0.0&b=00000" | xmllint --xpath 'string(//update/@version)' -)
    versionKey="CFBundleVersion"
    expectedTeamID="U5LPYJSPQ3"
    ;;
    
toonboomstoryboardpro2025)
    name="Storyboard Pro 25"
    type="dmg"
    version=$(curl -s "https://fileshare.toonboom.com/wl/?id=gXDIzUJu4BznZHs9e15WxLJdooDPu6ii" | grep -oE '25\.[0-9]+\.[0-9]+' | sort -V | tail -1)
    build=$(curl -s "https://docs.toonboom.com/help/storyboard-pro-25/storyboard/release-notes/storyboard-pro-25-release-notes.html" | grep -iEo 'build[^0-9]*([0-9]{4,6})' | grep -oE '[0-9]{4,6}')
    appNewVersion=(${version}.${build})
    downloadURL="https://fileshare.toonboom.com/wl/?id=gXDIzUJu4BznZHs9e15WxLJdooDPu6ii&path=${version}%2FSBP25-mac-${build}.dmg&mode=list&download=1"
    folderName="Toon Boom Storyboard Pro 25"
    appName="${folderName}/Storyboard Pro 25.app"
    versionKey="CFBundleVersion"
    expectedTeamID="U5LPYJSPQ3"
    ;;

topazgigapixel|\
topazgigapixelai)
    name="Topaz Gigapixel AI"
    type="pkg"
    versionKey="CFBundleShortVersionString"
    downloadURL="https://topazlabs.com/d/gigapixel/latest/mac/full"
    archiveName=$(curl -fsIL $downloadURL | grep -i ^location | awk -F "/" '{print $NF}')
    appNewVersion=$(grep -oi "[0-9].*[0-9]" <<< $archiveName)
    expectedTeamID="3G3JE37ZHF"
    ;;
topazphoto|\
topazphotoai)
    name="Topaz Photo AI"
    type="pkg"
    appNewVersion=$(curl -fs https://www.topazlabs.com/downloads | grep  -o 'photoVersion = "v.*"' | grep -o ' "v.*"' | sed -E 's/[v|"| ]//g')
    downloadURL="https://topazlabs.com/d/photo/latest/mac/full"
    archiveName="TopazPhotoAI-${appNewVersion}.pkg"
    expectedTeamID="3G3JE37ZHF"
    ;;
topazvideo|\
topazvideoai)
    name="Topaz Video AI"
    type="pkg"
    appNewVersion=$(curl -fs https://www.topazlabs.com/downloads | grep  -o 'videoVersion = "v.*"' | grep -o ' "v.*"' | sed -E 's/[v|"| ]//g')
    downloadURL="https://topazlabs.com/d/tvai/latest/mac/full"
    archiveName="TopazVideoAI-${appNewVersion}.pkg"
    expectedTeamID="3G3JE37ZHF"
    ;;
transmit5)
    name="Transmit"
    type="zip"
    downloadURL="https://download.panic.com/transmit/Transmit-5-Latest.zip"
    appNewVersion="$(curl -fsI "https://download.panic.com/transmit/Transmit-5-Latest.zip" | grep -i "^location" | sed -E 's/.*Transmit%20([0-9]+(\.[0-9]+)*)\.zip/\1/' | tr -d '\r')"
    expectedTeamID="VE8FC488U5"
    ;;

typora)
    name="Typora"
    type="dmg"
    #downloadURL="https://www.typora.io/download/Typora.dmg"
    downloadURL=$(curl -fs "https://www.typora.io/download/dev_update.xml" | xpath '(//rss/channel/item/enclosure/@url)[1]' 2>/dev/null | cut -d '"' -f2)
    #appNewVersion="$(curl -fs "https://www.typora.io/dev_release.html" | grep -o -i "h4>[0-9.]*</h4" | head -1 | sed -E 's/.*h4>([0-9.]*)<\/h4.*/\1/')"
    appNewVersion=$(curl -fs "https://www.typora.io/download/dev_update.xml" | xpath '(//rss/channel/item/enclosure/@sparkle:shortVersionString)[1]' 2>/dev/null | cut -d '"' -f2)
    expectedTeamID="9HWK5273G4"
    ;;
ultimakercura)
    name="Ultimaker Cura"
    type="dmg"
    if [[ $(arch) == "arm64" ]]; then
        archiveName="UltiMaker-Cura-[0-9.]*-macos-ARM64.dmg"
    elif [[ $(arch) == "i386" ]]; then
        archiveName="UltiMaker-Cura-[0-9.]*-macos-X64.dmg"
    fi
    downloadURL="$(downloadURLFromGit Ultimaker Cura)"
    appNewVersion=$(versionFromGit Ultimaker Cura )
    expectedTeamID="V4B3JXRRQS"
    ;;
uniconverter)
    # credit: Gabe Marchan (gabemarchan.com - @darklink87)
    name="Wondershare UniConverter"
    type="dmg"
    downloadURL="http://download.wondershare.com/video-converter-ultimate-mac_full735.dmg"
    expectedTeamID="YZC2T44ZDX"
    ;;
unityhub)
    name="Unity Hub"
    type="dmg"
    downloadURL="https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup.dmg"
    appNewVersion=$(curl -s https://unity.com/unity-hub/release-notes | grep -oE '>[0-9]+\.[0-9]+\.[0-9]+<' | head -1 | tr -d '<>')
    expectedTeamID="9QW8UQUTAA"
    ;;

veracrypt-fuse-t)
    name="VeraCrypt"
    type="pkgInDmg"
    archiveName="VeraCrypt_FUSE-T_[0-9.].*\.dmg"
    downloadURL=$(curl -sfL "https://api.github.com/repos/veracrypt/VeraCrypt/releases" | awk -F '"' "/browser_download_url/ && /$archiveName\"/ { print \$4; exit }")
    appNewVersion=$(echo "${downloadURL}" | sed -E 's/.*\/[a-zA-Z]*_FUSE-T_([0-9.]*.*)\.dmg/\1/g')
    expectedTeamID="Z933746L2S"
    ;;
veracrypt|\
veracrypt-macfuse)
    name="VeraCrypt"
    type="pkgInDmg"
    downloadURL="$(downloadURLFromGit veracrypt VeraCrypt)"
    appNewVersion="$(versionFromGit veracrypt VeraCrypt)"
    expectedTeamID="Z933746L2S"
    ;;
virtualbox)
    # credit: AP Orlebeke (@apizz)
    name="VirtualBox"
    type="pkgInDmg"
    pkgName="VirtualBox.pkg"
    downloadURL="https:$(curl -fsL "https://www.oracle.com/virtualization/technologies/vm/downloads/virtualbox-downloads.html" | grep "OSX.dmg" | xmllint --html --xpath 'string(//a/@href)' -)"
    appNewVersion=$(echo "${downloadURL}" | awk -F '/' '{print $5}')
    expectedTeamID="VB5E2TV963"
    ;;
virtualboxbeta)
    name="VirtualBox"
    type="pkgInDmg"
    pkgName="VirtualBox.pkg"
    betaVersion="$(curl -fs "https://download.virtualbox.org/virtualbox/LATEST-BETA.TXT")"
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://download.virtualbox.org/virtualbox/${betaVersion}/$(curl -fs "https://download.virtualbox.org/virtualbox/${betaVersion}/" | grep "macOSArm64" | cut -d\" -f2)"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://download.virtualbox.org/virtualbox/${betaVersion}/$(curl -fs "https://download.virtualbox.org/virtualbox/${betaVersion}/" | grep "OSX.dmg" | cut -d\" -f2)"
    fi
    appNewVersion="$(echo $betaVersion | cut -d_ -f1)"
    expectedTeamID="VB5E2TV963"
    ;;
virtualboxlatest)
    name="VirtualBox"
    type="pkgInDmg"
    pkgName="VirtualBox.pkg"
    appNewVersion=$(curl -fs "https://download.virtualbox.org/virtualbox/LATEST.TXT")
    if [[ $(arch) == "arm64" ]]; then
        downloadURL="https://download.virtualbox.org/virtualbox/${appNewVersion}/$(curl -fs "https://download.virtualbox.org/virtualbox/${appNewVersion}/" | grep "macOSArm64" | cut -d\" -f2)"
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://download.virtualbox.org/virtualbox/${appNewVersion}/$(curl -fs "https://download.virtualbox.org/virtualbox/${appNewVersion}/" | grep "OSX.dmg" | cut -d\" -f2)"
    fi
    expectedTeamID="VB5E2TV963"
    ;;
virtualboxstable)
    name="VirtualBox"
    type="pkgInDmg"
    pkgName="VirtualBox.pkg"
    appNewVersion=$(curl -fs "https://download.virtualbox.org/virtualbox/LATEST-STABLE.TXT")
    if [[ $(arch) == "arm64" ]]; then
        if [[ ! -z "$(curl -fs "https://download.virtualbox.org/virtualbox/${appNewVersion}/" | grep "macOSArm64")" ]]; then
            downloadURL="https://download.virtualbox.org/virtualbox/${appNewVersion}/$(curl -fs "https://download.virtualbox.org/virtualbox/${appNewVersion}/" | grep "macOSArm64" | cut -d\" -f2)"
        else 
            downloadURL="https://download.virtualbox.org/virtualbox/${appNewVersion}/$(curl -fs "https://download.virtualbox.org/virtualbox/${appNewVersion}/" | grep "OSX.dmg" | cut -d\" -f2)"
        fi
    elif [[ $(arch) == "i386" ]]; then
        downloadURL="https://download.virtualbox.org/virtualbox/${appNewVersion}/$(curl -fs "https://download.virtualbox.org/virtualbox/${appNewVersion}/" | grep "OSX.dmg" | cut -d\" -f2)"
    fi
    expectedTeamID="VB5E2TV963"
    ;;
microsoftvisualstudiocode|\
visualstudiocode|\
vscode)
    name="Visual Studio Code"
    type="zip"
    appNewVersion=$(curl -fsL "https://update.code.visualstudio.com/api/releases/stable" | tr ',' '\n' | head -1 | tr -d '["')
    downloadURL="https://update.code.visualstudio.com/latest/darwin-universal/stable"
    expectedTeamID="UBF8T346G9"
    appName="Visual Studio Code.app"
    blockingProcesses=( Code )
    ;;
vlc)
    # VLC is a versatile, open-source multimedia player that supports a wide range of audio, video, and streaming formats across multiple platforms
    name="VLC"
    type="dmg"
    appNewVersion=$(curl -s https://www.videolan.org/vlc/#download | xmllint --html --xpath "//script[contains(text(),'var PLATFORMS')]" - 2>/dev/null | grep -o '"osx":{"name":"macOS[^}]*' | grep -o '"latestVersion":"[^"]*' | sed 's/"latestVersion":"//')
    downloadURL="https://get.videolan.org/vlc/$appNewVersion/macosx/vlc-$appNewVersion-universal.dmg"
    expectedTeamID="75GAHG3SZQ"
    ;;
vmwarefusion)
    name="VMware Fusion"
    type="dmg"
    downloadURL="https://www.vmware.com/go/getfusion"
    curlOptions=(-H "Accept: */*" -H "Accept-Encoding: gzip, deflate" -H "Connection: keep-alive" -H "Host: www.vmware.com" -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Safari/605.1.15")
    appNewVersion=$(curl -fsIL ${curlOptions} "https://www.vmware.com/go/getfusion" | grep -i "^location" | awk '{print $2}' | sed 's/.*-\(.*\)-.*/\1/')
    expectedTeamID="EG7KH642X6"
    ;;
vmwarehorizonclient|\
omnissahorizonclient)
    name="Omnissa Horizon Client"
    type="pkgInDmg"
    jsonData=$(curl -fsL 'https://customerconnect.omnissa.com/channel/public/api/v1.0/products/getRelatedDLGList?locale=en_US&category=desktop_end_user_computing&product=omnissa_horizon_clients&version=8&dlgType=PRODUCT_BINARY')
    for var in code productId releasePackageId; do
        local ${var}=$(<<< "$jsonData" sed -nE 's/.*Omnissa Horizon Client for macOS[^}]*"'$var'":"([^"]*).*/\1/p')
    done
    downloadURL=$(curl -fsL "https://customerconnect.omnissa.com/channel/public/api/v1.0/dlg/details?locale=en_US&downloadGroup=$code&productId=$productId&rPId=$releasePackageId" | grep -oE 'https://[^"]*' )
    appNewVersion=$(<<< $downloadURL | grep -oE '\d+\.[0-9.]*\d')
    expectedTeamID="S2ZMFGQM93"
    ;;
vscodium)
    name="VSCodium"
    type="dmg"
    downloadURL="$(downloadURLFromGit VSCodium vscodium)"
    appNewVersion="$(versionFromGit VSCodium vscodium)"
    expectedTeamID="VC39D2VNQ7"
    blockingProcesses=( Electron )
    ;;
wacomdrivers)
    name="Wacom Center"
    type="pkgInDmg"
    downloadURL="$(curl -fs https://www.wacom.com/en-us/support/product-support/drivers | grep -e "drivers/mac/professional.*dmg" | head -1 | tr '"' "\n" | grep -i http)"
    expectedTeamID="EG27766DY7"
    #pkgName="Install Wacom Tablet.pkg"
    appNewVersion="$(curl -fs https://www.wacom.com/en-us/support/product-support/drivers | grep mac/professional/releasenotes | head -1 | tr '"' "\n" | grep -e "Driver [0-9][-0-9.]*" | sed -E 's/Driver ([-0-9.]*).*/\1/g')"
    ;;
warp)
    name="Warp"
    type="dmg"
    downloadURL="https://app.warp.dev/download"
    appNewVersion=$(curl -fs https://releases.warp.dev/channel_versions.json | grep -A 3 '"stable"' | grep '"version"' | head -n 1 | sed -E 's/.*"version": *"([^"]+)".*/\1/')
    expectedTeamID="2BBY89MBSN"
    versionKey="WarpVersion"
    ;;
wavescentral)
    name="Waves Central"
    type="dmg"
    downloadURL="https://cf-installers.waves.com/WavesCentral/Install_Waves_Central.dmg"
    appNewVersion=$( curl -sf "https://register.waves.com/Autoupdate/Updates/ByProductId/1/central-mac" | grep version | cut -d" " -f2 | xargs )
    expectedTeamID="GT6E3XD798"
    ;;
webex|\
webexteams)
    # credit: Erik Stam (@erikstam)
    name="Webex"
    type="dmg"
    appNewVersion=$(curl -fs https://help.webex.com/en-us/article/8dmbcr/Webex-App-%7C-What%27s-New | tr '"' "\n" |  grep "Mac—"| head -1|sed 's/[^0-9\.]//g' )
    blockingProcesses=( "Webex" "Webex Teams" "Cisco WebEx Start" "WebexHelper")
    if [[ $(arch) == arm64 ]]; then
        downloadURL="https://binaries.webex.com/webex-macos-apple-silicon/Webex.dmg"
    elif [[ $(arch) == i386 ]]; then
        downloadURL="https://binaries.webex.com/webex-macos-intel/Webex.dmg"
    fi
    expectedTeamID="DE8Y96K9QP"
    ;;
webexmeetings)
    # credit: Erik Stam (@erikstam)
    name="Cisco Webex Meetings"
    type="pkgInDmg"
    downloadURL="https://akamaicdn.webex.com/client/webexapp.dmg"
    expectedTeamID="DE8Y96K9QP"
    targetDir="/Applications"
    #blockingProcessesMaxCPU="5"
    blockingProcesses=( Webex )
    ;;
webextoolsremoval)
    name="WebEx Tools Removal"
    type="pkg"
    packageID="com.microsoft.remove.WebExPT"
    downloadURL="https://office-reset.com"$(curl -fs https://office-reset.com/macadmins/ | grep -o -i "href.*\".*\"*WebExPT_Removal.*.pkg" | cut -d '"' -f2)
    expectedTeamID="QGS93ZLCU7"
    ;;
webexvdiplugin)
    name="Cisco Webex VDI Plugin"
    type="pkg"
    if [[ "$(arch)" == "arm64" ]]; then
        downloadURL=$(curl -fsSL https://help.webex.com/en-us/article/ntp1us7/Webex-App-%7C-VDI-release-notes#reference-template_e92f9ad6-4f8c-4f69-b967-8615da1788ad 2>/dev/null | awk -F 'href="' '/<td align="" headers="">MacOS \(Apple Silicon\)/ {split($2, a, "\""); print a[1]; exit}')
    else
        downloadURL=$(curl -fsSl https://help.webex.com/en-us/article/ntp1us7/Webex-App-%7C-VDI-release-notes#reference-template_e92f9ad6-4f8c-4f69-b967-8615da1788ad 2>/dev/null | awk -F 'href="' '/<td align="" headers="">MacOS \(Intel base\)/ {split($2, a, "\""); print a[1]; exit}')
    fi
    expectedTeamID="DE8Y96K9QP"
    appNewVersion=$(curl -fsSL https://help.webex.com/en-us/article/ntp1us7/Webex-App-%7C-VDI-release-notes#reference-template_e92f9ad6-4f8c-4f69-b967-8615da1788ad 2>/dev/null | awk '/<th align="" font-weight="bold" id="">Webex App VDI Plugin/ {gsub(/.*\(/, "", $0); gsub(/\).*/, "", $0); print; exit}')
    ;;
windsurf)
    name="Windsurf"
    type="zip"
    myARCH="$(/usr/bin/arch)"
    if [ "$myARCH" != "arm64" ]; then
        myARCH=x64
    fi
    downloadURL="$( curl -s https://windsurf.com/editor/releases | tr '"\' "\n" | grep -m1 "darwin-$myARCH" )"
    appNewVersion="$( echo "$downloadURL" | awk -F '-' '{ print $NF }' | cut -d '.' -f 1-3 )"
    expectedTeamID="83Z2LHX6XW"
    ;;
wireshark)
    name="Wireshark"
    type="dmg"
    # Wireshark is a universal binary as of 4.6.0
    # while the feed URL contains 'x86-64', the download works on both Intel and Apple silicon
    sparkleFeed=$(curl -fs "https://www.wireshark.org/update/0/Wireshark/4.6.0/macOS/x86-64/en-US/stable.xml")
    appNewVersion=$(echo "$sparkleFeed" | xpath '(//rss/channel/item/enclosure/@sparkle:version)[1]' 2>/dev/null | cut -d '"' -f 2)
    downloadURL=$(echo "$sparkleFeed" | xpath '(//rss/channel/item/enclosure/@url)[1]' 2>/dev/null | cut -d '"' -f 2)
    expectedTeamID="7Z6EMTD2C6"
    ;;
xink)
    name="Xink"
    type="pkg"
    packageID="com.emailsignature.Xink"
    downloadURL="https://downloads.xink.io/macos/pkg"
    appNewVersion=$(curl -fs "https://downloads.xink.io/macos/appcast" | xpath '(//rss/channel/item/enclosure/@sparkle:version)[1]' 2>/dev/null | head -1 | cut -d '"' -f 2)
    expectedTeamID="F287823HVS"
    ;;
yubicoauthenticator)
    name="Yubico Authenticator"
    type="dmg"
    downloadURL="https://developers.yubico.com/yubioath-flutter/Releases/yubico-authenticator-latest-mac.dmg"
    appNewVersion=$(curl -fsI "$downloadURL" | grep -i location | grep -oE "[0-9]+(\.[0-9]+)+")
    expectedTeamID="LQA3CS5MM7"
    ;;
yubikeymanager)
    name="YubiKey Manager"
    type="pkg"
    appCustomVersion(){/usr/local/ykman/ykman -v | awk '{print $5}'}
	downloadURL=$(downloadURLFromGit Yubico yubikey-manager)
    appNewVersion=$(versionFromGit Yubico yubikey-manager)
    expectedTeamID="LQA3CS5MM7"
    #CLI for YubikeyManager which is not installed via the QT version.
    ;;
yubikeymanagerqt)
    name="YubiKey Manager GUI"
    type="pkg"
    downloadURL="https://developers.yubico.com/yubikey-manager-qt/Releases/yubikey-manager-qt-latest-mac.pkg"
    appNewVersion=$(curl -fsIL "${downloadURL}" | grep -i "^location" | grep -Eo "[1-9][0-9\.]*" )
    expectedTeamID="LQA3CS5MM7"
    ;;
zbrush2025)
	#credit pmex for the building the framework used for Maxon apps
	name="ZBrush"
    type="dmg"
    appCustomVersion(){
    defaults read "/Applications/Maxon ZBrush 2025/ZBrush.app/Contents/Info.plist" CFBundleVersion | grep -Eo "2025+\.[0-9]+"
    }
	downloadURL=$(curl -fsL https://www.maxon.net/en/downloads | grep -oE '[^"]*zbrush[^"]*\.dmg' | grep -v "windows.net" | sort -r | head -1)
	appNewVersion=$(sed -n 's/.*ZBrush_\([^_]*\).*/\1/p' <<< "${downloadURL}")
    targetDir="/Applications/Maxon ZBrush 2025"
    installerTool="ZBrush_${appNewVersion}_Installer.app"
    CLIInstaller="ZBrush_${appNewVersion}_Installer.app/Contents/MacOS/installbuilder.sh"
    CLIArguments=(--mode unattended --unattendedmodeui none)
    expectedTeamID="4ZY22YGXQG"
    ;;

zoom)
    name="zoom.us"
    type="pkg"
    downloadURL="https://zoom.us/client/latest/ZoomInstallerIT.pkg"
    appNewVersion="$(curl -fsIL ${downloadURL} | grep -i ^location | cut -d "/" -f5)"
    expectedTeamID="BJ4HAAB9B3"
    versionKey="CFBundleVersion"
    ;;
zoomoutlookplugin)
    name="Zoom Outlook Plugin"
    appName="PluginLauncher.app"
    targetDir="/Applications/ZoomOutlookPlugin"
    type="pkg"
    downloadURL="https://zoom.us/client/latest/ZoomMacOutlookPlugin.pkg"
    appNewVersion="$(curl -fsIL ${downloadURL} | grep -i ^location | cut -d "/" -f5 | cut -d "." -f1-3)"
    expectedTeamID="BJ4HAAB9B3"
    blockingProcesses=( "PluginLauncher" )
    ;;
zoomoutlookpluginremoval)
    name="Zoom Outlook Plugin Removal"
    type="pkg"
    packageID="com.microsoft.remove.ZoomPlugin"
    downloadURL="https://office-reset.com"$(curl -fs https://office-reset.com/macadmins/ | grep -o -i "href.*\".*\"*ZoomPlugin_Removal.*.pkg" | cut -d '"' -f2)
    expectedTeamID="QGS93ZLCU7"
    ;;
zoompresence|\
zoomrooms)
    name="ZoomPresence"
    type="pkg"
    downloadURL="https://zoom.us/client/latest/ZoomRooms.pkg"
    appNewVersion="$(curl -fsIL ${downloadURL} | grep -i location | cut -d "/" -f5)"
    expectedTeamID="BJ4HAAB9B3"
    ;;
*)
    # unknown label
    #printlog "unknown label $label"
    cleanupAndExit 1 "unknown label $label" ERROR
    ;;
esac

# MARK: reading arguments again
printlog "Reading arguments again: ${argumentsArray[*]}" INFO
for argument in "${argumentsArray[@]}"; do
    printlog "argument: $argument" DEBUG
    eval $argument
done

# verify we have everything we need
if [[ -z $name ]]; then
    printlog "need to provide 'name'" ERROR
    exit 1
fi
if [[ -z $type ]]; then
    printlog "need to provide 'type'" ERROR
    exit 1
fi
if [[ -z $downloadURL ]]; then
    printlog "need to provide 'downloadURL'" ERROR
    exit 1
fi
if [[ -z $expectedTeamID ]]; then
    printlog "need to provide 'expectedTeamID'" ERROR
    exit 1
fi

# Are we only asked to return label name
if [[ $RETURN_LABEL_NAME -eq 1 ]]; then
    printlog "Only returning label name." REQ
    printlog "$name"
    echo "$name"
    exit
fi

# MARK: application download and installation starts here

# Debug output of all variables in a label
printlog "name=${name}" DEBUG
printlog "appName=${appName}" DEBUG
printlog "type=${type}" DEBUG
printlog "archiveName=${archiveName}" DEBUG
printlog "downloadURL=${downloadURL}" DEBUG
printlog "curlOptions=${curlOptions}" DEBUG
printlog "appNewVersion=${appNewVersion}" DEBUG
printlog "appCustomVersion function: $(if type 'appCustomVersion' 2>/dev/null | grep -q 'function'; then echo "Defined. ${appCustomVersion}"; else; echo "Not defined"; fi)" DEBUG
printlog "versionKey=${versionKey}" DEBUG
printlog "packageID=${packageID}" DEBUG
printlog "pkgName=${pkgName}" DEBUG
printlog "choiceChangesXML=${choiceChangesXML}" DEBUG
printlog "expectedTeamID=${expectedTeamID}" DEBUG
printlog "blockingProcesses=${blockingProcesses}" DEBUG
printlog "installerTool=${installerTool}" DEBUG
printlog "CLIInstaller=${CLIInstaller}" DEBUG
printlog "CLIArguments=${CLIArguments}" DEBUG
printlog "updateTool=${updateTool}" DEBUG
printlog "updateToolArguments=${updateToolArguments}" DEBUG
printlog "updateToolRunAsCurrentUser=${updateToolRunAsCurrentUser}" DEBUG
#printlog "Company=${Company}" DEBUG # Not used

# NOTE: Do not disturb active display sleep assertion
if [[ ${INTERRUPT_DND} = "no" ]]; then
    # Check if a fullscreen app is active
    if hasDisplaySleepAssertion; then
        cleanupAndExit 24 "active display sleep assertion detected, aborting" ERROR
    fi
fi

printlog "BLOCKING_PROCESS_ACTION=${BLOCKING_PROCESS_ACTION}"
printlog "NOTIFY=${NOTIFY}"
printlog "LOGGING=${LOGGING}"

# NOTE: Finding LOGO to use in dialogs
case $LOGO in
    appstore)
        # Apple App Store on Mac
        if [[ $(sw_vers -buildVersion) > "19" ]]; then
            LOGO="/System/Applications/App Store.app/Contents/Resources/AppIcon.icns"
        else
            LOGO="/Applications/App Store.app/Contents/Resources/AppIcon.icns"
        fi
        ;;
    jamf)
        # Jamf Pro
        LOGO="/Library/Application Support/JAMF/Jamf.app/Contents/Resources/AppIcon.icns"
        ;;
    mosyleb)
        # Mosyle Business
        LOGO="/Applications/Self-Service.app/Contents/Resources/AppIcon.icns"
        if [[ -z $MDMProfileName ]]; then; MDMProfileName="Mosyle Corporation MDM"; fi
        ;;
    mosylem)
        # Mosyle Manager (education)
        LOGO="/Applications/Manager.app/Contents/Resources/AppIcon.icns"
        if [[ -z $MDMProfileName ]]; then; MDMProfileName="Mosyle Corporation MDM"; fi
        ;;
    addigy)
        # Addigy
        LOGO="/Library/Addigy/macmanage/MacManage.app/Contents/Resources/atom.icns"
        if [[ -z $MDMProfileName ]]; then; MDMProfileName="MDM Profile"; fi
        ;;
    microsoft)
        # Microsoft Endpoint Manager (Intune)
        if [[ -d "/Library/Intune/Microsoft Intune Agent.app" ]]; then
            LOGO="/Library/Intune/Microsoft Intune Agent.app/Contents/Resources/AppIcon.icns"
        elif [[ -d "/Applications/Company Portal.app" ]]; then
            LOGO="/Applications/Company Portal.app/Contents/Resources/AppIcon.icns"
        fi
        if [[ -z $MDMProfileName ]]; then; MDMProfileName="Management Profile"; fi
        ;;
    ws1)
        # Workspace ONE (AirWatch)
        LOGO="/Applications/Workspace ONE Intelligent Hub.app/Contents/Resources/AppIcon.icns"
        if [[ -z $MDMProfileName ]]; then; MDMProfileName="Device Manager"; fi
        ;;
    kandji)
        # Kandji
        LOGO="/Applications/Kandji Self Service.app/Contents/Resources/AppIcon.icns"
        if [[ -z $MDMProfileName ]]; then; MDMProfileName="MDM Profile"; fi
        ;;
    filewave)
        # FileWave
        LOGO="/usr/local/sbin/FileWave.app/Contents/Resources/fwGUI.app/Contents/Resources/kiosk.icns"
        if [[ -z $MDMProfileName ]]; then; MDMProfileName="FileWave MDM Configuration"; fi
        ;;
esac
if [[ ! -a "${LOGO}" ]]; then
    if [[ $(sw_vers -buildVersion) > "19" ]]; then
        LOGO="/System/Applications/App Store.app/Contents/Resources/AppIcon.icns"
    else
        LOGO="/Applications/App Store.app/Contents/Resources/AppIcon.icns"
    fi
fi
printlog "LOGO=${LOGO}" INFO

printlog "Label type: $type" INFO

# NOTE: extract info from data
if [ -z "$archiveName" ]; then
    case $type in
        dmg|pkg|zip|tbz|bz2)
            archiveName="${name}.$type"
            ;;
        pkgInDmg)
            archiveName="${name}.dmg"
            ;;
        *InZip)
            archiveName="${name}.zip"
            ;;
        updateronly)
            ;;
        *)
            printlog "Cannot handle type $type"
            cleanupAndExit 99
            ;;
    esac
fi
printlog "archiveName: $archiveName" INFO

if [ -z "$appName" ]; then
    # when not given derive from name
    appName="$name.app"
fi

if [ -z "$targetDir" ]; then
    case $type in
        dmg|zip|tbz|bz2|app*)
            targetDir="/Applications"
            ;;
        pkg*)
            targetDir="/"
            ;;
        updateronly)
            ;;
        *)
            cleanupAndExit 99 "Cannot handle type $type" ERROR
            ;;
    esac
fi

if [[ -z $blockingProcesses ]]; then
    printlog "no blocking processes defined, using $name as default" INFO
    blockingProcesses=( $name )
fi

# MARK: determine tmp dir
if [ "$DEBUG" -eq 1 ]; then
    # for debugging use script dir as working directory
    tmpDir=$(dirname "$0")
else
    # create temporary working directory
    tmpDir=$(mktemp -d )
fi

# NOTE: change directory to temporary working directory
printlog "Changing directory to $tmpDir" DEBUG
if ! cd "$tmpDir"; then
    cleanupAndExit 13 "error changing directory $tmpDir" ERROR
fi

# MARK: get installed version
getAppVersion
printlog "appversion: $appversion"

# NOTE: Exit if new version is the same as installed version (appNewVersion specified)
if [[ "$type" != "updateronly" && ($INSTALL == "force" || $IGNORE_APP_STORE_APPS == "yes") ]]; then
    printlog "Label is not of type “updateronly”, and it’s set to use force to install or ignoring app store apps, so not using updateTool."
    updateTool=""
fi
if [[ -n $appNewVersion ]]; then
    printlog "Latest version of $name is $appNewVersion"
    if [[ $appversion == $appNewVersion ]]; then
        if [[ $DEBUG -ne 1 ]]; then
            printlog "There is no newer version available."
            if [[ $INSTALL != "force" ]]; then
                message="$name, version $appNewVersion, is the latest version."
                if [[ $currentUser != "loginwindow" && $NOTIFY == "all" ]]; then
                    printlog "notifying"
                    displaynotification "$message" "No update for $name!"
                fi
                if [[ $DIALOG_CMD_FILE != "" ]]; then
                    updateDialog "complete" "Latest version already installed..."
                    sleep 2
                fi
                cleanupAndExit 0 "No newer version." REQ
            fi
        else
            printlog "DEBUG mode 1 enabled, not exiting, but there is no new version of app." WARN
        fi
    fi
else
    printlog "Latest version not specified."
fi

# MARK: check if this is an Update and we can use updateTool
if [[ (-n $appversion && -n "$updateTool") || "$type" == "updateronly" ]]; then
    printlog "App needs to be updated and uses $updateTool. Ignoring BLOCKING_PROCESS_ACTION and running updateTool now."
    updateDialog "wait" "Updating..."

    if [[ $DEBUG -ne 1 ]]; then
        if runUpdateTool; then
            finishing
            cleanupAndExit 0 "updateTool has run" REQ
        elif [[ $type == "updateronly" ]];then
            cleanupAndExit 0 "type is $type so we end here." REQ
        fi # otherwise continue
    else
        printlog "DEBUG mode 1 enabled, not running update tool" WARN
    fi
fi

# MARK: download the archive
if [ -f "$archiveName" ] && [ "$DEBUG" -eq 1 ]; then
    printlog "$archiveName exists and DEBUG mode 1 enabled, skipping download"
else
    # download
    printlog "Downloading $downloadURL to $archiveName" REQ
    if [[ $currentUser != "loginwindow" && $NOTIFY == "all" ]]; then
        printlog "notifying"
        if [[ $updateDetected == "YES" ]]; then
            displaynotification "Downloading $name update" "Download in progress …"
        else
            displaynotification "Downloading new $name" "Download in progress …"
        fi
    fi

    if [[ $DIALOG_CMD_FILE != "" ]]; then
        # pipe
        pipe="$tmpDir/downloadpipe"
        # initialise named pipe for curl output
        initNamedPipe create $pipe

        # run the pipe read in the background
        readDownloadPipe $pipe "$DIALOG_CMD_FILE" & downloadPipePID=$!
        printlog "listening to output of curl with pipe $pipe and command file $DIALOG_CMD_FILE on PID $downloadPipePID" DEBUG

        curlDownload=$(curl -fL -# --show-error ${curlOptions} "$downloadURL" -o "$archiveName" 2>&1 | tee $pipe)
        # because we are tee-ing the output, we want the pipe status of the first command in the chain, not the most recent one
        curlDownloadStatus=$(echo $pipestatus[1])
        killProcess $downloadPipePID

    else
        printlog "No Dialog connection, just download" DEBUG
        curlDownload=$(curl -v -fsL --show-error ${curlOptions} "$downloadURL" -o "$archiveName" 2>&1)
        curlDownloadStatus=$(echo $?)
    fi

    # Trying to detect proxy or web filter on downloaded file
    archiveSHA=$(shasum "$archiveName" | cut -w -f 1)
    archiveSize=$(du -k "$archiveName" | cut -w -f 1)
    archiveType=$(file "$archiveName" | cut -d ':' -f2 )
    printlog "Downloaded $archiveName – Type is $archiveType – SHA is $archiveSHA – Size is $archiveSize kB" INFO

    # Trying to detect download errors, including proxy or web filter blocking on downloaded file
    if [[ $curlDownloadStatus -ne 0 || $archiveType == *ASCII* ]]; then
        printlog "error downloading $downloadURL" ERROR
        message="$name update/installation failed. This will be logged, so IT can follow up."
        if [[ $currentUser != "loginwindow" && $NOTIFY == "all" ]]; then
            printlog "notifying"
            if [[ $updateDetected == "YES" ]]; then
                displaynotification "$message" "Error updating $name"
            else
                displaynotification "$message" "Error installing $name"
            fi
        fi
        if [[ $archiveType == *ASCII* ]]; then
            firstLines=$(head -c 51170 $archiveName)
            deduplicatelogs $firstLines
            cleanupAndExit 2 "File Downloaded is ASCII, we’re probably being blocked by a proxy or filter.  First 5k of file is:\n$logoutput" ERROR
        else
            deduplicatelogs "$curlDownload"
            cleanupAndExit 2 "Error downloading $downloadURL error:\n$logoutput" ERROR
        fi
    fi
fi

# MARK: when user is logged in, and app is running, prompt user to quit app
if [[ $BLOCKING_PROCESS_ACTION == "ignore" ]]; then
    printlog "ignoring blocking processes"
else
    if [[ $currentUser != "loginwindow" ]]; then
        if [[ ${#blockingProcesses} -gt 0 ]]; then
            if [[ ${blockingProcesses[1]} != "NONE" ]]; then
                checkRunningProcesses
            fi
        fi
    fi
fi

# MARK: install the download
printlog "Installing $name" REQ
if [[ $currentUser != "loginwindow" && $NOTIFY == "all" ]]; then
    printlog "notifying"
    if [[ $updateDetected == "YES" ]]; then
        displaynotification "Updating $name" "Installation in progress …"
        updateDialog "wait" "Updating..."
    else
        displaynotification "Installing $name" "Installation in progress …"
        updateDialog "wait" "Installing..."
    fi
fi

if [ -n "$installerTool" ]; then
    # installerTool defined, and we use that for installation
    printlog "installerTool used: $installerTool" REQ
    appName="$installerTool"
fi

case $type in
    dmg)
        installFromDMG
        ;;
    pkg)
        installFromPKG
        ;;
    zip)
        installFromZIP
        ;;
    tbz|bz2)
        installFromTBZ
        ;;
    pkgInDmg)
        installPkgInDmg
        ;;
    pkgInZip)
        installPkgInZip
        ;;
    appInDmgInZip)
        installAppInDmgInZip
        ;;
    *)
        cleanupAndExit 99 "Cannot handle type $type" ERROR
        ;;
esac

updateDialog "wait" "Finishing..."

# MARK: Finishing — print installed application location and version
finishing

# all done!
cleanupAndExit 0 "All done!" REQ
