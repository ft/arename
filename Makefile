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

install:
	cp arename.pl "${HOME}"/bin/
	chmod 0700 "${HOME}"/bin/arename.pl

install-doc: doc
	cp arename.1 /usr/local/share/man/man1/
	chmod 0644 /usr/local/share/man/man1/arename.1
