#!/bin/sh
# Check for and remove a pubring.db.lock file

LOCKFILE=~/.gnupg/public-keys.d/pubring.db.lock
if [ ! -f "$LOCKFILE" ]; then
  exit 0
fi

LOCKPID=`cat $LOCKFILE | head -n 1 | awk '{$1=$1;print}'`

if [ ! -f "/proc/$LOCKPID" ]; then
  rm $LOCKFILE
fi
