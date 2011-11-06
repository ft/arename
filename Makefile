# default installation location:
#   binaries: /usr/local/bin
#   module  : /usr/local/lib/site_perl
prefix="/usr/local"
libpath="lib/site_perl"
fakeroot="/usr/bin/fakeroot"
critic=""
maxwidth="14"

PERL ?= /usr/bin/perl

all:
	@printf 'Makefile targets intended for users:\n'
	@printf '  all            this text\n'
	@printf '  install        install both scripts and the module\n'
	@printf '  install-doc    install all documentation\n'
	@printf '  uninstall      remove both scripts and the module again\n'
	@printf '  uninstall-doc  remove the documentation\n'
	@printf '\nAll other targets are not for you. Stay away!\n'

test-help:
	@printf '\nMakefile targets intended for testers:\n'
	@printf 'DO NOT USE THESE UNLESS YOU READ THE '\''TESTINGS'\'' FILE!\n'
	@printf '  test           run the important parts of the test suite\n'
	@printf '  test-all       run every part of the test suite\n'
	@printf '  test-code      Check coding style using perlcritic\n'
	@printf '  test-doc       Check the pod syntax using podchecker\n'
	@printf '  test-install   Check the installation process\n'
	@printf '  test-suite     Run the ./tests/*.t test suite\n'
	@printf '  test-output    Run the ./tests/optest-perl script\n'
	@printf '  prepare-test-data\n'
	@printf '                 create audio data for the test suite\n'
	@printf '  test-help      this text\n'
	@printf '\n  Use '\''prove'\'' to run tests individually.\n'

dev-help: all test-help
	@printf '\nMakefile targets intended for developers:\n'
	@printf 'DO NOT USE THESE UNLESS YOU KNOW WHAT YOU ARE DOING!\n'
	@printf '  doc            generate arename.1 and arename.html\n'
	@printf '  dev-help       this text\n'
	@printf '  clean          clean up working tree\n'
	@printf '  distclean      same as clean, but removes .tars, too\n'
	@printf '  genperlscripts generate arename from arename.in\n'

genperlscripts:
	@$(PERL) ./bin/gps

doc: genperlscripts
	@./bin/gendoc.sh arename
	@./bin/gendoc.sh ataglist

clean:
	@[ ! -e arename.in ] && { printf 'DO NOT CALL THIS!\n' ; exit 1 ; } || true
	rm -f arename.html arename.1 ataglist.html ataglist.1 *.tmp .*~ *~ bin/*~ tests/*~ arename ataglist
	rm -f optest.pl
	rm -f */*.pm */*/*.pm */*/*/*.pm
	rm -Rf tests/data

distclean: clean
	rm -f *.tar.gz
	rm -f TAGS tags

install:
	@./bin/install.sh x arename       "$(prefix)/bin"                        $(maxwidth)
	@./bin/install.sh x ataglist      "$(prefix)/bin"                        $(maxwidth)
	@./bin/install.sh n modules/ARename.pm "$(prefix)/$(libpath)/"           $(maxwidth)
	@find modules/ARename -name "*.pm" -exec sh -c 's=$$1; d=$${1%/*}; d=$${d#modules/}; ./bin/install.sh n "$$s" "$(prefix)/$(libpath)/$$d/" $(maxwidth)' {} {} \;

install-doc:
	@./bin/install.sh n README        "$(prefix)/share/doc/arename"          $(maxwidth)
	@./bin/install.sh n UPGRADING     "$(prefix)/share/doc/arename"          $(maxwidth)
	@./bin/install.sh n REPORTING_BUGS "$(prefix)/share/doc/arename"         $(maxwidth)
	@./bin/install.sh n LICENCE       "$(prefix)/share/doc/arename"          $(maxwidth)
	@./bin/install.sh n CHANGES       "$(prefix)/share/doc/arename"          $(maxwidth)
	@./bin/install.sh n asdump        "$(prefix)/share/doc/arename"          $(maxwidth)
	@./bin/install.sh n arename.html  "$(prefix)/share/doc/arename"          $(maxwidth)
	@./bin/install.sh n arename.1     "$(prefix)/share/man/man1"             $(maxwidth)
	@./bin/install.sh n ataglist.html "$(prefix)/share/doc/arename"          $(maxwidth)
	@./bin/install.sh n ataglist.1    "$(prefix)/share/man/man1"             $(maxwidth)
	@./bin/install.sh n _arename      "$(prefix)/share/doc/arename/examples" $(maxwidth)

uninstall:
	@./bin/uninstall.sh f "$(prefix)/bin/arename"
	@./bin/uninstall.sh f "$(prefix)/bin/ataglist"
	@./bin/uninstall.sh f "$(prefix)/$(libpath)/ARename.pm"
	@./bin/uninstall.sh d "$(prefix)/$(libpath)/ARename"

uninstall-doc:
	@./bin/uninstall.sh d "$(prefix)/share/doc/arename"
	@./bin/uninstall.sh f "$(prefix)/share/man/man1/arename.1"
	@./bin/uninstall.sh f "$(prefix)/share/man/man1/ataglist.1"

test: test-check test-doc test-output test-suite

test-all: test-check test-install test-code test-doc test-output test-suite
	@printf '\nTested: '\''%s'\''\n\n' "$$(perl -Imodules ./arename -V)"

test-check:
	@[ ! -e tests/data/input.wav ] && { \
	  printf '\n  -- No data; Please read the TESTING file! --\n\n' ; \
	  exit 1 ; \
	} || true

test-install: doc
	@( \
	 if [ ! -x "$(fakeroot)" ] ; then \
	  printf 'fakeroot binary (%s) not found. Skipping installation test (see TESTING).\n' "$(fakeroot)" ;\
	  exit 0; \
	 fi ; \
	 "$(fakeroot)" /bin/sh ./tests/inst_t.sh ; \
	)

test-code:
	@CRITIC="$(critic)" sh ./bin/test-code.sh

test-doc:
	@( \
	 [ -e "arename.in" ] && PODFILE=arename.in || PODFILE=arename ; \
	 printf 'Checking pod syntax in "%s"...\n\n' "$$PODFILE" ; \
	 podchecker -warnings "$$PODFILE" || { \
	  printf '\n podchecker returned errors, please check!\n\n' ; \
	  exit 1 ; \
	 } ; \
	 if podchecker -warnings "$$PODFILE" 2>&1 | grep '^\*\*\* WARNING' > /dev/null 2>&1; then \
	  printf '\n podchecker returned warnings, please check!\n\n' ;\
	  exit 1 ; \
	 fi ; \
	 printf '\nPod syntax in "%s" passed all tests - okay.\n\n' "$$PODFILE" ; \
	)

test-output: genperlscripts
	perl tests/optest-perl
	@printf '\n\n  -!- Output routines appear to behaving properly.\n\n'

test-suite: test-check
	prove -Imodules -v tests/*.t

prepare-test-data:
	./bin/gentestsdata.sh

release: clean
	@./bin/dist.sh -r

prerelease: clean
	@./bin/dist.sh -p

snapshot: clean
	@./bin/dist.sh -s

tags:
	ctags --language-force=perl arename.in ARename.pm.in ataglist.in
	ctags -e --language-force=perl arename.in ARename.pm.in ataglist.in

.PHONY: install install-doc distclean clean all doc test-check tags
