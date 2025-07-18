 $ make
gcc -O2 -Wall -fPIC -DPACKAGE=\"qconf\" -DLOCALEDIR=\"/usr/share/locale\" -DKBUILD_NO_NLS -D_GNU_SOURCE -c parser_stubs.c -o parser_stubs.o
g++ -o qconf zconf.tab.o parser_stubs.o qconf.o -lQt5Widgets -lQt5Gui -lQt5Core 
