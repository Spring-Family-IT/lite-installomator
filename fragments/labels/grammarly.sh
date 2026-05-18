grammarly)
     name="Grammarly Desktop"
     type="dmg"
     packageID="com.grammarly.ProjectLlama"
     downloadURL="https://download-mac.grammarly.com/Grammarly.dmg"
     # Grammarly publishes a public Sparkle appcast; first item's shortVersionString
     # matches both the installer app's CFBundleShortVersionString and the pkg receipt.
     appNewVersion=$(curl -fsL "https://download-mac.grammarly.com/appcast.xml" | sed -nE 's/.*sparkle:shortVersionString="([^"]+)".*/\1/p' | head -1)
     expectedTeamID="W8F64X92K3"
     # appName="Grammarly Installer.app"
     installerTool="Grammarly Installer.app"
     CLIInstaller="Grammarly Installer.app/Contents/MacOS/Grammarly Desktop"
;;
