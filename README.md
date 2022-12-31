# alpis

This is ALT Linux post-install script for my personal needs.  
Currently it supports *p9* and *p10* branches with MATE desktop (Workstation and MATE StarterKit) and Xfce (Simply Linux).

Dependencies: `sudo` enabled using `su -l -c "usermod -a -G wheel $USER; control sudo wheelonly; control sudoers relaxed; control sudoreplay wheelonly; control sudowheel enabled;"` (as in SimplyLinux) and `lsb-release` [package](https://packages.altlinux.org/en/sisyphus/srpms/lsb-release/) installed, *tmpfs* > 2 Gb (or disabled in `/etc/fstab`).

One can launch this script on freshly installed system using commands below:

```
cd ~/Downloads
wget -c https://raw.githubusercontent.com/N0rbert/alpis/master/alpis.sh
chmod +x alpis.sh
sudo -E ./alpis.sh
```

