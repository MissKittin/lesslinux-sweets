DEFAULT /boot/isolinux/menu.c32
TIMEOUT 300

PROMPT 0

MENU TITLE Plyta ratunkowa 2010
MENU AUTOBOOT Automatyczny start za # s
MENU TABMSG

LABEL 11
MENU LABEL Normalny start
KERNEL /boot/isolinux/l2633vn
APPEND initrd=/boot/isolinux/devs.img,/boot/isolinux/initram.img,/boot/isolinux/i2633vn.img ramdisk_size=100000 vga=788 ultraquiet=1 security=none skipcheck=1 quiet lang=de toram=999999999  skipservices=|earlynet|installer|xconfgui|roothash|firewall|ssh|  hwid=unknown laxsudo=1
TEXT HELP
  Ta opcja pozwala wybrac optymalne ustawienia wyswietalania. 
  Dodatkowo uzyskasz dostep do twardych dyskow i napedow USB,
  aby zapisywac na nich pliki pobrane z internetu.
ENDTEXT

LABEL safemode
MENU LABEL -> Bezpieczny start
# MENU HIDE
KERNEL /boot/isolinux/menu.c32
APPEND /boot/isolinux/safusbpl.cfg
TEXT HELP
  Wybierz to ustawienie wtedy, gdy normalne uruchomienie 
  nie dziala na twoim komputerze.
ENDTEXT

LABEL memtest
MENU LABEL Sprawdzanie pamieci
KERNEL /boot/isolinux/memdisk
APPEND initrd=/boot/isolinux/memtest.img


