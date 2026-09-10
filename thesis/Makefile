## Mesoscope master's thesis — build
## Uses pdflatex + bibtex (biber is not required; IEEEtran uses bibtex).

MAIN    := main
LATEX   := pdflatex
LFLAGS  := -interaction=nonstopmode -halt-on-error
BIBTEX  := bibtex

.PHONY: all clean distclean watch

all: $(MAIN).pdf

$(MAIN).pdf: $(MAIN).tex references.bib $(wildcard sections/*.tex)
	$(LATEX) $(LFLAGS) $(MAIN)
	-$(BIBTEX) $(MAIN)
	$(LATEX) $(LFLAGS) $(MAIN)
	$(LATEX) $(LFLAGS) $(MAIN)

## Convenience target if latexmk is preferred.
watch:
	latexmk -pdf -pvc -interaction=nonstopmode $(MAIN)

clean:
	rm -f $(MAIN).aux $(MAIN).bbl $(MAIN).blg $(MAIN).log \
	      $(MAIN).out $(MAIN).toc $(MAIN).lof $(MAIN).lot \
	      $(MAIN).fls $(MAIN).fdb_latexmk sections/*.aux

distclean: clean
	rm -f $(MAIN).pdf
