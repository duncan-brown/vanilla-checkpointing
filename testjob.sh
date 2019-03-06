#!/bin/bash

set -e

i=0

echo "create empty output file"
rm -f my.output
touch my.output

read -r i_max s_time <<<$( tail -n 1 my.input )
echo "will run for ${i_max} iterations"
echo "sleeping for ${s_time} seconds each iteration"

if [ -f my.checkpoint ] ; then
  read -r i t_stamp <<<$( tail -n 1 my.checkpoint )
  echo "resuming from checkpoint created at: ${t_stamp}"
else
  echo "starting from scratch"
fi
echo "execution starting at iteration number: ${i}"

while [ ${i} -lt ${i_max} ] ; do
  echo "starting iteration ${i}"
  sleep ${s_time}
  t_now=$( date )
  echo "${i} ${t_now}" >> my.checkpoint
  i=$(( ${i} + 1 ))
  echo "next iteration is ${i}"
done

echo "saving checkpoint as output"
mv my.checkpoint my.output

echo "creating zero byte checkpoint file"
touch my.checkpoint

echo "exiting at " $(date)
exit 0
