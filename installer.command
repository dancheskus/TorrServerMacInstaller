#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$dir"

plistPath="/Library/LaunchAgents/torrserver.plist"
serverPath="/Users/Shared/TorrServer-darwin-amd64"
isServerInstalled=false
projectURL="https://api.github.com/repos/YouROK/TorrServer/releases"
latestMatrixVersion=$(curl -s $projectURL | grep tag_name | grep -m 1 MatriX | cut -d '"' -f 4)
webAppURL="http://localhost:8090"

replacePlist() { plutil -replace $1 $2 "$3" "$plistPath"; }
toggleAutostart() {
  if [[ $isRunAtLoad ]]; then
    replacePlist "RunAtLoad" "-bool" false
  else    
    replacePlist "RunAtLoad" "-bool" true
  fi
}
updateServrIsInstalled() {
  [[ -f $serverPath && -f $plistPath ]] && isServerInstalled=true
}

contains() {
  # https://www.programmersought.com/article/36184759477/
  local n=$#
  local value=${!n}
  for ((i=1;i < $#;i++)) {
      if [ "${!i}" == "${value}" ]; then
          echo "y"
          return 0
      fi
  }
  echo "n"
  return 1
}

installServer() {
  cat > torrserver.plist <<- "EOF"            
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
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
          <string>/Users/Shared/TorrServer/TorrServer-darwin-amd64</string>
          <string>-d</string>
          <string>/Users/Shared/TorrServer</string>
          <string>-l</string>
          <string>/Users/Shared/TorrServer/torrserver.log</string>
          <string>-p</string>
          <string>8090</string>
          <string>-a</string>
          <string>-k</string>
        </array>
        </dict>
    </plist>
EOF

  chmod 755 torrserver.plist
  sudo mv torrserver.plist /Library/LaunchAgents

  if [[ $1 ]]; then
    echo "Downloading $1..."
    curl -s $projectURL | grep browser_download_url | grep $1 | grep darwin-amd64 | cut -d '"' -f 4 | xargs -n 1 curl -O -sSL
  else
    echo "Downloading latest release..."
    curl -s $projectURL/latest | grep browser_download_url | grep darwin-amd64 | cut -d '"' -f 4 | xargs -n 1 curl -O -sSL
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
  open $webAppURL
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
      torrServerVer="$(curl -s $webAppURL/echo)"
      printKey "Server version"
      [[ $torrServerVer == $latestMatrixVersion ]] && printValue "$torrServerVer (latest)" || printValue "$torrServerVer (update available)"
    fi

    isRunAtLoad="$(plutil -extract "RunAtLoad" xml1 -o - $plistPath | grep true)"
    printKey "Autostart server when Mac OS starts"
    if [[ $isRunAtLoad ]]; then printValue "true"; else printValue "false"; fi
  fi
  
  echo; echo; echo; echo; echo;
}

isVersionMenu=false

startApp() {
  while ! $isVersionMenu; do
    updateServrIsInstalled
    printInfo

    # ----------------------- MENU ITEMS -------------------------
    installLatestServerOption="Install latest server"
    installDifferentServerVersionOption="Select another server version to install"
    startServerOption="Start server"
    stopServerOption="Stop server"
    updateServerOption="Update server"
    removeServerOption="Remove server"
    toggleAutostartOption="Toggle autostart"
    quitOption="Quit"
    # ------------------------------------------------------------
    
    options=()
    if [[ $isServerInstalled == true ]]; then
      [[ $isServerRunning ]] && options+=("$stopServerOption") || options+=("$startServerOption")
    else
      options+=("$installLatestServerOption")
    fi

    options+=("$installDifferentServerVersionOption")

    if [[ $isServerInstalled == true ]]; then
      [[ $torrServerVer != $latestMatrixVersion ]] && options+=("$updateServerOption")
      options+=("$removeServerOption" "$toggleAutostartOption")
    fi

    options+=("$quitOption")

    printHeader " Choose an option (enter number and press ENTER): "; echo
    COLUMNS=0
    select option in "${options[@]}"; do
      [[ $option == $installLatestServerOption || $option == $startServerOption || $option == $stopServerOption ]] && toggleServerState && break
      [[ $option == $updateServerOption ]] && removeServer && installServer && startServer && break
      [[ $option == $installDifferentServerVersionOption ]] && isVersionMenu=true && clear && break
      [[ $option == $removeServerOption ]] && removeServer && clear && echo "Server is removed." && break 2
      [[ $option == $toggleAutostartOption ]] && toggleAutostart && break
      [[ $option == $quitOption ]] && clear && break 2
      echo "Wrong key? Use keys [1 - ${#options[@]}]"
    done
  done
}

startApp

while $isVersionMenu; do
  options=($(curl -s $projectURL | grep tag_name | grep MatriX | cut -d '"' -f 4))
  returnBack="Return back"
  options+=("$returnBack")

  printHeader " Select version: "; echo
  select option in "${options[@]}"; do
    if [ $(contains "${options[@]}" "$option") == "y" ]; then
      if [[ $option != $returnBack ]]; then
        [[ $isServerInstalled == true ]] && removeServer
        installServer $option && startServer
      fi

      isVersionMenu=false; startApp; break
    else
      echo "Wrong key? Use keys [1 - ${#options[@]}]"
    fi
  done
done

echo "Bye bye!"
