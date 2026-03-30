# CELLAIR Elevator Pitch — Build
# Requires: pdflatex, mhchem, siunitx, tikz, booktabs, beamer

MAIN = main
LATEX = pdflatex
FLAGS = -interaction=nonstopmode -halt-on-error

.PHONY: all clean watch

all: $(MAIN).pdf

$(MAIN).pdf: $(MAIN).tex
	$(LATEX) $(FLAGS) $(MAIN).tex
	$(LATEX) $(FLAGS) $(MAIN).tex

clean:
	rm -f $(MAIN).{pdf,aux,log,nav,out,snm,toc,vrb}

watch:
	@echo "Watching for changes... (Ctrl+C to stop)"
	@while true; do \
		inotifywait -q -e modify $(MAIN).tex 2>/dev/null || sleep 2; \
		$(MAKE) all; \
	done
