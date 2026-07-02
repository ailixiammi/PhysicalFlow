#!/usr/bin/env bash
set -euo pipefail

ROOT_DEFAULT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ROOT="${GOALFLOW_ROOT:-$ROOT_DEFAULT}"
DDP_SCRIPT="$ROOT/scripts/local/run_goalflow_training_traj_ddp.sh"

if [[ ! -x "$DDP_SCRIPT" ]]; then
  echo "Missing executable DDP script: $DDP_SCRIPT" >&2
  exit 1
fi

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
  if [[ -n "${RANK:-}" && -n "${DEVICES:-}" ]]; then echo $((RANK / DEVICES)); return; fi
  return 1
}

detect_master_addr() {
  if [[ -n "${MASTER_ADDR:-}" ]]; then echo "$MASTER_ADDR"; return; fi
  if [[ -n "${CHIEF_IP:-}" ]]; then echo "$CHIEF_IP"; return; fi
  if [[ -n "${MASTER_IP:-}" ]]; then echo "$MASTER_IP"; return; fi
  if [[ -n "${VC_WORKER_HOSTS:-}" ]]; then echo "$VC_WORKER_HOSTS" | tr ',' '\n' | head -n 1; return; fi
  if [[ -n "${WORKER_HOSTS:-}" ]]; then echo "$WORKER_HOSTS" | tr ',' '\n' | head -n 1; return; fi
  if [[ -n "${HOSTFILE:-}" && -f "$HOSTFILE" ]]; then head -n 1 "$HOSTFILE"; return; fi
  if [[ -n "${PBS_NODEFILE:-}" && -f "$PBS_NODEFILE" ]]; then head -n 1 "$PBS_NODEFILE"; return; fi
  if [[ -n "${SLURM_JOB_NODELIST:-}" ]] && command -v scontrol >/dev/null 2>&1; then
    scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1
    return
  fi
  if [[ "${HOSTNAME:-}" =~ ^(.+)-[0-9]+$ ]]; then echo "${BASH_REMATCH[1]}-0"; return; fi
  return 1
}

export DEVICES="${DEVICES:-8}"
export NUM_NODES="${NUM_NODES:-4}"
export MASTER_PORT="${MASTER_PORT:-29500}"
export NCCL_DEBUG="${NCCL_DEBUG:-INFO}"
export NCCL_DEBUG_SUBSYS="${NCCL_DEBUG_SUBSYS:-INIT,NET}"
export NCCL_ASYNC_ERROR_HANDLING="${NCCL_ASYNC_ERROR_HANDLING:-1}"
export NCCL_NET="${NCCL_NET:-Socket}"
export NCCL_IB_DISABLE="${NCCL_IB_DISABLE:-1}"
export NCCL_SOCKET_IFNAME="${NCCL_SOCKET_IFNAME:-eth0}"

if ! export NODE_RANK="$(detect_node_rank)"; then
  echo "Cannot detect NODE_RANK." >&2
  echo "Set NODE_RANK to 0, 1, 2, or 3, or tell me the cluster platform's node-rank env var." >&2
  env | sort | grep -E 'RANK|NODE|HOST|SLURM|OMPI|VC_|POD|MASTER|CHIEF' >&2 || true
  exit 2
fi

if ! export MASTER_ADDR="$(detect_master_addr)"; then
  echo "Cannot detect MASTER_ADDR." >&2
  echo "Set MASTER_ADDR to the IP/hostname of node rank 0, or tell me the cluster platform's hostfile/master env var." >&2
  env | sort | grep -E 'RANK|NODE|HOST|SLURM|OMPI|VC_|POD|MASTER|CHIEF' >&2 || true
  exit 3
fi

echo "GoalFlow cluster launch:"
echo "  root        = $ROOT"
echo "  hostname    = ${HOSTNAME:-unknown}"
echo "  master      = $MASTER_ADDR:$MASTER_PORT"
echo "  node_rank   = $NODE_RANK"
echo "  num_nodes   = $NUM_NODES"
echo "  devices     = $DEVICES"
echo "  batch_size  = ${BATCH_SIZE:-2}"
echo "  num_workers = ${NUM_WORKERS:-4}"
echo "  max_epochs  = ${MAX_EPOCHS:-100}"
echo "  nccl_ifname = $NCCL_SOCKET_IFNAME"
echo "  nccl_net    = $NCCL_NET"
echo "  nccl_ib     = $NCCL_IB_DISABLE"

exec "$DDP_SCRIPT"
