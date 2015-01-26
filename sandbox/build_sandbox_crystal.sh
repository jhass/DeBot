#!/bin/sh

sudo rm sandbox_crystal
crystal build --release -o sandbox_crystal sandbox_crystal.cr
sudo chown root:root sandbox_crystal
sudo chmod 4755 sandbox_crystal
