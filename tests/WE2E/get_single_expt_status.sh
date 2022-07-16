#!/bin/bash 

#
#-----------------------------------------------------------------------
#
# This script updates and reports back the workflow status of a single
# forecast experiment under a specified base directory (expts_basedir).  
# It must be supplied two arguments, the full path to the
# experiments base directory & the experiment name.  
#
# This script is used to produce exit codes for each WE2E test submitted 
# as a part of Continous Integration Pipeline.
# 
# For the supplied experiment, it calls the workflow (re)launch script to 
# update the status of the workflow and prints the status.
# 
#
#-----------------------------------------------------------------------
#
# Do not allow uninitialized variables.
#
#-----------------------------------------------------------------------
#
set -u
#
#-----------------------------------------------------------------------
#
# Get the full path to the file in which this script/function is located
# (scrfunc_fp), the name of that file (scrfunc_fn), and the directory in
# which the file is located (scrfunc_dir).
#
#-----------------------------------------------------------------------
#
scrfunc_fp=$( readlink -f "${BASH_SOURCE[0]}" )
scrfunc_fn=$( basename "${scrfunc_fp}" )
scrfunc_dir=$( dirname "${scrfunc_fp}" )
#
#-----------------------------------------------------------------------
#
# The current script should be located in the "tests" subdirectory of the
# workflow's top-level directory, which we denote by homerrfs.  Thus,
# homerrfs is the directory one level above the directory in which the
# current script is located.  Set homerrfs accordingly.
#
#-----------------------------------------------------------------------
#
homerrfs=${scrfunc_dir%/*/*}
#
#-----------------------------------------------------------------------
#
# Set directories.
#
#-----------------------------------------------------------------------
#
ushdir="$homerrfs/ush"
#
#-----------------------------------------------------------------------
#
# Source bash utility functions.
#
#-----------------------------------------------------------------------
#
. $ushdir/source_util_funcs.sh
#
#-----------------------------------------------------------------------
#
# Set the usage message.
#
#-----------------------------------------------------------------------
#
usage_str="\
Usage:

  ${scrfunc_fn} \\
    expts_basedir=\"...\" \\
    expt_name=\"...\" \\
    [num_log_lines=\"...\"] \\
    [verbose=\"...\"]

The arguments in brackets are optional.  The arguments are defined as
follows:

expts_basedir:
Full path to the experiments base directory, i.e. the directory containing 
the experiment subdirectories.

expt_name:
Name of the experiment.  

num_log_lines:
Optional integer specifying the number of lines from the end of the 
workflow launch log file (log.launch_FV3LAM_wflow) of each test to 
include in the status report file that this script generates.

verbose:
Optional verbosity flag.  Should be set to \"TRUE\" or \"FALSE\".  Default
is \"FALSE\".
"
#
#-----------------------------------------------------------------------
#
# Check to see if usage help for this script is being requested.  If so,
# print it out and exit with a 0 exit code (success).
#
#-----------------------------------------------------------------------
#
help_flag="--help"
if [ "$#" -eq 1 ] && [ "$1" = "${help_flag}" ]; then
  print_info_msg "${usage_str}"
  exit 0
fi
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names for this script or function.
# Then process the arguments provided to it on the command line (which
# should consist of a set of name-value pairs of the form arg1="value1",
# arg2="value2", etc).
#
#-----------------------------------------------------------------------
#
valid_args=( \
  "expts_basedir" \
  "expt_name"  \
  "num_log_lines" \
  "verbose" \
  )
process_args valid_args "$@"
#
#-----------------------------------------------------------------------
#
# Set the default value of "num_log_lines".
#
#-----------------------------------------------------------------------
#
num_log_lines=${num_log_lines:-"40"}
#
#-----------------------------------------------------------------------
#
# Make the default value of "verbose" "FALSE".  Then make sure "verbose"
# is set to a valid value.
#
#-----------------------------------------------------------------------
#
verbose=${verbose:-"FALSE"}
check_var_valid_value "verbose" "valid_vals_BOOLEAN"
verbose=$(boolify "$verbose")
#
#-----------------------------------------------------------------------
#
# Verify that the required arguments to this script have been specified.
# If not, print out an error message and exit.
#
#-----------------------------------------------------------------------
#
help_msg="\
Use
  ${scrfunc_fn} ${help_flag}
to get help on how to use this script."

if [ -z "${expts_basedir}" ]; then
  print_err_msg_exit "\
The argument \"expts_basedir\" specifying the base directory containing
the experiment directories was not specified in the call to this script.  \
${help_msg}"
fi

if [ -z "${expt_name}" ]; then
  print_err_msg_exit "\
The argument \"expt_name\" specifying the experiment was not specified 
in the call to this script.  \
${help_msg}"
fi
#
#-----------------------------------------------------------------------
#
# Check that the specified experiments base directory exists and is 
# actually a directory.  If not, print out an error message and exit.
#
#-----------------------------------------------------------------------
#
if [ ! -d "${expts_basedir}" ]; then
  print_err_msg_exit "
The specified experiments base directory (expts_basedir) does not exist 
or is not actually a directory:
  expts_basedir = \"${expts_basedir}\""
fi
#
#-----------------------------------------------------------------------
#
# Loop through the elements of the array expt_subdirs.  For each element
# (i.e. for each active experiment), change location to the experiment 
# directory and call the script launch_FV3LAM_wflow.sh to update the log 
# file log.launch_FV3LAM_wflow.  Then take the last num_log_lines of 
# this log file (along with an appropriate message) and add it to the 
# status report file.
#
#-----------------------------------------------------------------------
#
separator="======================================"
launch_wflow_fn="launch_FV3LAM_wflow.sh"
launch_wflow_log_fn="log.launch_FV3LAM_wflow"

expt_subdir="${expts_basedir}/${expt_name}"
msg="\
$separator
Checking workflow status of experiment \"${expt_name}\" ..."
  print_info_msg "$msg"
#
# Change location to the experiment subdirectory, call the workflow launch
# script to update the workflow launch log file, and capture the output 
# from that call.
#
  cd_vrfy "${expt_subdir}"

wflow_status="none"

while [[ "${wflow_status}" == "Workflow status:  IN PROGRESS" || "${wflow_status}" == "none" ]]; do

  launch_msg=$( "${launch_wflow_fn}" 2>&1 )
  log_tail=$( tail -n ${num_log_lines} "${launch_wflow_log_fn}" )

  # The "tail -1" is to get only the last occurrence of "Workflow status"
  wflow_status=$( printf "${log_tail}" | grep "Workflow status:" | tail -1 )
  # Remove leading spaces.
  wflow_status=$( printf "${wflow_status}" "%s" | sed -r 's|^[ ]*||g' )
  print_info_msg "${wflow_status}"

  if [ "${wflow_status}" == "Workflow status:  FAILURE" ]; then 
    print_info_msg "Workflow failed, exiting "
    print_info_msg $separator
    exit 1 
    break

  elif [ "${wflow_status}" == "Workflow status:  SUCCESS" ]; then 
    print_info_msg "Workflow successful, exiting "
    print_info_msg $separator
    exit 0 
    break

  else
    print_info_msg "Waiting 2 minutes, then checking Worfklow Status again"
    sleep 120
  fi

  print_info_msg $separator

done
