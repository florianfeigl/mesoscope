# CELLAIR Mesoscope — Status Update Build
# Follow-up to elevator pitch (01_elevator_pitch)

MAIN = main
LATEX = pdflatex
FLAGS = -interaction=nonstopmode -halt-on-error

.PHONY: all clean watch

all: $(MAIN).pdf

$(MAIN).pdf: $(MAIN).tex
	$(LATEX) $(FLAGS) $(MAIN).tex
	$(LATEX) $(FLAGS) $(MAIN).tex

clean:
	rm -f $(MAIN).{pdf,aux,log,nav,out,snm,toc,vrb,fdb_latexmk,fls,synctex.gz}

watch:
	@echo "Watching for changes... (Ctrl+C to stop)"
	@while true; do \
		inotifywait -q -e modify $(MAIN).tex 2>/dev/null || sleep 2; \
		$(MAKE) all; \
	done
