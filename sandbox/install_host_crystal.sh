#/bin/sh

version=$(echo $(pacman -Qi crystal | grep Version | cut -d':' -f2))
pkg="crystal-$version-i686.pkg.tar.xz"
cp "/var/cache/pacman/pkg/$pkg" sandbox/crystal/
arch-chroot sandbox pacman -U "/crystal/$pkg"
