================================================================================
                        KAIDONG'S MINIMAL NIXOS VM
================================================================================

DESCRIPTION
-----------
This repository contains a minimal NixOS configuration for an experimental
virtual machine environment. It uses NixOS flakes to provide a reproducible
and declarative VM setup suitable for testing and development purposes.

The VM includes:
- XFCE desktop environment
- Emacs editor
- Zsh shell with Oh My Zsh
- SSH server enabled
- User account: kaidong (initial password: kaidong)


BUILD INSTRUCTIONS
------------------
To build the virtual machine, run:

    nix run

Or alternatively:

    nix build
    ./result/bin/run-nixos-vm


USAGE
-----
Once the VM starts, you can:

1. Log in with:
   - Username: kaidong
   - Password: kaidong

2. The VM will start with XFCE desktop environment

3. SSH is enabled, so you can SSH into the VM if needed

   To run the VM with SSH accessible from the host, use:

       QEMU_NET_OPTS=hostfwd=tcp::2222-:22 nix run . --impure

   Then you can SSH into the VM with:

       ssh -p 2222 kaidong@localhost

4. To stop the VM, simply close the QEMU window or shutdown from within
   the system


CUSTOMIZATION
-------------
Edit the configuration.nix file to customize your VM setup:
- Add/remove packages in environment.systemPackages
- Configure services and system options
- Modify user settings

After making changes, rebuild the VM with:

    nix run


PERSISTENT STORAGE
------------------
The VM uses nixos.qcow2 as its disk image. This file persists between runs,
so your changes and data will be saved. To reset the VM, delete this file
and rebuild.


LEARN MORE
----------
For more information about NixOS virtual machines, see:
https://nix.dev/tutorials/nixos/nixos-configuration-on-vm.html


REPOSITORY STRUCTURE
--------------------
- flake.nix              : Flake configuration defining the VM package
- configuration.nix      : Main NixOS system configuration
- hardware-configuration.nix : Hardware-specific settings for the VM
- nixos.qcow2           : VM disk image (created on first run)
- result                : Symlink to built VM (created after build)


================================================================================

