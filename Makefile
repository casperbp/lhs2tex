
include config.mk

sources		:= Main.lhs TeXCommands.lhs TeXParser.lhs \
		   Typewriter.lhs Math.lhs MathPoly.lhs \
                   NewCode.lhs \
		   Directives.lhs HsLexer.lhs FileNameUtils.lhs \
		   Parser.lhs FiniteMap.lhs Auxiliaries.lhs \
		   StateT.lhs Document.lhs Verbatim.lhs Value.lhs \
		   Version.lhs
snips		:= sorts.tt sorts.math id.math cata.math spec.math
objects         := $(foreach file, $(sources:.lhs=.o), $(file))
sections       	:= $(foreach file, $(sources:.lhs=.tex), $(file))

MKINSTDIR       := ./mkinstalldirs

###
### lhs dependencies (from %include lines)
###

MKLHSDEPEND = $(GREP) "^%include " $< \
               | $(SED) -e 's,^%include ,$*.tex : ,' \
               | $(SORT) | $(UNIQ) > $*.ld

MKFMTDEPEND = $(GREP) "^%include " $< \
               | $(SED) -e 's,^%include ,$*.fmt : ,' \
               | $(SORT) | $(UNIQ) > $*.ld

###
### hs dependencies
###


MKGHCDEPEND = $(GHC) -M -optdep-f -optdep$*.d $(GHCFLAGS) $<

###
### dependency postprocessing
###

DEPPOSTPROC = $(SED) -e 's/\#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
	         -e '/^$$/ d' -e 's/$$/ :/'

###
### default targets
###

.PHONY : default xdvi gv print install backup clean all depend doc

all : default

default : lhs2TeX doc

%.d : %.lhs
	$(MKGHCDEPEND); \
	$(CP) $*.d $*.dd; \
	$(DEPPOSTPROC) < $*.dd >> $.d; \
	$(RM) -f $*.dd

$(objects) : %.o : %.lhs
	$(GHC) -c $(GHCFLAGS) $< -o $@

-include $(sources:%.lhs=%.d)

# I don't understand this ... (ks)
#
# %.hi : %.o
# 	@if [ ! -f $@ ] ; then \
#	echo $(RM) $< ; \
#	$(RM) $< ; \
#	set +e ; \
#	echo $(MAKE) $(notdir $<) ; \
#	$(MAKE) $(notdir $<) ; \
#	if [ $$? -ne 0 ] ; then \
#	exit 1; \
#	fi ; \
#	fi

%.hi : %.o
	@:

%.ld : %.lhs
	$(MKLHSDEPEND); \
	$(CP) $*.ld $*.ldd; \
	$(DEPPOSTPROC) < $*.ldd >> $*.ld; \
	$(RM) -f $*.ldd

%.ld : %.fmt
	$(MKFMTDEPEND); \
	$(CP) $*.ld $*.ldd; \
	$(DEPPOSTPROC) < $*.ldd >> $*.ld; \
	$(RM) -f $*.ldd

%.tex : %.lhs lhs2TeX Lhs2TeX.fmt lhs2TeX.fmt
#	lhs2TeX -verb -iLhs2TeX.fmt $< > $@
	./lhs2TeX --math --align 33 -iLhs2TeX.fmt $< > $@

-include $(sources:%.lhs=%.ld)

%.tt : %.snip lhs2TeX lhs2TeX.fmt
	./lhs2TeX --tt -lmeta=True -ilhs2TeX.fmt $< > $@

%.math : %.snip lhs2TeX lhs2TeX.fmt
	./lhs2TeX --math --align 33 -lmeta=True -ilhs2TeX.fmt $< > $@

%.tex : %.lit lhs2TeX
	./lhs2TeX --verb -ilhs2TeX.fmt $< > $@


lhs2TeX.sty: lhs2TeX.sty.lit lhs2TeX
	./lhs2TeX --code lhs2TeX.sty.lit > lhs2TeX.sty
lhs2TeX.fmt: lhs2TeX.fmt.lit lhs2TeX
	./lhs2TeX --code lhs2TeX.fmt.lit > lhs2TeX.fmt

lhs2TeX : $(objects)
	$(GHC) $(GHCFLAGS) -o lhs2TeX $(objects)

doc : lhs2TeX lhs2TeX.sty lhs2TeX.fmt
	cd Guide; $(MAKE) Guide.pdf

depend:
	$(GHC) -M -optdep-f -optdeplhs2TeX.d $(GHCFLAGS) $(sources)
	$(RM) -f lhs2TeX.d.bak

lhs2TeX-includes : lhs2TeX.sty $(sections) $(snips) lhs2TeX.sty.tex lhs2TeX.fmt.tex Makefile.tex

Lhs2TeX.dvi : lhs2TeX-includes
Lhs2TeX.pdf : lhs2TeX-includes

xdvi : Lhs2TeX.dvi
	$(XDVI) -s 3 Lhs2TeX.dvi &

gv : Lhs2TeX.ps
	$(GV) Lhs2TeX.ps &

print : Lhs2TeX.dvi
	$(DVIPS) -D600 -f Lhs2TeX.dvi | lpr -Pa -Zl

install : lhs2TeX lhs2TeX.sty lhs2TeX.fmt
	$(MKINSTDIR) $(DESTDIR)$(bindir)
	$(INSTALL) -m 755 lhs2TeX $(DESTDIR)$(bindir)
	$(MKINSTDIR) $(DESTDIR)$(stydir)
	$(INSTALL) -m 644 lhs2TeX.sty lhs2TeX.fmt $(DESTDIR)$(stydir)

backup:
	cd ..; \
	$(RM) -f Literate.tar Literate.tar.gz; \
	tar -cf Literate.tar Literate; \
	gzip Literate.tar; \
	chmod a+r Literate.tar.gz

clean :
#	clean
	$(RM) -f lhs2TeX $(sections) $(snips) $(objects) *.hi *.dvi *.ps
	-$(RM) -f *.d *.dd *.ld *.ldd
	$(RM) -f lhs2TeX.sty lhs2TeX.fmt
	$(RM) -f Lhs2TeX.tex lhs2TeX.sty.tex lhs2TeX.fmt.tex Makefile.tex 
	cd Guide; $(MAKE) clean

# all:
# 	$(MAKE) install
# 	$(MAKE) Lhs2TeX.dvi

include common.mk