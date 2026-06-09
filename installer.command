#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "$dir"

plistPath="/Library/LaunchAgents/torrserver.plist"
launchctlService="gui/$(id -u)/TorrServer"
serverFolder="/Users/Shared/TorrServer"
case "$(uname -m)" in
  arm64) preferredServerBinary="TorrServer-darwin-arm64" ;;
  *) preferredServerBinary="TorrServer-darwin-amd64" ;;
esac
preferredServerPath="$serverFolder/$preferredServerBinary"
serverBinary="$preferredServerBinary"
serverPath="$preferredServerPath"
isServerInstalled=false
isNativeServerInstalled=false
projectURL="https://api.github.com/repos/YouROK/TorrServer/releases"
latestMatrixVersion=$(curl -s --max-time 10 "$projectURL/latest" | grep tag_name | grep -m 1 MatriX | cut -d '"' -f 4)
webAppURL="http://localhost:8090"

usePreferredServer() {
  serverBinary="$preferredServerBinary"
  serverPath="$preferredServerPath"
}

getServerVersion() {
  local version

  for ((i=0; i<10; i++)); do
    version="$(curl -s --max-time 1 "$webAppURL/echo")"
    if [[ $version ]]; then
      echo "$version"
      return 0
    fi

    sleep 0.3
  done
}

waitForServerStart() {
  for ((i=0; i<20; i++)); do
    if pgrep -f "TorrServer-darwin" >/dev/null; then
      return 0
    fi

    sleep 0.2
  done
}

waitForServerStop() {
  for ((i=0; i<20; i++)); do
    if ! pgrep -f "TorrServer-darwin" >/dev/null; then
      return 0
    fi

    sleep 0.2
  done
}

loadLaunchAgent() {
  if plutil -extract LaunchOnlyOnce raw -o - "$plistPath" >/dev/null 2>&1; then
    sudo -n plutil -remove LaunchOnlyOnce "$plistPath" 2>/dev/null || return 1
  fi

  if [[ $(stat -f "%Su:%Sg" "$plistPath" 2>/dev/null) != "root:wheel" ]]; then
    sudo -n chown root:wheel "$plistPath" 2>/dev/null || return 1
  fi

  if [[ $(stat -f "%Lp" "$plistPath" 2>/dev/null) != "644" ]]; then
    sudo -n chmod 644 "$plistPath" 2>/dev/null || return 1
  fi

  launchctl bootout "$launchctlService" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$plistPath" 2>/dev/null || true
}

startDetachedServer() {
  perl -MPOSIX=setsid -e '
    chdir shift or die "chdir failed: $!";
    open STDIN, "<", "/dev/null";
    open STDOUT, ">", "/dev/null";
    open STDERR, ">", "/dev/null";
    setsid() or die "setsid failed: $!";
    exec @ARGV;
  ' "$serverFolder" "$serverPath" -d "$serverFolder" -l "$serverFolder/torrserver.log" -p 8090 &
}

clearScreen() {
  clear 2>/dev/null || printf "\033c"
  return 0
}

replacePlist() { plutil -replace $1 $2 "$3" "$plistPath"; }
toggleAutostart() {
  if [[ $isRunAtLoad ]]; then
    replacePlist "RunAtLoad" "-bool" false
  else    
    replacePlist "RunAtLoad" "-bool" true
  fi
}
updateServrIsInstalled() {
  isServerInstalled=false
  isNativeServerInstalled=false
  usePreferredServer

  if [[ -f $plistPath ]]; then
    plistServerPath="$(plutil -extract ProgramArguments.0 raw -o - "$plistPath" 2>/dev/null)"

    for installedServerPath in "$plistServerPath" "$preferredServerPath" "$serverFolder/TorrServer-darwin-amd64" "$serverFolder/TorrServer-darwin-arm64"; do
      if [[ -f $installedServerPath ]]; then
        serverPath="$installedServerPath"
        serverBinary="${installedServerPath##*/}"
        isServerInstalled=true
        [[ $serverBinary == "$preferredServerBinary" ]] && isNativeServerInstalled=true
        return
      fi
    done
  fi
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
  usePreferredServer

  cat > torrserver.plist <<- EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
        <key>Label</key>
        <string>TorrServer</string>
        <key>ServiceDescription</key>
        <string>TorrServer service for Mac</string>
        <key>RunAtLoad</key>
        <true/>
        <key>ProgramArguments</key>
        <array>
          <string>$serverPath</string>
          <string>-d</string>
          <string>$serverFolder</string>
          <string>-l</string>
          <string>$serverFolder/torrserver.log</string>
          <string>-p</string>
          <string>8090</string>
        </array>
        </dict>
    </plist>
EOF

  chmod 644 torrserver.plist
  sudo chown root:wheel torrserver.plist
  sudo mv torrserver.plist /Library/LaunchAgents

  if [[ $1 ]]; then
    echo "Downloading $1..."
    downloadURL="$(curl -s "$projectURL" | grep browser_download_url | grep "$1" | grep "$serverBinary" | cut -d '"' -f 4 | head -n 1)"
  else
    echo "Downloading latest release..."
    downloadURL="$(curl -s "$projectURL/latest" | grep browser_download_url | grep "$serverBinary" | cut -d '"' -f 4 | head -n 1)"
  fi

  if [[ -z $downloadURL ]]; then
    echo "Could not find $serverBinary in TorrServer releases."
    return 1
  fi

  curl -O -sSL "$downloadURL"
  chmod 755 "$serverBinary"
  [ -d "$serverFolder" ] || mkdir "$serverFolder"
  mv "$serverBinary" "$serverFolder"
}

removeServer() {
  stopServer

  sudo rm -f "$plistPath"
  rm -f "$serverFolder/TorrServer-darwin-amd64" "$serverFolder/TorrServer-darwin-arm64"

  if [[ $1 == "askAboutDB" ]]; then
    isVersionMenu=false
    isRemoveMenu=true
  fi
}

stopServer() {
  launchctl kill TERM "$launchctlService" 2>/dev/null || true
  pkill -f "TorrServer-darwin" 2>/dev/null || true
  waitForServerStop
}

startServer() {
  loadLaunchAgent
  launchctl kickstart -k "$launchctlService" 2>/dev/null || {
    trap '' INT
    startDetachedServer
    trap - INT
  }
  waitForServerStart
  getServerVersion >/dev/null
  clearScreen
  open "$webAppURL"
}

toggleServerState() {
  if [[ $isServerInstalled == false ]]; then
    installServer "$1" || return
  fi

  [[ $isServerRunning ]] && stopServer || startServer
}

resetColor() { tput sgr0 2>/dev/null || true; }
printHeader() { printf "\033[44m$1\n"; resetColor; }
printTitle() { printf "\033[1m$1\n"; resetColor; }
printKey() { printf "   \033[1m$1: "; resetColor; }
printValue() { printf "\033[2m$1\n"; resetColor; }
printGreen() { printf "\e[30m\e[42m$1\n"; resetColor; }
printRed() { printf "\e[41m$1\n"; resetColor; }
printLightBlue() { printf "\e[104m$1\n"; resetColor; }
printGray() { printf "\e[30m\e[47m$1\n"; resetColor; }

printInfo() {
  clearScreen

  printHeader " TorrServer Mac OS installer "; echo

  isServerRunning="$(pgrep -f "TorrServer-darwin")"
  torrServerVer=""

  printTitle "Info:"

  printKey "Server is installed" && [[ $isServerInstalled == true ]] && printGreen " true " || printRed " false "


  if [[ $isServerInstalled == true ]]; then
    printKey "Server is running" && [[ $isServerRunning ]] && printGreen " true " || printRed " false "
    printKey "Server binary"
    [[ $isNativeServerInstalled == true ]] && printGreen " $serverBinary " || printGray " $serverBinary (native: $preferredServerBinary) "

    if [[ $isServerRunning ]]; then
      torrServerVer="$(getServerVersion)"
      printKey "Server version"
      if [[ -z $torrServerVer ]]; then
        printGray " unknown "
      elif [[ -z $latestMatrixVersion ]]; then
        printGray " $torrServerVer (latest unavailable) "
      elif [[ $torrServerVer == $latestMatrixVersion ]]; then
        printLightBlue " $torrServerVer (latest) "
      else
        printGray " $torrServerVer (update available) "
      fi
    fi

    isRunAtLoad="$(plutil -extract "RunAtLoad" xml1 -o - $plistPath | grep true)"
    printKey "Autostart server when Mac OS starts"
    [[ $isRunAtLoad ]] && printGreen " true " || printRed " false "
  fi
  
  echo; echo; echo; echo; echo;
}

isVersionMenu=false
isRemoveMenu=false

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
      [[ ($torrServerVer && $latestMatrixVersion && $torrServerVer != $latestMatrixVersion) || $isNativeServerInstalled != true ]] && options+=("$updateServerOption")
      options+=("$removeServerOption" "$toggleAutostartOption")
    fi

    options+=("$quitOption")

    printHeader " Choose an option (enter number and press ENTER): "; echo
    COLUMNS=0
    select option in "${options[@]}"; do
      [[ $option == $installLatestServerOption || $option == $startServerOption || $option == $stopServerOption ]] && toggleServerState && break
      [[ $option == $updateServerOption ]] && removeServer && installServer && startServer && break
      [[ $option == $installDifferentServerVersionOption ]] && isVersionMenu=true && clearScreen && break
      [[ $option == $removeServerOption ]] && removeServer "askAboutDB" && clearScreen && echo "Server is removed." && break 2
      [[ $option == $toggleAutostartOption ]] && toggleAutostart && break
      [[ $option == $quitOption ]] && clearScreen && break 2
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
        installServer "$option" && startServer
      fi

      isVersionMenu=false; startApp; break
    else
      echo "Wrong key? Use keys [1 - ${#options[@]}]"
    fi
  done
done

while $isRemoveMenu; do
    options=("Yes" "No")

    printHeader " Do you want to remove database also? "; echo
    COLUMNS=0
    select opt in "${options[@]}"; do
      case $REPLY in
        1) rm -rf $serverFolder; clearScreen; break 2 ;;
        2) clearScreen; break 2 ;;
        *) echo "Wrong key? Use keys [1 - ${#options[@]}]" >&2 ;;
      esac
    done
  done

echo "Bye bye!"
