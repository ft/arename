# default installation location:
#   binaries: /usr/local/bin
#   module  : /usr/local/lib/site_perl
prefix="/usr/local"
libpath="lib/site_perl"

all: arename.1 arename.html

doc: all

arename.1: arename.pl
	pod2man  ./arename.pl > arename.1    2>/dev/null

arename.html: arename.pl
	pod2html ./arename.pl > arename.html 2>/dev/null
	@rm -f *.tmp

clean: distclean

distclean:
	rm -f arename.html arename.1 *.tmp *~

install:
	@printf 'Installing arename.pl  to %s\n' "$(prefix)/bin"
	@cp arename.pl   "$(prefix)/bin/"
	@printf 'Installing ataglist.pl to %s\n' "$(prefix)/bin"
	@cp ataglist.pl  "$(prefix)/bin/"
	@chown root:root "$(prefix)/bin/arename.pl" "$(prefix)/bin/ataglist.pl"
	@chmod 0755      "$(prefix)/bin/arename.pl" "$(prefix)/bin/ataglist.pl"
	@printf 'Installing ARename.pm  to %s\n' "$(prefix)/$(libpath)/ARename.pm"
	@[ ! -d "$(prefix)/$(libpath)" ] && (mkdir -p "$(prefix)/$(libpath)" && chmod 0755 "$(prefix)/$(libpath)" ) || true
	@cp ARename.pm   "$(prefix)/$(libpath)"
	@chmod 0644      "$(prefix)/$(libpath)/ARename.pm"

install-doc: doc
	@printf 'Installing arename.1  to %s\n' "$(prefix)/share/man/man1"
	@cp arename.1    "$(prefix)/share/man/man1/"
	@chown root:root "$(prefix)/share/man/man1/arename.1"
	@chmod 0644      "$(prefix)/share/man/man1/arename.1"

.PHONY: install install-doc distclean clean all doc
