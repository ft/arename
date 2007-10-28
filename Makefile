all: arename.1 arename.html

doc: all

arename.1: arename.pl
	pod2man  ./arename.pl > arename.1

arename.html: arename.pl
	pod2html ./arename.pl > arename.html
	rm -f *.tmp

clean: distclean

distclean:
	rm -f arename.html arename.1 *.tmp *~
