# CELLAIR / Mesoscope — Parts Order List

## Priority: Urgent — Custom optics required

**Project:** OpenFlexure-based live-cell microscopy for bioreactor (hFOB 1.19 + hMEC 1 cell interaction)

> **Note (2026-04):** The IMX500 (AI Camera) is not part of this build. The Pi HQ Camera (IMX477) is the sole imaging camera.
> The Pi HQ Camera (IMX477) with C-mount is now the primary imaging camera.
> The AI HAT+ (Hailo-8) remains for real-time inference via HEF models.

---

## FROM TAULAB (https://taulab.eu/3-openflexure)

| Qty | Item | Description | Price |
|---|---|---|---|
| 1 | Sangaboard v5 | Motor controller board | £28 |
| 1 | OFMv7 Illumination Kit | LED, cable, diffuser, lens | £10 |
| 1 | OFMv7 Bag of Bits | M3 nuts, washers, screws, O-rings, oil | £24 |
| 3 | Geared Stepper Motor (28BYJ-48) | Unipolar stepper motors | £10.50 |

**Subtotal: ~£72.50**

---

## OPTICAL COMPONENTS (from your distributor)

> **CRITICAL: Standard 50mm tube lens will NOT work**
> See `hardware/optics/OPTICS_MODULE.md` for full calculation.

| Qty | Item | Spec | Notes |
|---|---|---|---|
| **1** | **Tube lens** | Achromat doublet, 12.7mm diameter, **125-150mm focal length** | IMX477 sensor is 2.1× larger than Pi Cam v2. Ordered from taulab. |
| 1 | Condenser lens | PMMA, 13mm, ~5mm focal | Standard, optional |

**Recommended:** ThorLabs AC127-150-A (150mm) for ≤10x objective, or AC127-125-A (125mm) for ≤4x.

---

## ELECTRONICS

| Qty | Item | Notes |
|---|---|---|
| 1 | 200mm Pi Camera ribbon cable | Already have - shipped with HQ Camera |
| 2 | DuPont 1x2 pin connector housings | |
| 2 | Jumper cables F-F 30cm (red + black) | |

---

## ALREADY HAVE

- Raspberry Pi 5 (8GB)
- AI HAT+ (Hailo-8, 27 TOPS) — for inference only, not camera
- HQ Camera (IMX477, C-mount) — primary microscope camera
- DS3231 RTC Module
- GPIO Stacking Header
- Micro SD card
- Power Supply (USB-C, 27W)
- 3× 28BYJ-48 stepper motors (acquired separately)
- 3× 28BYJ-48 stepper motors (acquired separately)
