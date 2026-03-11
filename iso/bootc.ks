lang de_DE.UTF-8
keyboard de
timezone Europe/Berlin --utc

network --bootproto=dhcp

bootloader --location=mbr
clearpart --all --initlabel
autopart

reboot

bootc install ghcr.io/humocs-man/fluffy-pancake:stable
