# Disabled 2026-08-21: RealVNC ended anonymous downloads. v7 renamed "RealVNC
# Classic Viewer", available only from the RealVNC Portal (sign-in, Premium/
# Enterprise). v8 "RealVNC Connect Viewer" is Cloudflare/human-verification
# gated — no curl-able URL. Deploy manually via Intune pkg wrapper instead.
# See https://help.realvnc.com/hc/en-us/articles/35745908986653
realvncviewer)
    name="Real VNC Viewer"
    appName="VNC Viewer.app"
    type="dmg"
    downloadURL="https://downloads.realvnc.com/download/file/viewer.files/VNC-Viewer-Latest-MacOSX-universal.dmg"
    appNewVersion="$(curl -sL https://realvnc.zendesk.com/api/v2/help_center/en-us/articles/5835892358941.json | sed -n 's/.*VNC-Viewer-\([0-9.]*\)-MacOSX.*/\1/p')"
    expectedTeamID="ZNCQ8JEH7X"
    ;;
