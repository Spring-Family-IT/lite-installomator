gotiengviet)
    name="GoTiengViet"
    type="dmg"
    downloadURL="https://www.trankynam.com/gotv/downloads/GoTiengViet.dmg"
    # Vendor page has the version in a non-machine-readable position; proxy Homebrew Cask.
    appNewVersion=$(curl -fsL "https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/g/gotiengviet.rb" | sed -nE 's/^[[:space:]]*version[[:space:]]+"([^"]+)".*/\1/p')
    expectedTeamID="KHEMQ2FD9E"
    ;;
