#!/bin/sh

umount sandbox
rm -rf sandbox
mkdir -p sandbox

pacstrap -cd sandbox \
  bash \
  binutils \
  curl \
  fakeroot  \
  file \
  gc \
  gcc \
  git \
  grep \
  libatomic_ops \
  libpcl \
  libunwind \
  libxml2 \
  libyaml \
  llvm \
  make \
  pacman \
  pcre 

cd sandbox

mkdir -p dev/shm
mknod -m666 dev/null c 1 3

arch-chroot . useradd -m crystal
echo "en_US.UTF-8 UTF-8" >> etc/locale.gen
arch-chroot . locale-gen
echo "LANG=en_US.UTF-8" > etc/locale.conf

yaourt -G crystal-git
arch-chroot . chown -R crystal:users crystal-git
arch-chroot . /bin/sh -c 'cd /crystal-git; su crystal -- makepkg'
arch-chroot . pacman -U crystal-git/crystal-*.tar.xz 
