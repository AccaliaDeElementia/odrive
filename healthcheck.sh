#!/bin/bash

source /app/run.pids

ERRORS=0
if [ -n "${PID_LOGROTATE}" -a -e /proc/${PID_LOGROTATE} ]; then
  echo 'SUCCESS: odrive log rotator running'
else 
  ((ERRORS++))
  echo 'ERROR: odrive log rotator not running'
fi
if [ -n "${PID_ODRIVEAGENT}" -a -e /proc/${PID_ODRIVEAGENT} ]; then
  echo 'SUCCESS: odrive agent running'
else
  ((ERRORS++))
  echo 'ERROR: odrive agent not running'
fi
if [ -n "${PID_ODRIVEREFRESH}" -a -e /proc/${PID_ODRIVEREFRESH} ]; then
  echo 'SUCCESS: odrive refresh running'
else
  ((ERRORS++))
  echo 'ERROR: odrive refresh not running'
fi
if [ -n "${PID_ODRIVETRASH}" -a -e /proc/${PID_ODRIVETRASH} ]; then
  echo 'SUCCESS: odrive empty trash running'
else
  ((ERRORS++))
  echo 'ERROR: odrive empty trash not running'
fi
if [ -n "${PID_ODRIVESYNC}" -a -e /proc/${PID_ODRIVESYNC} ]; then
  echo 'SUCCESS: odrive sync running'
else 
  ((ERRORS++))
  echo 'ERROR: odrive sync not running'
fi

if [ "${ERRORS}" -gt 0 ]; then
  exit 1
fi