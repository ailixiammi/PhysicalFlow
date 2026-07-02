#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="${ENV_NAME:-goalflow-navsim}"
CONDA_BIN="${CONDA_BIN:-/opt/conda/bin/conda}"
ROOT_DEFAULT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROOT="${GOALFLOW_ROOT:-$ROOT_DEFAULT}"

"$CONDA_BIN" env create -n "$ENV_NAME" -f "$ROOT/envs/goalflow-navsim.yml"
"$CONDA_BIN" run -n "$ENV_NAME" python -m pip check || true

PYTHON_BIN_CREATED="$("$CONDA_BIN" run -n "$ENV_NAME" python -c 'import sys; print(sys.executable)')"
echo "Created conda env: $ENV_NAME"
echo "Use with: PYTHON_BIN=$PYTHON_BIN_CREATED bash scripts/local/run_goalflow_training_traj_cluster.sh"
