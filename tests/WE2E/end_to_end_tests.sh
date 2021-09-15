#!/bin/bash -l

#----------------------------------------------------------------------
#  Automation of UFS Short Range Weather App Worfklow End to End Tests.
#
#  The script is dependant on a successful build of this repo using the
#  test/build.sh script in the ufs-srweather-app repository.
#  The UFS build must be completed in a particular manner for this 
#  script to function properly, notably the location of the build and
#  bin directories: 
#    BUILD_DIR=${APP_DIR}/build_${compiler}
#    BIN_DIR=${APP_DIR}/bin_${compiler}
#
#  With the creating of a test_log directory and output files describing
#  the result of each workflow status, a testing framework is established.
#  The user must verify the contents of each experiment file in test_log/ 
#  to check workflow success or failure.
#
#  Example: ./end_to_end_tests.sh hera zrtrr
#----------------------------------------------------------------------

#-----------------------------------------------------------------------
#  Set variables
#-----------------------------------------------------------------------

branches=( rrfs_ci )

function usage {
  echo
  echo "Usage: $0 machine slurm_account  | -h"
  echo
  echo "       machine       [required] is one of: ${machines[@]}"
  echo "       slurm_account [required] case sensitive name of the user-specific slurm account"
  echo "       -h            display this help"
  echo
  exit 1

}

machines=( hera )

if [ "$1" = "-h" ] ; then usage ; fi
[[ $# -le 1 ]] && usage

export machine=$1
machine=$(echo "${machine}" | tr '[A-Z]' '[a-z]')  # scripts in sorc need lower case machine name

export account=$2

#-----------------------------------------------------------------------
# Choose experiment.
#-----------------------------------------------------------------------

expts=( grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GSD_SAR )

#-----------------------------------------------------------------------
# Set directories
#-----------------------------------------------------------------------

scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )

TESTS_DIR=$( dirname "${scrfunc_dir}" )
REGIONAL_WORKFLOW_DIR=$( dirname "${TESTS_DIR}" )
SRW_APP_DIR=$( dirname "${REGIONAL_WORKFLOW_DIR}" )
TOP_DIR=$( dirname "${SRW_APP_DIR}" )

#BRANCH_DIR_NAME=ufs-srweather-app-${branches}
APP_DIR=${TOP_DIR}/ufs-srweather-app
EXPTS_DIR=${TOP_DIR}/expt_dirs

#----------------------------------------------------------------------
# Temporary fix to set EXECDIR in setup.sh appropriately.
#----------------------------------------------------------------------

sed -i 's|EXECDIR="${SR_WX_APP_TOP_DIR}/bin"|EXECDIR="${SR_WX_APP_TOP_DIR}/bin_intel/bin"|g' "${REGIONAL_WORKFLOW_DIR}/ush/setup.sh"

#-----------------------------------------------------------------------
# Run E2E Tests
#-----------------------------------------------------------------------

# Load Python Modules
cmd="${APP_DIR}/env/wflow_${machine}.env"
source ${cmd}

echo "-- Load environment =>"  $cmd

# If experiments list file exists, remove it, and add the experiemnts to a new expts list file
auto_file="auto_expts_list.txt"

rm -rf ${auto_file}
echo ${expts} > ${auto_file}

# Run the E2E Workflow tests
./run_WE2E_tests.sh tests_file=${auto_file} machine=${machine} account=${account}

