{
  # Use this config on a live system with
  # > nix --experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko /tmp/luks-btrfs-subvolumes.nix
  #
  # Then set nodatacow for required subvolumesr:
  # > chattr +C /mnt/<mounted-subvolume-folder>
  # > lsattr /mnt
  # or
  # > lsattr -d /mnt/<mounted-subvolume-folder>
  # The mount option 'nodatacow' cannot be used if there are other subvolumes with datacow enabled
  # https://wiki.archlinux.org/title/btrfs
  # " within a single file system, it is not possible to mount some subvolumes with nodatacow and others with datacow. The mount option of the first mounted subvolume applies to any other subvolumes. "
  #
  # Last, install nixos indicating --no-filesystems so it doesn't override disko setup:
  # > nixos-generate-config --no-filesystems --root /mnt
  #
  disko.devices = {
    disk = {
      vdb = {
        type = "disk";
        device = "/dev/nvme1n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" "defaults" ];
              };
            };
            luks = {
              size = "500G";
              content = {
                type = "luks";
                name = "crypted";
                # disable settings.keyFile if you want to use interactive password entry
                #passwordFile = "/tmp/secret.key"; # Interactive
                settings = {
                  allowDiscards = true;
                  # echo -n "<password" > /tmp/secret.key
                  passwordFile = "/tmp/secret.key";
                };
                # additionalKeyFiles = [ "/tmp/additionalSecret.key" ];
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "@nixos" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    # Preserve root home in a sepparate subvol
                    "@root" = {
                      mountpoint = "/root";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@nixstore" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@nixos/log" = {
                      mountpoint = "/log";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@nixos/tmp" = {
                      mountpoint = "/tmp";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@nixos/srv" = {
                      mountpoint = "/srv";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "@nixos/var" = {
                      mountpoint = "/var";
                      mountOptions = [ "compress=zstd" "noatime" ];
                      # Set no-cow with
                      # > chattr +C /mnt/var
                      # once mounted
                    };
                  };
                };
              };
            };
            encryptedSwap = {
              size = "33G";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
          };
        };
      };
    };
  };
}

