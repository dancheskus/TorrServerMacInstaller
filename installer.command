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

  if [[ $1 ]]; then
    echo "Downloading $1..."
    curl -s https://api.github.com/repos/YouROK/TorrServer/releases | grep browser_download_url | grep $1 | grep darwin-amd64 | cut -d '"' -f 4 | xargs -n 1 curl -O -sSL
  else
    echo "Downloading latest release..."
    curl -s https://api.github.com/repos/YouROK/TorrServer/releases/latest | grep browser_download_url | grep darwin-amd64 | cut -d '"' -f 4 | xargs -n 1 curl -O -sSL
  fi
  chmod 755 TorrServer-darwin-amd64
  mv TorrServer-darwin-amd64 /Users/Shared/
}

removeServer() {
  stopServer

  sudo rm $plistPath && rm $serverPath
}

stopServer() {
  pkill -f "TorrServer-darwin-amd64"
}

startServer() {
  cd /Users/Shared
  (&>/dev/null ./TorrServer-darwin-amd64 &)
  cd "$dir"
  clear
  open http://localhost:8090
}

toggleServerState() {
  if [[ $isServerInstalled == false ]]; then
    installServer $1
  fi

  [[ $isServerRunning ]] && stopServer || startServer
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

isVersionMenu=false

enableMainMenu() {
  while ! $isVersionMenu; do
    updateServrIsInstalled
    printInfo
    
    firstOption="Start server"
    [[ $isServerRunning ]] && firstOption="Stop server"

    if [[ $isServerInstalled == true ]]; then
      options=("$firstOption" "Update server" "Remove server" "Toggle autostart" "Quit")

      printHeader " Choose an option: "; echo
      COLUMNS=0
      select opt in "${options[@]}"; do
        case $REPLY in
          1) toggleServerState; break ;;
          2) break ;;
          3) removeServer; clear; echo "Server is removed."; break 2 ;;
          4) [[ $isRunAtLoad ]] && replaceAutostart false || replaceAutostart true; break ;;
          5) clear; break 2 ;;
          *) echo "Wrong key? Use keys [1 - 5]" >&2 ;;
        esac
      done
    else
      options=("Install latest server" "Select another server version to install" "Quit")

      printHeader " Choose an option: "; echo
      COLUMNS=0
      select opt in "${options[@]}"; do
        case $REPLY in
          1) toggleServerState; break ;;
          2) isVersionMenu=true; clear; break ;;
          3) clear; break 2 ;;
          *) echo "Wrong key? Use keys [1 - 3]" >&2 ;;
        esac
      done 
    fi

  done
}

enableMainMenu

while $isVersionMenu; do
    options=($(curl -s https://api.github.com/repos/YouROK/TorrServer/releases | grep tag_name | grep MatriX | cut -d '"' -f 4))
    returnBack="Return back"
    options+=("$returnBack")

    printHeader " Select version: "; echo
    COLUMNS=0
    select option in "${options[@]}"; do
        if [[ $option != $returnBack ]]; then
          removeServer
          toggleServerState $option
        fi
        
        isVersionMenu=false; enableMainMenu; break
    done

done

echo "Bye bye!"