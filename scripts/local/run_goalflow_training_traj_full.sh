#!/usr/bin/env bash
set -euo pipefail

export NUM_NODES="${NUM_NODES:-4}"
export DEVICES="${DEVICES:-8}"
export BATCH_SIZE="${BATCH_SIZE:-2}"
export NUM_WORKERS="${NUM_WORKERS:-4}"
export MAX_EPOCHS="${MAX_EPOCHS:-100}"
export EXPERIMENT_NAME="${EXPERIMENT_NAME:-train_traj_full}"
export GOALFLOW_PRECHECK="${GOALFLOW_PRECHECK:-0}"
export FROM_SCRATCH="${FROM_SCRATCH:-0}"
export TRAIN_SCALE="${TRAIN_SCALE:-1.0}"

ROOT_DEFAULT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROOT="${GOALFLOW_ROOT:-$ROOT_DEFAULT}"

exec "$ROOT/scripts/local/run_goalflow_training_traj_cluster.sh"
