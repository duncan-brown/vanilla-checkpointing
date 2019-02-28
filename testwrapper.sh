#!/bin/bash

set -e

strace_pid=""
prog_pid=""

function checkpoint_death {
  echo "exiting with SIGTERM" &>> wrapper.log
  cleanup
  /bin/kill -s TERM $$
}

function checkpoint_trap {
  echo "checkpoint_trap function called" &>> wrapper.log
  while prog_state=$(ps hos -p ${prog_pid}) && [[ "${prog_state}" = "D" ]] ; do
    echo "process is doing disk i/o, waiting..." &>> wrapper.log
    sleep 5
  done
  echo "sending SIGTSTP to pid ${prog_pid}" &>> wrapper.log
  if /bin/kill -s TSTP ${prog_pid} &>> wrapper.log ; then
    while sleep 5 && prog_state=$(ps hos -p ${prog_pid}) && ! [[ "${prog_state}" = "t" || "${prog_state}" = "T" ]] ; do
      echo "waiting for pid ${prog_pid} to suspend..." &>> wrapper.log
    done
    echo "pid ${prog_pid} is in state ${prog_state}" &>> wrapper.log
  else
    echo "failed to send SIGTSTP to ${prog_pid}" &>> wrapper.log
    checkpoint_death
  fi
  if prog_state=$(ps hos -p ${prog_pid}) ; then
    echo "unsetting USR1 trap and re-sending USR1 to pid $$" &>> wrapper.log
    trap - USR1
    cleanup
    /bin/kill -s USR1 $$
  else
    echo "process went away during checkpoint" &>> wrapper.log
    checkpoint_death
  fi
}

function cleanup {
  set +e
  echo "cleanup: killing any strace process" &>> wrapper.log
  if [ ! -z ${strace_pid} ] ; then
    /bin/kill -s TERM ${strace_pid} &>> wrapper.log
  fi
  rm -f strace.out
}

trap checkpoint_trap USR1
trap cleanup EXIT

function strace_wait {
  if ! prog_state=$(ps hos -p ${prog_pid}) ; then
    echo "program went away before strace, exiting with SIGTERM" &>> wrapper.log
    /bin/kill -s TERM $$
  else
    echo "starting strace on ${prog_pid} in state ${prog_state}" &>> wrapper.log
  fi
  strace -e trace=none -q -p ${1} &> strace.out &
  strace_pid=${!}
  wait ${strace_pid}
  echo "strace exited with: $(cat strace.out)" &>> wrapper.log
  st_ec=$(tail -n 1 strace.out)
  rm -f strace.out
  sig_regex='^(.*) SIG([A-Z]*) (.*)$'
  if [[ ${st_ec} =~ ${sig_regex} ]]; then
    es=${BASH_REMATCH[2]}
    echo "exiting with SIG${es}" &>> wrapper.log
    /bin/kill -s ${es} $$
  else
    ec="${st_ec//[!0-9]/}"
  fi
}

if [ -f wrapper.checkpoint ] ; then
  prog_pid=$(cat wrapper.checkpoint)
  echo "wrapper checkpoint found for pid ${prog_pid}" &>> wrapper.log
  if prog_state=$(ps hos -p ${prog_pid}) ; then
    while prog_state=$(ps hos -p ${prog_pid}) && [[ "${prog_state}" = "t" || "${prog_state}" = "T" ]] ; do
      echo "sending SIGCONT to process ${prog_pid} in state ${prog_state}" &>> wrapper.log
      /bin/kill -s CONT $prog_pid &>> wrapper.log
      sleep 1
    done
    strace_wait ${prog_pid}
  else
    echo "could not find pid ${prog_pid}, starting from scratch" &>> wrapper.log
    rm -f wrapper.checkpoint
    stdbuf -oL nohup "${@}" 1>nohup.out 2>nohup.err </dev/null &
    prog_pid=${!}
    echo ${prog_pid} > wrapper.checkpoint
    echo "job running as pid ${prog_pid}" &>> wrapper.log
    wait ${prog_pid}
    ec=$?
  fi
else
  echo "no wrapper checkpoint found, starting job from scratch" &>> wrapper.log
  stdbuf -oL nohup "${@}" 1>nohup.out 2>nohup.err </dev/null &
  prog_pid=${!}
  echo ${prog_pid} > wrapper.checkpoint
  echo "job running as pid ${prog_pid}" &>> wrapper.log
  wait ${prog_pid}
  ec=$?
fi

echo "dumping stderr and stdout" &>> wrapper.log

cat nohup.out >&1
cat nohup.err >&2

rm -f nohup.out nohup.err

echo "exiting with code $ec" &>> wrapper.log

exit $ec
