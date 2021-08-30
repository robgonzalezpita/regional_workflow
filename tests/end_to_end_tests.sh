#!/bin/bash -l

#----------------------------------------------------------------------
#  Automation of UFS Short Range Weather App Worfklow End to End Tests.
#
#  The script is dependant on a successful build of this repo. 
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
#  Example: . end_to_end_tests.sh hera zrtrr
#----------------------------------------------------------------------

#-----------------------------------------------------------------------
#  Set variables
#-----------------------------------------------------------------------

branches=( rrfs_ci ) 

export machine=$1
machine=`echo "${machine}" | tr '[A-Z]' '[a-z]'`  # scripts in sorc need lower case machine name

export account=$2
account=`echo "${account}"`


#-----------------------------------------------------------------------
# Choose experiment. ( Full list in  ./baselines_list.txt)  
#-----------------------------------------------------------------------

#expts=( grid_RRFS_CONUS_25km_ics_HRRR_lbcs_RAP_suite_RRFS_v1alpha )
expts=( grid_RRFS_CONUS_25km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2 )
#expts=( grid_RRFS_CONUS_13km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2 )
#expts=( grid_RRFS_CONUS_13km_ics_HRRR_lbcs_RAP_suite_HRRR )
#expts=( inline_post )
#expts=( grid_RRFS_CONUS_13km_ics_FV3GFS_lbcs_FV3GFS_suite_GFS_v15p2 grid_RRFS_CONUS_25km_ics_HRRR_lbcs_RAP_suite_RRFS_v1alpha )

#-----------------------------------------------------------------------
# Set directories
#-----------------------------------------------------------------------

scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )

REGIONAL_WORKFLOW_DIR=$( dirname "${scrfunc_dir}" )
SRW_APP_DIR=$( dirname "${REGIONAL_WORKFLOW_DIR}" )
TOP_DIR=$( dirname "${SRW_APP_DIR}" )
TESTS_DIR=${REGIONAL_WORKFLOW_DIR}/tests

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
source ${APP_DIR}/env/wflow_${machine}.env
cmd="${APP_DIR}/env/wflow_${machine}.env"

echo "-- Python command =>"  $cmd

# If experiments list file exists, remove it, and add the experiemnts to a new expts list file
if [ -f "auto_expts_list.txt" ] ; then
  rm "auto_expts_list.txt"
fi
echo ${expts} > auto_expts_list.txt

# Run the E2E Workflow tests
#./run_experiments.sh expts_file=auto_expts_list.txt machine=${machine} account=${account} use_cron_to_relaunch=FALSE
./run_experiments.sh expts_file=auto_expts_list.txt machine=${machine} account=${account}

