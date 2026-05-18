gotomeeting)
    # credit: @matins
    name="GoToMeeting"
    type="dmg"
    downloadURL="https://link.gotomeeting.com/latest-dmg"
    # Redirect resolves to .../builds/g2m/<build>/GoToMeeting.dmg.
    # CFBundleShortVersionString is 10.19.0.<build> (not derivable from URL);
    # CFBundleVersion is the bare build number, so compare on that.
    versionKey="CFBundleVersion"
    appNewVersion=$(curl -fsIL -o /dev/null -w "%{url_effective}" "${downloadURL}" | sed -nE 's@.*/g2m/([0-9]+)/.*@\1@p')
    expectedTeamID="GFNFVT632V"
    ;;
