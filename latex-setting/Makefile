default: dvi
all: pdf

help:
	@echo  'Cleaning targets:'
	@echo  '  clean       - Remove most generated files but keep the figure converted files'
	@echo  '  distclean   - Remove all generated fiels'
	@echo  ''
	@echo  'Other generic targets:'
	@echo  '  all         - Build all targets marked with [*]'
	@echo  '* dvi         - Build DVI file'
	@echo  '* pdf         - Build PDF file'
	@echo  '* fig         - Build figure files'
	@echo  '  rename      - Build uniq named PDF file'
	@echo  ''
	@echo  'Useful interface:'
	@echo  '  vdvi        - Open DVI file'
	@echo  '  vpdf view   - Open PDF file'
	@echo  ''
	@echo  'nkf:'
	@echo  '  nkf-euc     - Change character code to EUC'
	@echo  '  nkf-sjis    - Change character code to Shift-JIS'
	@echo  '  nkf-utf8    - Change character code to UTF-8'
	@echo  ''
	@echo  'Packaging:'
	@echo  '  archive     - Archive document of current directory'
	@echo  '  archive-git - Archive document of current directory by git'

MAIN := main

## Configuration for document (overwrite by Makefile.d)
# The main TeX file name (exclude .tex)
MY-MAIN		 := $(shell find . -name "*.tex" -type f)
MY-MAIN		 := $(basename ${MY-MAIN})
# Other dependencies to generate
MY-DEPS          :=
# Other Makefiles
MY-MAKEFILES     :=
# Version
MY-VERSION       := 0
# An unique document name for publish
MY-UNIQ-FILENAME := $(MY-MAIN).$(MY-VERSION)
# Convert pdf to eps (yes|no)
CONV-PDF-TO-EPS  := no
# join logs  (yes|no) Needs Ruby.
JOIN-LOGS        := no

MAIN := $(MY-MAIN)

## Environment Variables
# Use shell
SHELL = bash

## Commands for Linux
XDVI     := xdvi-ja
VIEW     := acroread -openInNewWindow /a "zoom=0"
FINDER   := nautilus
BIBTEX   := pbibtex	# or jbibtex
EMACS    := emacs
PLATEX   := platex -halt-on-error -interaction=nonstopmode -file-line-error
INKSCAPE := inkscape
TGIF     := tgif
PDFTOPS  := pdftops

# Commands for Mac OS
ifeq ("$(shell uname)","Darwin")
	XDVI     := open -a Mxdvi
#	XDVI     := /Applications/Mxdvi.app/Contents/MacOS/Mxdvi
	VIEW     := open
	FINDER   := open
	BIBTEX   := pbibtex -kanji=euc
	EMACS    := /Applications/Emacs.app/Contents/MacOS/Emacs
	PLATEX   := platex -kanji=euc
    INKSCAPE := /Applications/Inkscape.app/Contents/MacOS/Inkscape
endif

# A timestamp format
TIMESTAMP := $(shell date +%Y%m%d)

## Define dependent files to generate DVI file
SRC-FIGURE-DIRS := $(shell find . -name "*.png" -or -name "*.eps" -or -name "*.svg" | cut -d "/" -f 2 | head -n1)
SRC-OBJ := $(wildcard $(addsuffix /*.obj,$(SRC-FIGURE-DIRS))) # Tgif files
SRC-SVG := $(wildcard $(addsuffix /*.svg,$(SRC-FIGURE-DIRS))) # Inkscape files
SRC-PNG := $(wildcard $(addsuffix /*.png,$(SRC-FIGURE-DIRS))) # Some pictures
SRC-PDF := $(wildcard $(addsuffix /*.pdf,$(SRC-FIGURE-DIRS))) # Power Point, Visio, and so on

# Will generate files (They will be removed by clean-full)
DST-FIG := $(SRC-SVG:%.svg=%.pdf)            # svg -> pdf
# DST-FIG += $(SRC-PNG:%.png=%.bb)             # png -> bb
DST-FIG += $(SRC-PNG:%.png=%.eps)            # png -> eps
DST-FIG += $(SRC-OBJ:%.obj=%.eps)            # obj -> eps
# DST-FIG += $(SRC-PDF:%.pdf=%.bb)			 # pdf -> bb
ifeq ("$(CONV-PDF-TO-EPS)","yes")
	DST-FIG += $(SRC-PDF:%.pdf=%.eps)		 # pdf -> eps
endif

# Input figure files for LaTeX
DVISRC-FIG := $(DST-FIG)
DVISRC-FIG += $(wildcard $(addsuffix /*.eps,$(SRC-FIGURE-DIRS))) # original EPSs
DVISRC-FIG += $(wildcard $(addsuffix /*.pdf,$(SRC-FIGURE-DIRS))) # original PDFs

# Input TeX files for LaTeX
DVISRC-TEX := $(MAIN).tex $(wildcard *.tex)
# DVISRC-TEX += $(wildcard **/*.tex)           # dependent to zsh

# Input other files for LaTeX
DVISRC-SRC := $(wildcard src/*)

# All dependent files for LaTeX
DVISRC := $(DVISRC-FIG) $(DVISRC-TEX) $(DVISRC-SRC) $(MY-DEPS) \
          $(wildcard *.cfg) $(wildcard *.cls) $(wildcard *.bib) $(wildcard *.bst) \
          $(wildcard *.sty) $(wildcard styles/*.sty)


## Basic targets
dvi: $(MAIN).dvi
pdf: $(MAIN).pdf
fig: $(DVISRC-FIG)

# Run individual Makefiles
prepare:
	@for F in $(MY-MAKEFILES) ;\
	do \
		echo MAKE\\t$$F ;\
		make --no-print-directory -C $$(dirname $$F) -f $$(basename $$F) ;\
	done

rename: $(MAIN).pdf
	@if [ $(MAIN).pdf != $(MY-UNIQ-FILENAME).pdf ]  ;\
	then                                        \
		rm -f $(MY-UNIQ-FILENAME).pdf          ;\
		cp $(MAIN).pdf $(MY-UNIQ-FILENAME).pdf ;\
	fi

define latex-join-log
  ruby -Ku -e ' \
    s = "" ;\
    readlines.each {|l|  \
      l = l.chomp ;\
      if l.empty?       ;\
        puts s; s = ""  ;\
      else              ;\
        unless s.empty? ;\
          if l =~ /^\(/  ;\
            s << " <NL> " ;\
          end ;\
        end ;\
        s << l.gsub(/\s+/) {|t| t.size >= 2 ? "  " : " "} ;\
      end               ;\
    } ;\
    puts s unless s.empty?' $1
endef
define strong
	echo -en "\e[1;31m" ;\
	echo -n  $1$2$3$4$5$6$7$8$9 ;\
	echo -e  "\e[m"
endef

figures: $(DVISRC-FIG)

$(MAIN).dvi: $(DVISRC)
	@make prepare
	@rm -f $@
	@$(call strong,PLATEX)
	@$(PLATEX) $(MAIN).tex
	@test -f $@
	@if [ -f "references.bib" ] ; then   \
		$(call strong,BIBTEX)           ;\
		$(BIBTEX) $(MAIN) > jbibtex.log ;\
	fi
	@if [ -f "$(MAIN).idx" ] ; then   \
		$(call strong,MANDEX)        ;\
		mendex $(MAIN).idx           ;\
	fi
	@$(call strong,PLATEX)
	@$(PLATEX) $(MAIN).tex
	@$(call strong,PLATEX)
	@$(PLATEX) $(MAIN).tex
	@if [ "$(JOIN-LOGS)" = "yes" ] ; then    \
		$(call latex-join-log,$(@:.dvi=.log)) > platex.log ; \
		if [ -f "references.bib" ] ; then  \
			if grep Warning jbibtex.log > /dev/null ; then \
				ruby -e 'puts "\n"+"="*80'; \
				$(call strong,"WARNING (jbibtex):") ;\
				nkf -u jbibtex.log | grep Warning | sed -e 's/<NL>/\n  /g' ;\
			fi ;\
		fi  ;\
		if grep Warning platex.log > /dev/null; then \
			ruby -e 'puts "\n"+"="*80'; \
			$(call strong,"WARNING (platex):") ;\
			nkf -u platex.log | grep Warning | sed -e 's/<NL>/\n  /g' ;\
		fi  ;\
	fi

$(MAIN).pdf: dvi
	dvipdfmx -f texfonts.map -q $(MAIN).dvi


## Figure conversion algorithms
%.bb: %.png
	cd $(shell dirname "$<") && ebb $(shell basename $<)
%.bb: %.pdf
	cd $(shell dirname "$<") && ebb $(shell basename $<)
%.eps: %.png
	convert $< eps2:$@

# Inkscape: svg -> eps
%.eps: %.svg
	$(INKSCAPE) $< --export-eps=$@ --export-text-to-path --export-area-drawing

%.pdf: %.svg
	rsvg-convert -f pdf -o $@ $<

# Tgif: obj -> eps
%.eps: %.obj
	$(TGIF) -print -eps $<

# Power Point, Visio: pdf -> eps
#   Mac OS: [brew install xpdf] but not good
%.eps: %.pdf
	$(PDFTOPS) -eps $<
%.ps: %.pdf
	$(PDFTOPS) $<

# nkf:
nkf-utf8:
	nkf -w8 --overwrite *.tex *.sty Makefile ipsjunsrt.bst references.bib eco.cls
nkf-euc:
	nkf -e --overwrite *.tex *.sty Makefile ipsjunsrt.bst references.bib eco.cls
nkf-sjis:
	nkf -s --overwrite *.tex *.sty Makefile ipsjunsrt.bst references.bib eco.cls

## Interfaces
vdvi: dvi
	$(XDVI) $(MAIN).dvi &
kill-acroread:
	-killall acroread $(MAIN).pdf
vpdf: kill-acroread pdf
	acroread $(MAIN).pdf &
view: $(MAIN).pdf
	$(VIEW) $(MAIN).pdf &
vfig:
	$(FINDER) fig &
vdir:
	$(FINDER) . &
edit:
	exec $(EMACS) *.tex &
edit-console:
	$(EMACS) -nw $(MAIN).tex


## Git
update-gitignore:
    # (1) Rename .gitignore to .gitignore.orig
	@if [ -f .gitignore ]; then ;\
	    cp .gitignore .gitignore.orig  ;\
    else ;\
	    echo  "$(MAIN).pdf" > .gitignore.orig ;\
	    echo  "$(MY-UNIQ-FILENAME).pdf" >> .gitignore.orig ;\
	    echo  ".gitignore.orig" >> .gitignore.orig ;\
	fi
    # (2) Remove figure entries from gitignore
	@grep -v $(addprefix -e ,$(SRC-FIGURE-DIRS:=/)) -e '# make:' .gitignore.orig | sort | uniq > .gitignore || true
    # (3) Emit generateable figures
	@ruby -e "puts '# make: generateable files'; puts %w{$(DST-FIG)}" >> .gitignore

# print-ignore-figs:
# 	@ruby -e "puts %w{$(FIG)}"

## Remove temporary files
# Clean files exclude generated figure files
clean:
	rm -f $(addprefix $(MAIN),.log .toc .dvi .ps .pdf .lof .lot .idx .ilg .ind .bbl .blg .tar.bz2 .zip)
	rm -f $(DVISRC-TEX:%.tex=%.aux)
	rm -f $(MY-UNIQ-FILENAME).pdf jbibtex.log platex.log

# Clean all generated files
distclean: clean
	rm -f $(DST-FIG)
	-@for F in $(MY-MAKEFILES) ; do \
		echo "\tCLEAN $$F" ;\
		make --no-print-directory -C $$(dirname $$F) -f $$(basename $$F) clean ;\
	done

distclean-rec:
	@for F in *                                     ;\
	do                                               \
		if [ -d "$$F" -a -f "$$F/Makefile" ]        ;\
		then                                         \
			echo -e "CLEAN \t$$F"  ;\
			make -sC "$$F" distclean clean-rec      ;\
		fi                                           \
	done

## Backup commands
archive: clean
	$(eval TEMP := $(shell mktemp /tmp/tmp.XXXXXXXXXX))
	tar -cjC $(dir $(PWD)) -f $(TEMP) $(shell basename $(PWD))
	mv $(TEMP) $(MAIN)-v$(MY-VERSION).tar.bz2

archive-git:
	git archive --prefix="$(MAIN)-v$(MY-VERSION)/" --format=zip master > $(MAIN)-v$(MY-VERSION).zip

PHONY += prepare
PHONY += dvi pdf rename alternative-pdf figures
PHONY += vdvi vpdf view vfig vdir
PHONY += edit edit-console
PHONY += clean distclean clean-rec
PHONY += backup restore archive tar

.PHONY: $(PHONY)