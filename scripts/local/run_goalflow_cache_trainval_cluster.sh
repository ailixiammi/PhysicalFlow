#!/usr/bin/env bash
set -euo pipefail

ROOT_DEFAULT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROOT="${GOALFLOW_ROOT:-$ROOT_DEFAULT}"

detect_node_rank() {
  if [[ -n "${NODE_RANK:-}" ]]; then echo "$NODE_RANK"; return; fi
  if [[ -n "${GROUP_RANK:-}" ]]; then echo "$GROUP_RANK"; return; fi
  if [[ -n "${SLURM_NODEID:-}" ]]; then echo "$SLURM_NODEID"; return; fi
  if [[ -n "${OMPI_COMM_WORLD_RANK:-}" ]]; then echo "$OMPI_COMM_WORLD_RANK"; return; fi
  if [[ "${HOSTNAME:-}" =~ -master-([0-9]+)$ ]]; then echo "${BASH_REMATCH[1]}"; return; fi
  if [[ "${HOSTNAME:-}" =~ -worker-([0-9]+)$ ]]; then echo $((BASH_REMATCH[1] + 1)); return; fi
  if [[ -n "${POD_INDEX:-}" ]]; then echo "$POD_INDEX"; return; fi
  if [[ -n "${VC_TASK_INDEX:-}" ]]; then echo "$VC_TASK_INDEX"; return; fi
  if [[ "${HOSTNAME:-}" =~ -([0-9]+)$ ]]; then echo "${BASH_REMATCH[1]}"; return; fi
  return 1
}

export NODE_RANK="${NODE_RANK:-$(detect_node_rank)}"
export NUM_NODES="${NUM_NODES:-1}"
export PYTHON_BIN="${PYTHON_BIN:-/opt/conda/envs/navsim/bin/python}"

DATA_ROOT_DEFAULT="/mnt/cfs-baidu/public/guanglei.zhao/goalflow/0630"
DATA_ROOT="${GOALFLOW_DATA_ROOT:-$DATA_ROOT_DEFAULT}"

export NAVSIM_DEVKIT_ROOT="${NAVSIM_DEVKIT_ROOT:-$ROOT}"
export NAVSIM_EXP_ROOT="${GOALFLOW_EXP_ROOT:-${DATA_ROOT}/exp}"
export OPENSCENE_DATA_ROOT="${OPENSCENE_DATA_ROOT:-${DATA_ROOT}/download/openscene-v1.1}"
export NUPLAN_MAPS_ROOT="${NUPLAN_MAPS_ROOT:-${DATA_ROOT}/download/maps}"
export NUPLAN_MAP_VERSION="${NUPLAN_MAP_VERSION:-nuplan-maps-v1.0}"
export HYDRA_FULL_ERROR="${HYDRA_FULL_ERROR:-1}"
export GOALFLOW_SKIP_CACHE_FILE_NOT_FOUND="${GOALFLOW_SKIP_CACHE_FILE_NOT_FOUND:-1}"

CLUSTER_DEPS="${GOALFLOW_CLUSTER_DEPS:-${NAVSIM_DEVKIT_ROOT}/.cluster_python_deps}"
if [[ -d "$CLUSTER_DEPS" ]]; then
  export PYTHONPATH="${NAVSIM_DEVKIT_ROOT}:${CLUSTER_DEPS}${PYTHONPATH+:$PYTHONPATH}"
else
  export PYTHONPATH="${NAVSIM_DEVKIT_ROOT}${PYTHONPATH+:$PYTHONPATH}"
fi

CACHE_PATH="${CACHE_PATH:-${DATA_ROOT}/exp/training_cache_trainval_full}"
export GOALFLOW_CACHE_SKIP_LOG="${GOALFLOW_CACHE_SKIP_LOG:-${CACHE_PATH}/_cache_logs/skipped_file_not_found_rank_${NODE_RANK}.log}"
EXPERIMENT_NAME="${EXPERIMENT_NAME:-cache_full_goalflow_trainval}"
THREADS_PER_NODE="${THREADS_PER_NODE:-${CPU_NUM:-64}}"
FORCE_CACHE_COMPUTATION="${FORCE_CACHE_COMPUTATION:-false}"
SCENE_FILTER="${SCENE_FILTER:-navtrain}"
SPLIT="${SPLIT:-trainval}"
WORKER="${WORKER:-ray_distributed_no_torch}"
DRY_RUN="${DRY_RUN:-0}"
EXCLUDE_LOGS_FILE="${EXCLUDE_LOGS_FILE:-}"

cd "$NAVSIM_DEVKIT_ROOT"

SHARD_LOG_NAMES="$($PYTHON_BIN - <<'PY'
import os
from pathlib import Path
import sys
import yaml

rank = int(os.environ["NODE_RANK"])
world = int(os.environ["NUM_NODES"])
scene_filter = os.environ.get("SCENE_FILTER", "navtrain")
exclude_logs_file = os.environ.get("EXCLUDE_LOGS_FILE", "")
cfg_path = Path("navsim/planning/script/config/common/scene_filter") / f"{scene_filter}.yaml"
data = yaml.safe_load(cfg_path.read_text())
logs = data.get("log_names")
if not logs:
    raise RuntimeError(f"scene_filter={scene_filter} has no explicit log_names; cannot shard safely")

excluded = set()
if exclude_logs_file:
    for line in Path(exclude_logs_file).read_text().splitlines():
        item = line.strip()
        if not item:
            continue
        excluded.add(Path(item).name)
    logs = [log for log in logs if log not in excluded]

shard = [log for idx, log in enumerate(logs) if idx % world == rank]
print("[" + ",".join(shard) + "]")
print(
    f"cache shard: rank={rank} world={world} total_logs_after_exclude={len(logs)} "
    f"excluded_logs={len(excluded)} shard_logs={len(shard)}",
    file=sys.stderr,
    flush=True,
)
PY
)"

echo "GoalFlow cache cluster launch:"
echo "  root          = $NAVSIM_DEVKIT_ROOT"
echo "  hostname      = ${HOSTNAME:-unknown}"
echo "  node_rank     = $NODE_RANK"
echo "  num_nodes     = $NUM_NODES"
echo "  python        = $PYTHON_BIN"
echo "  data_root     = $DATA_ROOT"
echo "  openscene     = $OPENSCENE_DATA_ROOT"
echo "  maps          = $NUPLAN_MAPS_ROOT"
echo "  cache_path    = $CACHE_PATH"
echo "  scene_filter  = $SCENE_FILTER"
echo "  split         = $SPLIT"
echo "  worker        = $WORKER"
echo "  threads/node  = $THREADS_PER_NODE"
echo "  force_cache   = $FORCE_CACHE_COMPUTATION"
echo "  exclude_file  = ${EXCLUDE_LOGS_FILE:-none}"
echo "  dry_run       = $DRY_RUN"

if [[ "$DRY_RUN" == "1" ]]; then
  echo "DRY_RUN=1; not starting cache job."
  exit 0
fi

exec "$PYTHON_BIN" navsim/planning/script/run_dataset_caching.py \
  agent=goalflow_agent_traj \
  experiment_name="$EXPERIMENT_NAME" \
  cache_path="$CACHE_PATH" \
  scene_filter="$SCENE_FILTER" \
  split="$SPLIT" \
  scene_filter.log_names="$SHARD_LOG_NAMES" \
  worker="$WORKER" \
  worker.threads_per_node="$THREADS_PER_NODE" \
  force_cache_computation="$FORCE_CACHE_COMPUTATION"
