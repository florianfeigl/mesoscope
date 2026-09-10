# Mesoscope — Master's Thesis (LaTeX)

IEEEtran journal-class draft of the mesoscope thesis. The scaffold and the
already-known content (introduction, background, requirements, optical,
mechanical, electronics, software, edge-AI, cost) are filled in; results that
depend on future experiments are marked inline as `[TODO: ...]` (red).

## Layout

| Path | Contents |
|------|----------|
| `main.tex` | Preamble, title, abstract, `\input`s all sections, bibliography |
| `sections/01_introduction.tex` … `11_conclusion.tex` | Body chapters |
| `sections/A_appendix.tex` | Printed-parts table and wiring appendix |
| `references.bib` | BibTeX entries (OpenFlexure, UC2, Squid, Cellpose, StarDist) |
| `figures/` | Local figures (currently empty) |

Figures are also pulled from `../hardware/assembly/` via `\graphicspath`. The
exploded-view PNGs there are **not committed** — regenerate them first with
`hardware/assembly/build_exploded.sh` (the thesis uses
`exploded_view_nolabels.png`).

## Build

```bash
make            # pdflatex + bibtex + pdflatex x2  ->  main.pdf
make clean      # remove aux files
make distclean  # also remove main.pdf
```

Requires `pdflatex` and `bibtex` (TeX Live; `texlive-publishers` provides
`IEEEtran.cls`/`IEEEtran.bst`). `biber` is **not** needed. `latexmk` is
optional (`make watch`).

## Status

Draft (milestone M0). Open decisions and parameter gaps are flagged as
`[TODO: ...]` and cross-referenced to `docs/THESIS_PARAMETER_GAPS.md` and the
milestones M1–M3.
