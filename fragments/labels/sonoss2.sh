sonoss2)
    name="Sonos"
    type="dmg"
    downloadURL="https://www.sonos.com/redir/controller_software_mac2"
    # Sonos DMG ships CFBundleShortVersionString=17.2 (marketing) and
    # CFBundleVersion=90.0.67171 (build, encoded in filename Sonos_90.0-67171.dmg).
    # Only the build is derivable from public sources, so compare on CFBundleVersion.
    versionKey="CFBundleVersion"
    appNewVersion=$(curl -fsIL -o /dev/null -w "%{url_effective}" "${downloadURL}" | sed -nE 's@.*/Sonos_([0-9.\-]+)\.dmg$@\1@p' | tr '-' '.')
    expectedTeamID="2G4LW83Q3E"
    ;;
