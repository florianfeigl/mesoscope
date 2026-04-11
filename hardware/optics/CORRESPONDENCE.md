# OpenFlexure Support Correspondence

## 2026-03-30: HQ Camera optics module (William Wadsworth)

**From:** William Wadsworth <pyswjw@bath.ac.uk> (OpenFlexure team)
**Subject:** RE: Request for DWG Files

### Key Points

1. **Camera type in OpenSCAD:** Use `CAMERA = "picamera_hq"` (NOT `"arducam_b0196"`).
   William corrected this explicitly in his reply.

2. **Camera class in OpenFlexure v3 server config** (verified against `v3` branch source):
   - Class: `openflexure_microscope_server.things.camera.picamera:StreamingPiCamera2`
   - kwarg: `"camera_board": "picamera_hq"` (maps to IMX477 sensor info in `recalibrate_utils`)
   - Stage (Sangaboard): `openflexure_microscope_server.things.stage.sangaboard:SangaboardThing`

3. **Branch:** Use the `hq_camera` branch:
   ```
   git clone https://gitlab.com/openflexure/openflexure-microscope.git
   git checkout hq_camera
   ```

3. **Only two parameters need changing:**
   - `tube_lens_f` — nominal focal length (set to 125 or 150)
   - `tube_lens_ffd` — back focal distance (slightly shorter than f, check datasheet)
   
   Both in `optics_configurations.scad`, function `rms_f50d13_config`.

4. **The tube height and camera Z offset are computed automatically** from these
   parameters — no need to set them manually.

5. **Questions should go to the forum** so solutions are public:
   https://openflexure.discourse.group/

### Forum References
- CAD pipeline: https://openflexure.discourse.group/t/alternative-file-options-other-than-stl-for-block-delta-stages/1438
- HQ Camera / Arducam B0196: https://openflexure.discourse.group/t/arducam-b0196-on-high-resolution-v7-microscope/2393/3

---

## 2026-03-10: Initial contact (Julian Stirling)

**From:** Julian Stirling <julian@julianstirling.co.uk>
**Key points:**
- OpenFlexure uses OpenSCAD (text-based parametric CAD), not AutoCAD/DWG
- v3 server recommended (new picamera stack, FastAPI)
- IMX500 support requires a PISP tuning file
- Pi 5 migration is of interest to the team