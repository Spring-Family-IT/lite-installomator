miniconda)
    type="pkg"
    packageID="io.continuum.pkg.prepare_installation"
    # PackageInfo carries versions like 'py313_26.3.2-2' — non-numeric chars break
    # Installomator's default '[0-9.]*' extractor, so read the raw string ourselves.
    appCustomVersion() { pkgutil --pkg-info io.continuum.pkg.prepare_installation 2>/dev/null | awk '/^version:/ {print $2}'; }
    if [[ $(arch) == arm64 ]]; then
        name="Miniconda3-latest-MacOSX-arm64"
        downloadURL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.pkg"
        # Proxy Homebrew Cask's on_arm version block (~1-3 day lag).
        appNewVersion=$(curl -fsL "https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/m/miniconda.rb" | awk '/on_arm do/,/on_intel do/' | sed -nE 's/^[[:space:]]*version[[:space:]]+"([^"]+)".*/\1/p')
    elif [[ $(arch) == i386 ]]; then
        name="Miniconda3-latest-MacOSX-x86_64"
        downloadURL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.pkg"
        # Intel is "Legacy version" in Homebrew (Anaconda has stopped new intel builds).
        appNewVersion=$(curl -fsL "https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/m/miniconda.rb" | awk '/on_intel do/,/^end/' | sed -nE 's/^[[:space:]]*version[[:space:]]+"([^"]+)".*/\1/p')
    fi
    expectedTeamID="Z5788K4JT7"
    ;;
