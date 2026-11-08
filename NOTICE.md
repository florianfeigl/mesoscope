# NOTICE

This repository (the **mesoscope** project; instrument model **IDANA**) is
multi-licensed per component type. Licensing is declared machine-readably using
the [REUSE](https://reuse.software/) specification in `REUSE.toml`, and the full
license texts are stored in the `LICENSES/` directory.

## Licensing model

| Component | SPDX identifier | Text |
|---|---|---|
| Hardware design & manufacturing files (`hardware/**`: `.scad`, `.stl`, `.gcode`, `.bgcode`, `.png`) | `CERN-OHL-S-2.0` | `LICENSES/CERN-OHL-S-2.0.txt` |
| Software (Ansible playbooks/roles/templates, shell & Python scripts, CI, repo config) | `GPL-3.0-only` | `LICENSES/GPL-3.0-only.txt` |
| Documentation, thesis and media (`.md`, `.tex`, `.bib`, `.html`, `thesis/**`, `resources/**`) | `CC-BY-4.0` | `LICENSES/CC-BY-4.0.txt` |

Copyright holder: Florian Feigl.

## OpenFlexure attribution and reciprocity

This repository contains hardware designs and source material **derived from the
OpenFlexure project**, which is licensed under the CERN Open Hardware Licence v2 –
Strongly Reciprocal (`CERN-OHL-S-2.0`). The hardware design files above are kept
under `CERN-OHL-S-2.0` to honour that reciprocity.

If you redistribute or modify OpenFlexure-derived Covered Source you must follow
the terms of `CERN-OHL-S-2.0`: retain original Notices, add modification notices,
and ensure the modified Covered Source is licensed under `CERN-OHL-S-2.0` when
Conveyed.

The upstream OpenFlexure clone under `sources/openflexure-microscope/` is
**gitignored**, is not part of this repository's tracked source, and retains its
own upstream license (see `sources/openflexure-microscope/License`).

If you need help determining whether a file in this repository is covered by
`CERN-OHL-S-2.0`, ask before taking action.
