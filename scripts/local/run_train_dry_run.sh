#!/usr/bin/env bash
set -euo pipefail

GOALFLOW_ROOT_DEFAULT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export NAVSIM_DEVKIT_ROOT="${GOALFLOW_ROOT:-$GOALFLOW_ROOT_DEFAULT}"
export NAVSIM_EXP_ROOT="${GOALFLOW_EXP_ROOT:-${NAVSIM_DEVKIT_ROOT}/exp}"
export PYTHONPATH="${NAVSIM_DEVKIT_ROOT}${PYTHONPATH+:$PYTHONPATH}"

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
BATCH_SIZE="${BATCH_SIZE:-5}"
NUM_WORKERS="${NUM_WORKERS:-1}"

cd "$NAVSIM_DEVKIT_ROOT"

"$PYTHON_BIN" navsim/planning/script/run_training.py \
agent=goalflow_agent_traj \
experiment_name=debug_train_traj_clean \
scene_filter=navtrain \
split=trainval \
cache_path="$CACHE_PATH" \
use_cache_without_dataset=True \
trainer.params.fast_dev_run=True \
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
