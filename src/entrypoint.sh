#!/bin/bash

USER_ID=${LOCAL_USER_ID:-9001}

echo "Starting with UID : $USER_ID"
useradd -d /pm -o -c "PocketMine-MP"      pm -s /bin/bash -u $USER_ID
export HOME=/pm
chown -R pm:pm /pm
chown -R pm:pm /pm_data

EXEC=exec
ASSETS="banned-ips.txt banned-players.txt ops.txt players plugins pocketmine.yml server.properties white-list.txt worlds"
for ASSET in $ASSETS; do
  if [[ -e /pm_data/$ASSET ]]; then
    ln -s /pm_data/$ASSET /pm/$ASSET
  else
    EXEC=
  fi
done

if [[ -z $@ ]]; then
  cd /pm
  echo "$EXEC /usr/local/bin/gosu pm /tmp/wrapper.pl"
  $EXEC /usr/local/bin/gosu pm /tmp/wrapper.pl
else
  echo "$EXEC $@"
  $EXEC $@
fi

for ASSET in $ASSETS; do
  if [[ ! -e /pm_Data/$ASSET ]]; then
    cp -r /pm/$ASSET /pm_data/$ASSET
    chown -R pm:pm /pm_data/$ASSET
  fi
done
