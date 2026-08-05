{
  disk ? "/dev/nvme0n1",
  ...
}:

{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = disk;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                extraArgs = [
                  "-n"
                  "BOOT"
                ];
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };

            root = {
              end = "-17G";
              content = {
                type = "filesystem";
                format = "ext4";
                extraArgs = [
                  "-L"
                  "nixos"
                ];
                mountpoint = "/";
              };
            };

            swap = {
              size = "100%";
              content = {
                type = "swap";
                extraArgs = [
                  "-L"
                  "swap"
                ];
              };
            };
          };
        };
      };
    };
  };
}
