
Debian
====================
This directory contains files used to package filokd/filok-qt
for Debian-based Linux systems. If you compile filokd/filok-qt yourself, there are some useful files here.

## filok: URI support ##


filok-qt.desktop  (Gnome / Open Desktop)
To install:

	sudo desktop-file-install filok-qt.desktop
	sudo update-desktop-database

If you build yourself, you will either need to modify the paths in
the .desktop file or copy or symlink your filokqt binary to `/usr/bin`
and the `../../share/pixmaps/filok128.png` to `/usr/share/pixmaps`

filok-qt.protocol (KDE)

