{ lib, pkgs, ... }:

let
  kanata = pkgs.kanata;
  karabinerDriver = kanata.passthru.darwinDriver;
  karabinerSupportDir = "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice";
  karabinerManagerApp = "/Applications/.Karabiner-VirtualHIDDevice-Manager.app";
  kanataBin = "/Library/Application Support/org.nixos/kanata/bin/kanata";

  kanataConfig = pkgs.writeTextFile {
    name = "kanata-caps-symbols.kbd";
    text = ''
      (defcfg
        process-unmapped-keys yes
        macos-dev-names-include (
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
        _ A-bspc ret 7 8 9 0 [ ] - =
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

    echo "setting up Karabiner VirtualHIDDevice support files..." >&2
    rm -rf ${lib.escapeShellArg karabinerSupportDir}
    mkdir -p ${lib.escapeShellArg (dirOf karabinerSupportDir)}
    /usr/bin/ditto \
      ${lib.escapeShellArg "${karabinerDriver}/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice"} \
      ${lib.escapeShellArg karabinerSupportDir}

    echo "removing obsolete Kanata app wrapper..." >&2
    rm -rf /Applications/Kanata.app

    echo "setting up stable Kanata executable..." >&2
    mkdir -p ${lib.escapeShellArg (dirOf kanataBin)}
    cp -f ${lib.escapeShellArg (lib.getExe kanata)} ${lib.escapeShellArg kanataBin}
    chmod 755 ${lib.escapeShellArg kanataBin}
  '';

  launchd.daemons.karabiner-vhiddaemon = {
    serviceConfig = {
      ProgramArguments = [
        "${karabinerSupportDir}/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
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
        kanataBin
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
