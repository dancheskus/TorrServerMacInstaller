#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$dir"

cat > torrserver.plist <<- "EOF"            
<?xml version="1.0" encoding="UTF-8"?>                                                                 
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"\>
<plist version="1.0">
  <dict>            
    <key>Label</key>           
    <string>TorrServer</string>  
    <key>ServiceDescription</key>              
    <string>TorrServer service for Mac</string>
    <key>LaunchOnlyOnce</key>
    <true/>             
    <key>RunAtLoad</key>
    <true/>                    
    <key>ProgramArguments</key>
    <array>                                                 
      <string>/Users/Shared/TorrServer-darwin-amd64</string>
      <string>-d</string>           
      <string>/Users/Shared</string>
    </array>
  </dict>
</plist>
EOF

chmod 755 torrserver.plist
sudo mv torrserver.plist /Library/LaunchAgents

curl -s https://api.github.com/repos/YouROK/TorrServer/releases/latest | grep browser_download_url | grep darwin-amd64 | cut -d '"' -f 4 | xargs -n 1 curl -O -sSL
chmod 755 TorrServer-darwin-amd64
mv TorrServer-darwin-amd64 /Users/Shared/

if [[ $(pgrep -f "TorrServer-darwin-amd64") ]]; then
    echo "stopping TorrServer..."

    pkill -f "TorrServer-darwin-amd64"
else
    echo "starting TorrServer..."

    cd /Users/Shared
    nohup ./TorrServer-darwin-amd64 &>/dev/null &
    cd "$dir"
    open http://localhost:8090
fi