.POSIX:
.SUFFIXES: .el .elc

EMACS    = emacs
MAKEINFO = makeinfo
COMPILE  = mct.elc

all: compile mct.info

.PHONY: compile
compile: $(COMPILE)

.PHONY: clean
clean:
	rm -f $(COMPILE) mct.texi mct.info

mct.texi: README.org
	$(EMACS) -Q --batch $< -f org-texinfo-export-to-texinfo --kill

mct.info: mct.texi
	$(MAKEINFO) $<

.el.elc:
	$(EMACS) -Q --batch -L . -f batch-byte-compile $^
