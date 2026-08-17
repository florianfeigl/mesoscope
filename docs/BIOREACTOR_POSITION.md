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

## Kamera-Einstellungen (Stand: 2026-08-17, nach Service-Restart)

| Einstellung    | Wert             |
|----------------|------------------|
| ExposureTime   | 397 µs           |
| AnalogueGain   | 1.0              |
| ColourGains    | [1.4, 2.3]       |

Diese Werte sind nach dem Service-Restart aktiv und sehen gut aus.

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
