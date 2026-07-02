#!/usr/bin/env bash
set -euo pipefail

GOALFLOW_ROOT_DEFAULT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export NAVSIM_DEVKIT_ROOT="${GOALFLOW_ROOT:-$GOALFLOW_ROOT_DEFAULT}"
export NAVSIM_EXP_ROOT="${GOALFLOW_EXP_ROOT:-${NAVSIM_DEVKIT_ROOT}/exp}"
CLUSTER_DEPS="${GOALFLOW_CLUSTER_DEPS:-${NAVSIM_DEVKIT_ROOT}/.cluster_python_deps}"
if [[ -d "$CLUSTER_DEPS" ]]; then
  export PYTHONPATH="${NAVSIM_DEVKIT_ROOT}:${CLUSTER_DEPS}${PYTHONPATH+:$PYTHONPATH}"
else
  export PYTHONPATH="${NAVSIM_DEVKIT_ROOT}${PYTHONPATH+:$PYTHONPATH}"
fi

DATA_ROOT_DEFAULT="/mnt/cfs-baidu/public/guanglei.zhao/goalflow/0630"
DATA_ROOT="${GOALFLOW_DATA_ROOT:-$DATA_ROOT_DEFAULT}"

export OPENSCENE_DATA_ROOT="${OPENSCENE_DATA_ROOT:-${DATA_ROOT}/download/openscene-v1.1}"
export NUPLAN_MAPS_ROOT="${NUPLAN_MAPS_ROOT:-${DATA_ROOT}/download/maps}"
export NUPLAN_MAP_VERSION="${NUPLAN_MAP_VERSION:-nuplan-maps-v1.0}"

PYTHON_BIN="${PYTHON_BIN:-/opt/conda/envs/navsim/bin/python}"
CACHE_PATH="${CACHE_PATH:-${DATA_ROOT}/exp/training_cache_trainval}"
V99_PRETRAINED_PATH="${V99_PRETRAINED_PATH:-${DATA_ROOT}/data/depth_pretrained_v99-3jlw0p36-20210423_010520-model_final-remapped.pth}"
CHECKPOINT_PATH="${CHECKPOINT_PATH:-${DATA_ROOT}/data/goalflow_traj_epoch_54-step_18260.ckpt}"
VOC_PATH="${VOC_PATH:-${DATA_ROOT}/data/cluster_points_8192_.npy}"
export HYDRA_FULL_ERROR="${HYDRA_FULL_ERROR:-1}"

DEVICES="${DEVICES:-8}"
NUM_NODES="${NUM_NODES:-1}"
MAX_EPOCHS="${MAX_EPOCHS:-100}"
BATCH_SIZE="${BATCH_SIZE:-2}"
NUM_WORKERS="${NUM_WORKERS:-8}"
EXPERIMENT_NAME="${EXPERIMENT_NAME:-a_train_traj_ddp_clean}"
GOALFLOW_PRECHECK="${GOALFLOW_PRECHECK:-1}"

cd "$NAVSIM_DEVKIT_ROOT"

if [[ "$GOALFLOW_PRECHECK" == "1" ]]; then
  "$PYTHON_BIN" - <<'PY'
import importlib
mods = [
    "cv2",
    "nuplan",
    "timm",
    "scipy",
    "shapely",
    "matplotlib",
    "vovnet.vovnet",
    "navsim.agents.goalflow.goalflow_agent_traj",
]
for name in mods:
    module = importlib.import_module(name)
    print(f"precheck import OK: {name} -> {getattr(module, '__file__', '')}", flush=True)
PY
fi

"$PYTHON_BIN" navsim/planning/script/run_training.py \
agent=goalflow_agent_traj \
experiment_name="$EXPERIMENT_NAME" \
scene_filter=navtrain \
split=trainval \
cache_path="$CACHE_PATH" \
use_cache_without_dataset=True \
trainer.params.max_epochs="$MAX_EPOCHS" \
trainer.params.num_nodes="$NUM_NODES" \
+trainer.params.devices="$DEVICES" \
dataloader.params.batch_size="$BATCH_SIZE" \
dataloader.params.num_workers="$NUM_WORKERS" \
agent.config.training=True \
agent.config.has_navi=True \
agent.config.start=True \
agent.config.freeze_perception=True \
agent.config.only_perception=False \
agent.config.train_scale=0.1 \
agent.config.tf_d_model=1024 \
agent.config.trajectory_weight=50.0 \
agent.config.agent_class_weight=0.2 \
agent.config.agent_box_weight=0.05 \
agent.config.bev_semantic_weight=0.2 \
agent.config.agent_loss=True \
agent.config.v99_pretrained_path="$V99_PRETRAINED_PATH" \
agent.checkpoint_path="$CHECKPOINT_PATH" \
agent.config.voc_path="$VOC_PATH"
