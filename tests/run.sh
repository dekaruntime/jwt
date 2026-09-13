#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
root=$PWD
export DEKA_DSC=${DEKA_DSC:-$root/.toolchain/dsc}
deka=${DEKA_BIN:-$root/.toolchain/deka}
[[ "$($DEKA_DSC --version)" == 'dsc [version 0.51.2]' ]]
[[ "$($deka --version)" == *'deka [version 0.50.0]'* ]]
"$deka" install
"$deka" check index.ds
"$deka" check tests/roundtrip.ds
output=$("$deka" run tests/roundtrip.ds)
printf '%s\n' "$output"
[[ "$output" == ok ]]
# Exercise package-name resolution and returned claims in a separate project.
mkdir -p .toolchain/consumer
python3 - <<'PY'
import json
from pathlib import Path
root = Path.cwd()
consumer = root / '.toolchain/consumer'
manifest = json.loads((root / 'deka.json').read_text())
(consumer / 'deka.json').write_text(json.dumps({
    'name': 'jwt-consumer', 'version': '0.0.0', 'main': 'main.ds',
    'dependencies': manifest['dependencies'],
}, indent=2) + '\n')
source = (root / 'tests/roundtrip.ds').read_text()
source = source.replace('"../index.ds"', '"@deka/jwt"')
source = source.replace('"../boundary.mjs"', '"./boundary.mjs"')
(consumer / 'main.ds').write_text(source)
for source, target in [('boundary.mjs', 'boundary.mjs'), ('tests/log.mjs', 'log.mjs')]:
    (consumer / target).write_text((root / source).read_text())
PY
cd .toolchain/consumer
"$deka" install
"$deka" link "$root"
python3 - <<'PY'
import json
from pathlib import Path
p = Path('deka.json')
manifest = json.loads(p.read_text())
manifest['dependencies']['@deka/jwt'] = '0.4.0'
p.write_text(json.dumps(manifest, indent=2) + '\n')
PY
"$deka" check main.ds
output=$("$deka" run main.ds)
printf '%s\n' "$output"
[[ "$output" == ok ]]
