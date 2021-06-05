#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$dir"

plistPath="/Library/LaunchAgents/torrserver.plist"
serverPath="/Users/Shared/TorrServer-darwin-amd64"
isServerInstalled=false

replacePlist() { plutil -replace $1 $2 "$3" "$plistPath"; }
replaceAutostart() { replacePlist "RunAtLoad" "-bool" $1; }
updateServrIsInstalled() {
  [[ -f $serverPath && -f $plistPath ]] && isServerInstalled=true
}

installServer() {
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
}

startServer() {
  if [[ $isServerInstalled == false ]]; then
    installServer
  fi

  if [[ $isServerRunning ]]; then
      echo "Stopping TorrServer..."

      pkill -f "TorrServer-darwin-amd64"
  else
      echo "Starting TorrServer..."

      cd /Users/Shared
      (&>/dev/null ./TorrServer-darwin-amd64 &)
      cd "$dir"
      clear
      open http://localhost:8090
  fi
}

printHeader() { printf "\033[44m$1\n"; tput sgr0; }
printTitle() { printf "\033[1m$1\n"; tput sgr0; }
printKey() { printf "   \033[1m$1: "; }
printValue() { printf "\033[2m$1\n"; tput sgr0; }

printInfo() {
  clear

  printHeader " TorrServer Mac OS installer "; echo

  isServerRunning="$(pgrep -f "TorrServer-darwin-amd64")"

  printTitle "Info:"

  printKey "Server is installed" && printValue $isServerInstalled


  if [[ $isServerInstalled == true ]]; then
    printKey "Server is running" && [[ $isServerRunning ]] && printValue "true" || printValue "fasle"

    if [[ $isServerRunning ]]; then
      torrServerVer="$(curl -s http://localhost:8090/echo)"
      printKey "Server version"
      printValue $torrServerVer
    fi

    isRunAtLoad="$(plutil -extract "RunAtLoad" xml1 -o - $plistPath | grep true)"
    printKey "Autostart server when Mac OS starts"
    if [[ $isRunAtLoad ]]; then printValue "true"; else printValue "false"; fi
  fi
  
  echo; echo; echo; echo; echo;
}

while true; do
  updateServrIsInstalled
  printInfo
  
  firstOption="Start server" && [[ $isServerInstalled == true && $isServerRunning ]] && firstOption="Stop server"
  options=("$firstOption" "Update server" "Remove server" "Toggle autostart" "Quit")

  printHeader " Choose an option: "; echo
  COLUMNS=0
  select opt in "${options[@]}"; do
    case $REPLY in
      1) startServer; break ;;
      2) break ;;
      3) break ;;
      4) [[ $isRunAtLoad ]] && replaceAutostart false || replaceAutostart true; break ;;
      5) clear; break 2 ;;
      *) echo "What's that?" >&2 ;;
    esac
  done
done

echo "Bye bye!"