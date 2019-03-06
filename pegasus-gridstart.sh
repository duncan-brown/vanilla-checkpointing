#!/bin/bash
set -e
pegasus_lite_version_major="5"
pegasus_lite_version_minor="0"
pegasus_lite_version_patch="0dev"
pegasus_lite_enforce_strict_wp_check="true"
pegasus_lite_version_allow_wp_auto_download="true"

. pegasus-lite-common.sh

pegasus_lite_init

# cleanup in case of failures
trap pegasus_lite_signal_int INT
trap pegasus_lite_signal_term TERM
trap pegasus_lite_unexpected_exit EXIT

echo -e "\n########################[Pegasus Lite] Setting up workdir ########################"  1>&2
# work dir
export pegasus_lite_work_dir=$PWD
pegasus_lite_setup_work_dir

echo -e "\n##############[Pegasus Lite] Figuring out the worker package to use ##############"  1>&2
# figure out the worker package to use
pegasus_lite_worker_package

echo -e "\n##################### Checking file integrity for input files #####################"  1>&2
# do file integrity checks

set +e
job_ec=0
echo -e "\n######################[Pegasus Lite] Executing the user task ######################"  1>&2
pegasus-kickstart -n testjob -N j1 -R local  -s my.output=my.output -s my.checkpoint=my.checkpoint -s wrapper.log=wrapper.log -s wrapper.checkpoint=wrapper.checkpoint -L diamond -T 2019-02-28T17:34:12-05:00 /home/dbrown/projects/osg/condor-checkpoint-sig/testjob.sh 
job_ec=$?
set -e

set -e


# clear the trap, and exit cleanly
trap - EXIT
pegasus_lite_final_exit

