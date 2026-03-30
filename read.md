# OpenFlexure Mikroskopie-System — Projektübersicht

Kostengünstiges, portables Mikroskopie-System mit KI-gestützter Echtzeit-Analyse für biologische Proben, auf Basis vollständig offener Hard- und Software. Reproduzierbar, erweiterbar, einsetzbar in Forschung und Lehre.

---

## Hardware-Komponenten

### Raspberry Pi 5

| Eigenschaft | Wert |
|---|---|
| Prozessor | ARM Cortex-A76, 4× 2,4 GHz |
| RAM | 4 / 8 GB LPDDR4X |
| Schnittstellen | USB 3, PCIe, CSI |
| Leistung | bis 5 W (idle) |
| Betriebssystem | Raspberry Pi OS |
| **Rolle im System** | Steuerrechner & Host |

### Raspberry Pi AI HAT+

| Eigenschaft | Wert |
|---|---|
| Chip | Hailo-8L NPU |
| Leistung | 26–27 TOPS |
| Anschluss | PCIe (M.2 HAT) |
| Inferenz | Echtzeit, low power |
| Einsatz | Objekterkennung, Segmentierung |
| **Rolle im System** | KI-Beschleuniger |

### Raspberry Pi HQ Camera

| Eigenschaft | Wert |
|---|---|
| Sensor | Sony IMX477, 12 MP |
| Pixelgröße | 1,55 µm |
| Optik | C/CS-Mount, wechselbar |
| Anschluss | CSI-2 (15-pin) |
| Sensordiagonale | 7,9 mm |
| **Rolle im System** | Bildaufnahme |

---

## OpenFlexure-Integration

Das System basiert auf dem [OpenFlexure-Projekt](https://openflexure.org) — einer open-source Mikroskopplattform mit 3D-gedruckter Mechanik und Python-basierter Steuersoftware.

### Mechanik

- XYZ-Bühne mit Schrittmotoren, sub-µm Schrittauflösung
- 3D-gedruckte Struktur (PLA / PETG), kompakt und portabel
- Objektivhalter mit RMS-Gewinde
- Konfigurierbare LED-Beleuchtung
- **Anpassung:** Probenhalter für Bioreaktor-Proben

### Software

- Steuerung via OpenFlexure Server (Python, REST-API / JSON)
- Kamera-Integration über Picamera2
- Web-UI und Skript-Steuerung
- Lizenz: Open Source (CERN-OHL)
- **Anpassung:** Plugin-Erweiterungen für automatisierte Serienaufnahmen

### KI-Analyse

- Modell: YOLOv8, angepasst auf Zellsegmentierung
- Inferenz auf Hailo-8L NPU (< 30 ms Latenz)
- Training extern / Cloud, Deployment als `.hef`-Datei
- Ausgabe: annotierte Bilder, CSV / JSON, Statistiken
- **Anpassung:** Fine-Tuning auf eigenen Zell-Datensatz

---

## Analyse-Workflow

```
Probe einlegen → HQ Camera → RPi 5 → AI HAT+ → Ergebnis
```

| Schritt | Komponente | Details |
|---|---|---|
| 1 — Probe | OpenFlexure-Bühne | XYZ-Positionierung, Fokussierung, LED-Beleuchtung |
| 2 — Aufnahme | HQ Camera | Sony IMX477, RAW / JPEG, CSI-2 |
| 3 — Vorverarbeitung | Raspberry Pi 5 | Picamera2, Bildnormalisierung, OpenFlexure Server |
| 4 — Inferenz | AI HAT+ | Hailo-8L, YOLOv8, Zellsegmentierung, < 30 ms |
| 5 — Export | Web-UI / API | Annotierte Bilder, CSV, JSON, Statistiken |

---

## Experimentelle Roadmap

### Phase 1 — Bioreaktor-Besiedelung (Woche 1–2)

- [ ] Zellkultur vorbereiten
- [ ] Bioreaktor sterilisieren
- [ ] Besiedelung durchführen
- [ ] Wachstum überwachen
- [ ] Parameter protokollieren

**Meilenstein:** Konfluente Zellschicht im Reaktor erreicht

---

### Phase 2 — Mikroskopie & Datensatz (Woche 2–4)

- [ ] OpenFlexure aufsetzen und kalibrieren
- [ ] HQ Camera kalibrieren
- [ ] Bildaufnahme-Skripte entwickeln
- [ ] Automatisierte Serienaufnahmen (Zeitreihe)
- [ ] Qualitätssicherung der Aufnahmen

**Meilenstein:** > 500 annotierbare Aufnahmen vorhanden

---

### Phase 3 — Annotation & YOLO-Training (Woche 4–6)

- [ ] Bilder annotieren (z. B. CVAT)
- [ ] Klassen definieren (Zelltypen, Zustände)
- [ ] YOLOv8 fine-tuning auf eigenem Datensatz
- [ ] Modell evaluieren (mAP)
- [ ] Hailo-Export (`.hef`) via Hailo Model Zoo Toolchain

**Meilenstein:** Modell mAP > 0,75 auf Validierungsset

---

### Phase 4 — Deployment & Validierung (Woche 6–8+)

- [ ] Modell auf AI HAT+ laden
- [ ] Echtzeit-Inferenz am System testen
- [ ] Latenz & Genauigkeit messen
- [ ] Biologische Validierung der Ergebnisse
- [ ] Dokumentation & ggf. Publikationsvorbereitung

**Meilenstein:** Live-Demo am System, Ergebnisse publizierbar

---

### Durchgehende Aktivitäten

- Laborprotokoll & Versionierung (alle Phasen)
- Datensicherung & Backup-Strategie (alle Phasen)

---

## Abhängigkeiten & Risiken

| Risiko | Beschreibung | Maßnahme |
|---|---|---|
| Besiedelung schlägt fehl | Phase 2–4 verzögern sich | Puffer in Zeitplan einplanen |
| Datensatz zu klein | Schlechte Modellgeneralisierung | Semi-Automation via SAM2 für Annotation |
| Hailo-Toolchain | `.hef`-Export komplex | Frühzeitig aufsetzen, nicht erst in Phase 4 |
| Fokus-Drift | Unschärfe in Zeitreihen | Autofokus-Skript via OpenFlexure API |

---

## Lizenz & Referenzen

- [OpenFlexure Project](https://openflexure.org) — CERN-OHL
- [Hailo Model Zoo](https://github.com/hailo-ai/hailo_model_zoo)
- [YOLOv8 (Ultralytics)](https://github.com/ultralytics/ultralytics)
- [CVAT Annotierungstool](https://github.com/opencv/cvat)
