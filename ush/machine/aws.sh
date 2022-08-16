#!/bin/bash

function file_location() {

  # Return the default location of external model files on disk

  local external_file_fmt external_model location

  external_model=${1}
  external_file_fmt=${2}

  location=""
  echo ${location:-}

}

EXTRN_MDL_SYSBASEDIR_ICS=${EXTRN_MDL_SYSBASEDIR_ICS:-$(file_location \
  ${EXTRN_MDL_NAME_ICS} \
  ${FV3GFS_FILE_FMT_ICS})}
EXTRN_MDL_SYSBASEDIR_LBCS=${EXTRN_MDL_SYSBASEDIR_LBCS:-$(file_location \
  ${EXTRN_MDL_NAME_LBCS} \
  ${FV3GFS_FILE_FMT_LBCS})}

EXTRN_MDL_DATA_STORES=${EXTRN_MDL_DATA_STORES:-"aws nomads"}

# System scripts to source to initialize various commands within workflow
# scripts (e.g. "module").
if [ -z ${ENV_INIT_SCRIPTS_FPS:-""} ]; then
  ENV_INIT_SCRIPTS_FPS=( /opt/intel/oneapi/setvars.sh /scratch1/apps/lmod/lmod/init/bash )
fi

# Commands to run at the start of each workflow task.
PRE_TASK_CMDS='{ ulimit -s unlimited; ulimit -a; }'

# Architecture information
WORKFLOW_MANAGER="rocoto"
NCORES_PER_NODE=${NCORES_PER_NODE:-36}
SCHED=${SCHED:-"slurm"}
PARTITION_DEFAULT=${PARTITION_DEFAULT:-"compute"}
QUEUE_DEFAULT=${QUEUE_DEFAULT:-"compute"}
PARTITION_HPSS=${PARTITION_HPSS:-"compute"}
QUEUE_HPSS=${QUEUE_HPSS:-"compute"}
PARTITION_FCST=${PARTITION_FCST:-"compute"}
QUEUE_FCST=${QUEUE_FCST:-"compute"}

# UFS SRW App specific paths
staged_data_dir="/scratch1/staged_data_dir"
FIXgsm=${FIXgsm:-"${staged_data_dir}/fix/fix_am"}
FIXaer=${FIXaer:-"${staged_data_dir}/fix/fix_aer"}
FIXlut=${FIXlut:-"${staged_data_dir}/fix/fix_lut"}
TOPO_DIR=${TOPO_DIR:-"${staged_data_dir}/fix/fix_orog"}
SFC_CLIMO_INPUT_DIR=${SFC_CLIMO_INPUT_DIR:-"${staged_data_dir}/fix/fix_sfc_climo"}
DOMAIN_PREGEN_BASEDIR=${DOMAIN_PREGEN_BASEDIR:-"${staged_data_dir}/FV3LAM_pregen"}

# Run commands for executables
RUN_CMD_SERIAL="time"
RUN_CMD_UTILS="srun --mpi=pmi2"
RUN_CMD_FCST='mpirun -np $SLURM_NTASKS'
RUN_CMD_POST="srun --mpi=pmi2"

# Test Data Locations
TEST_COMIN="${staged_data_dir}/COMGFS"
TEST_PREGEN_BASEDIR="${staged_data_dir}/FV3LAM_pregen"
TEST_EXTRN_MDL_SOURCE_BASEDIR="${staged_data_dir}/input_model_data"
TEST_ALT_EXTRN_MDL_SYSBASEDIR_ICS="/scratch2/BMC/det/UFS_SRW_app/dummy_FV3GFS_sys_dir"
TEST_ALT_EXTRN_MDL_SYSBASEDIR_LBCS="/scratch2/BMC/det/UFS_SRW_app/dummy_FV3GFS_sys_dir"
