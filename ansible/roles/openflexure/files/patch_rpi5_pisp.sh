#!/usr/bin/env bash
set -euo pipefail

SRC="src/openflexure_microscope_server/things/camera"

patched=0

# Patch 1: picamera_tuning_file_utils.py - return empty dict on Pi 5
TF="${SRC}/picamera_tuning_file_utils.py"
if grep -q '# Note the vc4 here' "$TF" 2>/dev/null; then
  python3 -c "
import sys
with open('$TF') as f:
    c = f.read()
c = c.replace(
    '    fname = f\"{sensor_model}.json\"\n    # Note the vc4 here. This locks us to Pi4. We will need to update this to support\n    # the Raspberry Pi 5.\n    tuning_path = os.path.join(THIS_DIR, \"tuning_files\", \"vc4\", fname)\n\n    try:\n        with open(tuning_path, \"r\", encoding=\"utf-8\") as file_obj:\n            return json.load(file_obj)\n    except (json.decoder.JSONDecodeError, IOError) as e:\n        raise TuningFileError(f\"Could not load tuning from {tuning_path}.\") from e',
    '    fname = f\"{sensor_model}.json\"\n    vc4_path = os.path.join(THIS_DIR, \"tuning_files\", \"vc4\", fname)\n    if os.path.isfile(vc4_path):\n        with open(vc4_path, \"r\", encoding=\"utf-8\") as file_obj:\n            tuning = json.load(file_obj)\n        if tuning.get(\"target\") == \"pisp\":\n            return tuning\n    return {}'
)
with open('$TF', 'w') as f:
    f.write(c)
print('Patched tuning utils')
"
  patched=1
fi

# Patch 2: picamera.py - handle empty tuning in __init__
PY="${SRC}/picamera.py"
if grep -q 'try:' "${PY}" && grep -q 'ServerNotRunningError as e:' "${PY}" && grep -q 'Tuning file could not be set' "${PY}"; then
  python3 -c "
import sys
with open('$PY') as f:
    c = f.read()

# 2a: __init__ tuning block
c = c.replace(
    '        # Set tuning to default tuning. This will be overwritten when the Thing is\n        # connected to the server if tuning is saved to disk.\n        try:\n            self.tuning = copy.deepcopy(self.default_tuning)\n        except ServerNotRunningError as e:\n            # This will throw an error after setting as we are not connected to\n            # a server. But we know this, so we ignore the error as long as the\n            # tuning data is set.\n            if \"version\" not in self.tuning:\n                raise RuntimeError(\"Tuning file could not be set.\") from e\n\n        # Also set the colour gains based on the tuning. Set to _colour_gains to not\n        # trigger a ServerNotRunningError\n        self._colour_gains = tf_utils.get_colour_gains_from_lst(self.tuning)',
    '        try:\n            self.tuning = copy.deepcopy(self.default_tuning)\n        except ServerNotRunningError:\n            pass\n        if self.tuning and \"version\" in self.tuning:\n            self._colour_gains = tf_utils.get_colour_gains_from_lst(self.tuning)\n        else:\n            self._colour_gains = (1.0, 1.0)'
)

# 2b: _initialise_picamera tuning block
c = c.replace(
    '        with self._picamera_lock, tempfile.NamedTemporaryFile(\"w\") as tuning_file:\n            json.dump(self.tuning, tuning_file)\n            tuning_file.flush()  # but leave it open as closing it will delete it\n            os.environ[\"LIBCAMERA_RPI_TUNING_FILE\"] = tuning_file.name\n\n            if self._picamera is not None:',
    '        with self._picamera_lock:\n            if self.tuning and \"version\" in self.tuning:\n                _tuning_file = tempfile.NamedTemporaryFile(\"w\")\n                _tuning_file.__enter__()\n                json.dump(self.tuning, _tuning_file)\n                _tuning_file.flush()\n                os.environ[\"LIBCAMERA_RPI_TUNING_FILE\"] = _tuning_file.name\n            else:\n                os.environ.pop(\"LIBCAMERA_RPI_TUNING_FILE\", None)\n                _tuning_file = None\n\n            if self._picamera is not None:'
)

c = c.replace(
    '            # Specify tuning file otherwise it will be overwritten with None.\n            self._picamera = Picamera2(\n                camera_num=self._camera_num,\n                tuning=self.tuning,\n            )',
    '            if self.tuning and \"version\" in self.tuning:\n                self._picamera = Picamera2(\n                    camera_num=self._camera_num,\n                    tuning=self.tuning,\n                )\n            else:\n                self._picamera = Picamera2(\n                    camera_num=self._camera_num,\n                )\n\n            if _tuning_file is not None:\n                _tuning_file.__exit__(None, None, None)'
)

with open('$PY', 'w') as f:
    f.write(c)
print('Patched picamera')
"
  patched=1
fi

if [ "$patched" -eq 1 ]; then
  find /opt/openflexure -name '__pycache__' -type d -exec rm -rf {} + 2>/dev/null || true
  find /opt/openflexure -name '*.pyc' -delete 2>/dev/null || true
  echo "Patched"
else
  echo "Already patched (or upstream fixed)"
fi
