# Bioreaktor Position

Stage-Position für den Bioreaktor (Stand: 2026-08-17):

```json
{"x": 7984, "y": -8637, "z": 22826}
```

**Zurücksetzen mit:**
```
curl -X POST http://mesoscope.local:5000/stage/move_absolute \
  -H "Content-Type: application/json" \
  -d '{"x": 7984, "y": -8637, "z": 22826}'
```

---

## Kamera-Einstellungen (Stand: 2026-08-24, getestet)

| Einstellung    | Wert             |
|----------------|------------------|
| ExposureTime   | 492 µs           |
| AnalogueGain   | 1.0              |
| ColourGains    | [0.9, 2.9]       |

Iterativ am Live-Bild getunt und als gut bestätigt. Persistiert in
`/var/openflexure/settings/camera/settings.json`, daher nach Neustart aktiv.
Manuelle Werte halten die Auto-Weißabgleich-/Belichtungskalibrierung (AWB/AE)
deaktiviert — nicht den Auto-Kalibrier-/Weißabgleich-Button im Web-UI drücken,
sonst werden die ColourGains wieder auf ~neutral überschrieben (Grünstich).

### Frühere Werte (Stand: 2026-08-17, überholt)

| Einstellung    | Wert             |
|----------------|------------------|
| ExposureTime   | 397 µs           |
| AnalogueGain   | 1.0              |
| ColourGains    | [1.4, 2.3]       |

Waren für die damalige Beleuchtung getunt; bei aktuellem Licht zu hell mit Rotstich.

---

## Auto-Calibration (CSM) — Offenes Problem

Die automatische Kalibrierung (`/camera_stage_mapping/calibrate_xy`) schlägt mit folgendem Fehler fehl:

```
MappingError: Moved the stage by [0. 8192. 0.] but saw no motion.
```

**Ursache (diagnostiziert):**
- Die Bilder aus `capture_downsampled_array` zeigen bei FFT-Korrelation keine detektierbare Verschiebung, auch wenn die Stage-Bewegung im Live-Preview sichtbar ist.
- Bei hoher Belichtung (20000 µs) ist das Bild übersteuert (mean ~228/255) → FFT findet kein Muster.
- Bei normaler Belichtung (397 µs) ist die FFT-Korrelation nicht sensitiv genug für die vorhandenen Bildmerkmale.
- Das 4-Kanal-Format (XBGR8888, Kanal 3 = immer 0) ist kein Primärproblem.
- Die `grab_as_array`-Methode (MJPEG-Stream) zeigt dasselbe Verhalten.

**Nächste Schritte:**
- CSM-Matrix manuell setzen (steps_per_pixel schätzen)
- Oder: `capture_downsampled_array` durch `grab_as_array` im Tracker ersetzen und testen
- Oder: Alternativen Tracking-Algorithmus ("direct" statt "fft") evaluieren
- **Umgesetzt:** `calibration_crop_fraction` auf der `IMX500Camera`-Thing (siehe
  `ansible/roles/openflexure/files/imx500_camera.py`) — schneidet vor dem Downsampling
  in `capture_downsampled_array` auf die mittleren N % des Bildes zu, damit dunkle/vignettierte
  Ecken den FFT-/Direct-Tracker nicht mehr stören (Community-Vermutung: dunkle Ecken senken den
  Kontrast für die Kreuzkorrelation). Betrifft nur den CSM-Tracker, nicht Live-Preview oder
  normale Snapshots (`capture_array`). Aktivieren/Testen:
  ```
  curl -X PUT http://mesoscope.local:5000/camera/calibration_crop_fraction \
    -H "Content-Type: application/json" -d '0.6'
  curl -X POST http://mesoscope.local:5000/camera_stage_mapping/calibrate_xy
  ```
  Nach dem Deploy des neuen `imx500_camera.py` über Ansible testen und Wert ggf. iterativ
  verkleinern (z.B. 0.6 → 0.4), bis die Kalibrierung erfolgreich durchläuft.
