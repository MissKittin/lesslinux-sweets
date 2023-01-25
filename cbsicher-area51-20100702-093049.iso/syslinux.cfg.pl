DEFAULT /boot/isolinux/menu.c32
TIMEOUT 300

PROMPT 0

# MENU TITLE COMPUTERBILD Safer Surfing
# MENU TABMSG  
# MENU AUTOBOOT Automatic boot in # second{,s}...

MENU TITLE KOMPUTER SWIAT Bezpiecznie w internecie
MENU TABMSG  
MENU AUTOBOOT Automatyczny start za # s

# MENU TITLE COMPUTERBILD Sicher Surfen
# MENU TABMSG  
# MENU AUTOBOOT Automatischer Start in # Sekunde{,n}...

#######################

LABEL polish
MENU LABEL Polski
MENU DISABLE
MENU HIDE

LABEL 0pl
MENU LABEL Pelny start
# MENU INDENT 2
KERNEL /boot/isolinux/l2633px
APPEND initrd=/boot/isolinux/devs.img,/boot/isolinux/initram.img,/boot/isolinux/i2633px.img ramdisk_size=100000 vga=788 ultraquiet=1 security=smack skipcheck=1 quiet lang=pl toram=999999999 skipservices=|earlynet|ssh|mountcdrom|loadata|installer|xconfgui|roothash|  hwid=unknown 
TEXT HELP
  Ta opcja pozwala wybrac optymalne ustawienia wyswietalania. 
  Dodatkowo uzyskasz dostep do twardych dyskow i napedow USB,
  aby zapisywac na nich pliki pobrane z internetu.
ENDTEXT

LABEL 1pl
MENU LABEL Szybki start
# MENU INDENT 2
KERNEL /boot/isolinux/l2633px
APPEND initrd=/boot/isolinux/devs.img,/boot/isolinux/initram.img,/boot/isolinux/i2633px.img ramdisk_size=100000 vga=788 ultraquiet=1 security=smack skipcheck=1 quiet lang=pl toram=999999999 skipservices=|earlynet|ssh|mountcdrom|loadata|hwproto|xconfgui|installer|runtimeconf|roothash|  hwid=unknown 
TEXT HELP
  Jesli chcesz tylko przegladac internet, wybierz te opcje.
  System z plyty uruchomi sie ze standardowymi ustawieniami, 
  ale bez dostepu do dyskow.
ENDTEXT

LABEL 2pl
MENU LABEL Instalacja
# MENU INDENT 2
MENU HIDE
KERNEL /boot/isolinux/l2633px
APPEND initrd=/boot/isolinux/devs.img,/boot/isolinux/initram.img,/boot/isolinux/i2633px.img ramdisk_size=100000 vga=788 ultraquiet=1 security=smack skipcheck=1 quiet lang=pl toram=9999999999  skipservices=|earlynet|ssh|mountcdrom|loadata|xconfgui|dbus|wicd|runtimeconf|alsaprepare|ffprep|roothash|  hwid=unknown 
TEXT HELP
  Zainstaluj system Bezpiecznie w internecie na pendrivie lub
  dysku USB. Twoje ustawienia, e-maile i pliki beda bezpiecznie
  przechowywane w zaszyfrowanym kontenerze.
ENDTEXT

LABEL 3pl
MENU LABEL -> Bezpieczny start
MENU INDENT 2
KERNEL /boot/isolinux/menu.c32
APPEND /boot/isolinux/safeu_pl.cfg
TEXT HELP
  Tu znajdziesz ustawienia dla sprzetu, ktory moze sprawiac problemy.
ENDTEXT

#######################

