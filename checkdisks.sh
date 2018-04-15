#!/bin/bash
# This script checks the health of disks

# Disks to check
disks="
/dev/sda
/dev/sdb
/dev/sdc
/dev/sdd"

globalStat="OK"
# Checking disk
for disk in $disks
do
  # Checking status for a disk
  status=(`smartctl -H $disk | grep 'PASSED'`)
  # Checking if PASSED status
  if [ -z $status ]
  then
    globalStat="NOK"
    failedDisks+=("$disk")
  fi
done

if [ $globalStat = "NOK" ]
then
  echo "${failedDisks[*]}"
else
  echo "Disks OK"
fi
