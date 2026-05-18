openvpnconnect)
    # credit: Erik Stam (@erikstam)
    name="OpenVPN"
    type="pkgInDmg"
    pkgName="OpenVPN_Connect_Installer_signed.pkg"
    downloadURL="https://openvpn.net/downloads/openvpn-connect-v2-macos.dmg"
    # App's CFBundleShortVersionString is a stale "2.1"; the pkg receipt
    # net.openvpn.connect carries the real version (e.g. 2.7.1.111) which
    # matches the filename in the redirect target.
    packageID="net.openvpn.connect"
    appNewVersion=$(curl -fsIL -o /dev/null -w "%{url_effective}" "${downloadURL}" | sed -nE 's@.*/openvpn-connect-([0-9.]+)_signed\.dmg$@\1@p')
    expectedTeamID="ACV7L3WCD8"
    ;;
