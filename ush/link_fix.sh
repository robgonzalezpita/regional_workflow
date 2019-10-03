#!/bin/bash

#
#-----------------------------------------------------------------------
#
# Get the name of the current script and the directory in which it is 
# located.  This script should be located in USHDIR, so set USHDIR to 
# the script directory (USHDIR is needed in various places below or in
# sourced scripts).
#
#-----------------------------------------------------------------------
#
script_name=$(basename ${BASH_SOURCE[0]})
script_dir=$(dirname ${BASH_SOURCE[0]})
USHDIR="${script_dir}"
#
#-----------------------------------------------------------------------
#
# Source the function definitions file, which should be in the same di-
# rectory as the current script.  This is needed in order to be able to
# use the process_args() function below.
#
#-----------------------------------------------------------------------
#
. $USHDIR/source_funcs.sh
#
#-----------------------------------------------------------------------
#
# Save current shell options (in a global array).  Then set new options
# for this script/function.
#
#-----------------------------------------------------------------------
#
{ save_shell_opts; set -u +x; } > /dev/null 2>&1
#
#-----------------------------------------------------------------------
#
# Specify the set of valid argument names that this script/function can
# accept.  Then process the arguments provided to it (which should con-
# sist of a set of name-value pairs of the form arg1="value1", etc).
#
#-----------------------------------------------------------------------
#
valid_args=( "verbose" \
             "script_var_defns_fp" \
             "file_group" \
           )
process_args valid_args "$@"
#
#-----------------------------------------------------------------------
#
# Source the variable definitions script and the function definitions
# file.
#
#-----------------------------------------------------------------------
#
. ${script_var_defns_fp}
#
#-----------------------------------------------------------------------
#
# If verbose is set to TRUE, print out what each valid argument has been
# set to.
#
#-----------------------------------------------------------------------
#
if [ "$verbose" = "TRUE" ]; then
  num_valid_args="${#valid_args[@]}"
  print_info_msg "\n\
The arguments to script/function \"${script_name}\" have been set as 
follows:
" 1>&2
  for (( i=0; i<$num_valid_args; i++ )); do
    line=$( declare -p "${valid_args[$i]}" )
    printf "  $line\n" 1>&2
  done
fi
#
#-----------------------------------------------------------------------
#
# Create symlinks in the FIXsar directory pointing to the grid files.
# These symlinks are needed by the make_orog, make_sfc_climo, make_ic,
# make_lbc, and/or run_fcst tasks.
#
# Note that we check that each target file exists before attempting to 
# create symlinks.  This is because the "ln" command will create sym-
# links to non-existent targets without returning with a nonzero exit
# code.
#
#-----------------------------------------------------------------------
#
if [ "$verbose" = "TRUE" ]; then
  print_info_msg "
Creating links in the FIXsar directory to the grid files...
"
fi
#
#-----------------------------------------------------------------------
#
# Create globbing patterns for grid, orography, and surface climo files.
#
#-----------------------------------------------------------------------
#
fns_grid=( \
"C*_mosaic.nc" \
"C*_grid.tile${TILE_RGNL}.halo${nh3_T7}.nc" \
"C*_grid.tile${TILE_RGNL}.halo${nh4_T7}.nc" \
)

fns_orog=( \
"C*_oro_data.tile${TILE_RGNL}.halo${nh0_T7}.nc" \
"C*_oro_data.tile${TILE_RGNL}.halo${nh4_T7}.nc" \
)

sfc_climo_fields=( \
"facsf" \
"maximum_snow_albedo" \
"slope_type" \
"snowfree_albedo" \
"soil_type" \
"substrate_temperature" \
"vegetation_greenness" \
"vegetation_type" \
)
num_fields=${#sfc_climo_fields[@]}
fns_sfc_climo=()
for (( i=0; i<${num_fields}; i++ )); do
  ii=$((2*i))
  fns_sfc_climo[$ii]="C*.${sfc_climo_fields[$i]}.tile${TILE_RGNL}.halo${nh0_T7}.nc"
  fns_sfc_climo[$ii+1]="C*.${sfc_climo_fields[$i]}.tile${TILE_RGNL}.halo${nh4_T7}.nc"
done
#
#-----------------------------------------------------------------------
#
# Prepend appropriate directory to each set of file name globbing pat-
# terns.
#
#-----------------------------------------------------------------------
#
fps_grid=( "${fns_grid[@]/#/${GRID_DIR}/}" )
fps_orog=( "${fns_orog[@]/#/${OROG_DIR}/}" )
fps_sfc_climo=( "${fns_sfc_climo[@]/#/${SFC_CLIMO_DIR}/}" )

if [ "${file_group}" = "grid" ]; then
  fps_all=( "${fps_grid[@]}" )
  run_task="${RUN_TASK_MAKE_GRID}"
elif [ "${file_group}" = "orog" ]; then
  fps_all=( "${fps_orog[@]}" )
  run_task="${RUN_TASK_MAKE_OROG}"
elif [ "${file_group}" = "sfc_climo" ]; then
  fps_all=( "${fps_sfc_climo[@]}" )
  run_task="${RUN_TASK_MAKE_SFC_CLIMO}"
else
  print_err_msg_exit "${script_name}" "\
Invalid value specified for file_group.  Valid values are:
"
fi
#
#-----------------------------------------------------------------------
#
# Find all files matching the globbing patterns and make sure that they
# all have the same C-resolution in their names.
#
#-----------------------------------------------------------------------
#
i=0
res_prev=""
res=""
fp_prev=""

for fp in ${fps_all[@]}; do

  fn=$( basename $fp )
printf "i = %s\n" "$i"
printf "  fn = %s\n" "$fn"

  res=$( printf "%s" $fn | sed -n -r -e "s/^C([0-9]*).*/\1/p" )
  if [ -z $res ]; then
    print_err_msg_exit "${script_name}" "\
The C-resolution could not be extracted from the current file's name.
The full path to the file (fp) is:
  fp = \"${fp}\"
This may be because fp contains the * globbing character, which would
imply that no files were found that match the globbing pattern specified
in fp.
"
  fi

printf "  res_prev = %s\n" "${res_prev}"
printf "  res = %s\n" "${res}"
  if [ $i -gt 0 ] && [ ${res} != ${res_prev} ]; then
    print_err_msg_exit "${script_name}" "\
The C-resolutions (as obtained from the file names) of the previous and 
current file (fp_prev and fp, respectively) are different:
  fp_prev = \"${fp_prev}\"
  fp      = \"${fp}\"
Please ensure that all files have the same C-resolution.
"
  fi

  i=$((i+1))
  fp_prev="$fp"
  res_prev=${res}

done
#
#-----------------------------------------------------------------------
#
#
#
#-----------------------------------------------------------------------
#
# Set RES to a null string if it is not already defined in the variable
# defintions file.
#
RES=${RES:-""}
if [ "$RES" = "$res" ] || [ "$RES" = "" ]; then
  cres="C${res}"
  set_file_param "${SCRIPT_VAR_DEFNS_FP}" "RES" "${res}"
  set_file_param "${SCRIPT_VAR_DEFNS_FP}" "CRES" "${cres}"
elif [ "$RES" != "$res" ]; then
  print_err_msg_exit "${script_name}" "\
The resolution (RES) specified in the variable definitions file 
(script_var_defns_fp) does not match the resolution (res) found in this
script for the specified file group (file_group):
  script_var_defns_fp = \"${script_var_defns_fp}\"
  RES = \"${RES}\"
  file_group = \"${file_group}\"
  res = \"${res}\"
This usually means that one or more of the file groups (grid, orography,
and/or surface climatology) are defined on different grids.
"
fi
#
#-----------------------------------------------------------------------
#
# Replace the * globbing character in the set of globbing patterns with 
# the C-resolution.  This will result in a set of (full paths to) speci-
# fic files.  Use these as the link targets to create symlinks in the 
# FIXsar directory.
#
#-----------------------------------------------------------------------
#
fps_all=( "${fps_all[@]/\*/$res}" )

echo
printf "fps_all = ( \\ \n"
printf "\"%s\" \\ \n" "${fps_all[@]}"
printf ")"
echo

relative_or_null=""
if [ "${run_task}" = "TRUE" ]; then
  relative_or_null="--relative"
fi

echo
echo "FIXsar = \"$FIXsar\""

cd_vrfy $FIXsar
for fp in "${fps_all[@]}"; do
  if [ -f "$fp" ]; then
    ln_vrfy -sf ${relative_or_null} $fp .
#    ln_vrfy -sf $fp .
  else
    print_err_msg_exit "${script_name}" "\
Cannot create symlink because target file (fp) does not exist:
  fp = \"${fp}\""
  fi
done
#
#-----------------------------------------------------------------------
#
# Create links locally (in the FIXsar directory) needed by the forecast
# task.  These are "files" that the FV3 executable looks for.
#
#-----------------------------------------------------------------------
#
if [ "${file_group}" = "grid" ]; then
# Create link to grid file needed by the make_ic and make_lbc tasks.
  filename="${cres}_grid.tile${TILE_RGNL}.halo${nh4_T7}.nc"
  ln_vrfy -sf ${relative_or_null} $filename ${cres}_grid.tile${TILE_RGNL}.nc
fi

# Create links to surface climatology files needed by the make_ic task.
if [ "${file_group}" = "sfc_climo" ]; then

  tmp=( "${sfc_climo_fields[@]/#/${cres}.}" )
  fns_sfc_climo_with_halo=( "${tmp[@]/%/.tile${TILE_RGNL}.halo${nh4_T7}.nc}" )
  fns_sfc_climo_no_halo=( "${tmp[@]/%/.tile${TILE_RGNL}.nc}" )

  cd_vrfy $FIXsar
  for (( i=0; i<${num_fields}; i++ )); do
    target="${fns_sfc_climo_with_halo[$i]}"
    symlink="${fns_sfc_climo_no_halo[$i]}"
    if [ -f "$target" ]; then
#      ln_vrfy -sf ${relative_or_null} $target $symlink
      ln_vrfy -sf $target $symlink
    else
      print_err_msg_exit "${script_name}" "\
Cannot create symlink because target file (target) does not exist:
  target = \"${target}\""
    fi
  done

fi
#
#-----------------------------------------------------------------------
#
# Restore the shell options saved at the start of this script/function.
#
#-----------------------------------------------------------------------
#
{ restore_shell_opts; } > /dev/null 2>&1
