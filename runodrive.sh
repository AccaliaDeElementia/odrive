#!/bin/bash

APPDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
PATH="${APPDIR}/bin:${PATH}"
PID_ODRIVEAGENT=''
PID_ODRIVEREFRESH=''
PID_ODRIVETRASH=''
PID_ODRIVESYNC=''
PID_LOGROTATE=''

function initOneDrive() {
    local INIT_FIRST=0
    if [ ! -e /home/odrive/.odrive-agent/db/odrive.db -a "${ODRIVE_AUTH_TOKEN}" = "NOAUTH" ]; then
        INIT_FIRST=1
        echo "NO AUTHENTICATION TOKEN PROVIDED. CANNOT RUN" >&2
        exit 1
    fi
    odriveagent &>/var/log/odriveagent.log &
    PID_ODRIVEAGENT=$!
    sleep 2s;
    if [ "${INIT_FIRST}" = "1" ]; then
        odrive authenticate "${ODRIVE_AUTH_TOKEN}"
        odrive mount /data "${ODRIVE_REMOTE_MOUNT}"
        sleep 5s
    fi
}

function refreshMount() {
    while true; do
        echo "" >> /var/log/odriverefresh.log
        date >> /var/log/odriverefresh.log
        echo "Initiating Refresh of data" >> /var/log/odriverefresh.log
        find /data -type d -print0 |xargs -r0 -n1 odrive refresh &>> /var/log/odriverefresh.log
        echo "" >> /var/log/odriverefresh.log
        date >> /var/log/odriverefresh.log
        echo "Completed Refresh of data" >> /var/log/odriverefresh.log
        sleep 6h;
    done
}

function emptyTrash() {
    while true; do
        echo "" >> /var/log/odriverefresh.log
        date >> /var/log/odriverefresh.log
        echo "Initiating emptying of trash" >> /var/log/odriverefresh.log
        odrive emptytrash &>> /var/log/odriverefresh.log
        echo "" >> /var/log/odriverefresh.log
        date >> /var/log/odriverefresh.log
        echo "Completed emptying of trash" >> /var/log/odriverefresh.log
        sleep 1h;
    done
}

function syncMount() {
    while true; do
        echo "" >> /var/log/odrivesync.log
        date >> /var/log/odrivesync.log
        echo "Initiating Sync of data" >> /var/log/odrivesync.log
        find /data  -iname '*.cloudf' -print0 -o -iname '*.cloud' -print0 |xargs -r0 -n1 odrive sync &>> /var/log/odrivesync.log
        echo "" >> /var/log/odrivesync.log
        date >> /var/log/odrivesync.log
        echo "Completed Sync of data" >> /var/log/odrivesync.log
        sleep 5m;
    done
}

function logRotate() {
    while true; do
        sleep 24h;
        cp /var/log/odriveagent.log /var/log/odriveagent.1.log;
        > /var/log/odriveagent.log;
        cp /var/log/odrivesync.log /var/log/odrivesync.1.log;
        > /var/log/odrivesync.log;
        cp /var/log/odriverefresh.log /var/log/odriverefresh.1.log;
        > /var/log/odriverefresh.log;
    done;
}


initOneDrive;

logRotate &
PID_LOGROTATE=$!

refreshMount &
PID_ODRIVEREFRESH=$!

sleep 1m

syncMount &
PID_ODRIVESYNC=$!
emptyTrash &
PID_ODRIVETRASH=$!

cat > /app/run.pids <<PIDS
PID_ODRIVEAGENT=${PID_ODRIVEAGENT}
PID_ODRIVEREFRESH=${PID_ODRIVEREFRESH}
PID_ODRIVESYNC=${PID_ODRIVESYNC}
PID_ODRIVETRASH=${PID_ODRIVETRASH}
PID_LOGROTATE=${PID_LOGROTATE}
PIDS

while true; do
    if [ -z "${PID_LOGROTATE}" -o ! -e /proc/${PID_LOGROTATE} ]; then
        date >> /var/log/odriveagent.log
        echo 'ERROR: odrive log rotator not running' >>/var/log/odriveagent.log
        break;
    fi
    if [ -z "${PID_ODRIVEAGENT}" -o ! -e /proc/${PID_ODRIVEAGENT} ]; then
        date >> /var/log/odriveagent.log
        echo 'ERROR: odrive agent not running' >>/var/log/odriveagent.log
        break;
    fi
    if [ -z "${PID_ODRIVEREFRESH}" -o ! -e /proc/${PID_ODRIVEREFRESH} ]; then
        date >> /var/log/odriveagent.log
        echo 'ERROR: odrive refresh not running' >>/var/log/odriveagent.log
        break;
    fi
    if [ -z "${PID_ODRIVETRASH}" -o ! -e /proc/${PID_ODRIVETRASH} ]; then
        date >> /var/log/odriveagent.log
        echo 'ERROR: odrive empty trash not running' >>/var/log/odriveagent.log
        break;
    fi
    if [ -z "${PID_ODRIVESYNC}" -o ! -e /proc/${PID_ODRIVESYNC} ]; then
        date >> /var/log/odriveagent.log
        echo 'ERROR: odrive sync not running' >>/var/log/odriveagent.log
        break;
    fi
    sleep 1m;
done