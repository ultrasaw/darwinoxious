{ lib, pkgs, ... }:

let
  kanata = pkgs.kanata;
  karabinerDriver = kanata.passthru.darwinDriver;
  karabinerManagerApp = "/Applications/.Karabiner-VirtualHIDDevice-Manager.app";
  kanataApp = "/Applications/Kanata.app";

  kanataInfoPlist = pkgs.writeText "Kanata-Info.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleExecutable</key>
      <string>kanata</string>
      <key>CFBundleIdentifier</key>
      <string>org.nixos.kanata</string>
      <key>CFBundleInfoDictionaryVersion</key>
      <string>6.0</string>
      <key>CFBundleName</key>
      <string>Kanata</string>
      <key>CFBundlePackageType</key>
      <string>APPL</string>
      <key>CFBundleShortVersionString</key>
      <string>${kanata.version}</string>
      <key>CFBundleVersion</key>
      <string>${kanata.version}</string>
      <key>LSMinimumSystemVersion</key>
      <string>13.0</string>
      <key>LSUIElement</key>
      <true/>
    </dict>
    </plist>
  '';

  kanataConfig = pkgs.writeTextFile {
    name = "kanata-caps-symbols.kbd";
    text = ''
      (defcfg
        process-unmapped-keys yes
        macos-dev-names-include (
          "Apple Internal Keyboard / Trackpad"
          "NuPhy Gem80"
        )
      )

      (defsrc caps d e y u i o j k l ;)

      (defalias
        sym (layer-while-held symbols)
      )

      (deflayer base
        @sym d e y u i o j k l ;
      )

      (deflayer symbols
        _ bspc ret 7 8 9 0 [ ] - =
      )
    '';
    checkPhase = ''
      ${lib.getExe kanata} --cfg "$target" --check --debug
    '';
  };
in
{
  environment.systemPackages = [
    kanata
    karabinerDriver
  ];

  system.activationScripts.launchd.text = lib.mkBefore ''
    echo "setting up Karabiner VirtualHIDDevice manager app..." >&2
    rm -rf ${lib.escapeShellArg karabinerManagerApp}
    /usr/bin/ditto \
      ${lib.escapeShellArg "${karabinerDriver}/Applications/.Karabiner-VirtualHIDDevice-Manager.app"} \
      ${lib.escapeShellArg karabinerManagerApp}

    echo "setting up Kanata app wrapper..." >&2
    rm -rf ${lib.escapeShellArg kanataApp}
    mkdir -p ${lib.escapeShellArg "${kanataApp}/Contents/MacOS"}
    cp ${lib.escapeShellArg "${lib.getExe kanata}"} ${lib.escapeShellArg "${kanataApp}/Contents/MacOS/kanata"}
    chmod 755 ${lib.escapeShellArg "${kanataApp}/Contents/MacOS/kanata"}
    cp ${lib.escapeShellArg kanataInfoPlist} ${lib.escapeShellArg "${kanataApp}/Contents/Info.plist"}
    /usr/bin/codesign --force --deep --sign - ${lib.escapeShellArg kanataApp}
  '';

  launchd.daemons.karabiner-vhiddaemon = {
    serviceConfig = {
      ProgramArguments = [
        "${karabinerDriver}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/log/karabiner-vhiddaemon.out.log";
      StandardErrorPath = "/var/log/karabiner-vhiddaemon.err.log";
    };
  };

  launchd.daemons.karabiner-vhidmanager = {
    serviceConfig = {
      ProgramArguments = [
        "${karabinerManagerApp}/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager"
        "activate"
      ];
      RunAtLoad = true;
      StandardOutPath = "/var/log/karabiner-vhidmanager.out.log";
      StandardErrorPath = "/var/log/karabiner-vhidmanager.err.log";
    };
  };

  launchd.daemons.kanata = {
    serviceConfig = {
      ProgramArguments = [
        "${kanataApp}/Contents/MacOS/kanata"
        "--cfg"
        "${kanataConfig}"
        "--no-wait"
        "--debug"
        "--log-layer-changes"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/log/kanata.out.log";
      StandardErrorPath = "/var/log/kanata.err.log";
    };
  };
}
