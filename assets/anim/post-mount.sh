#!/system/bin/sh

# Us
MODDIR=${0%/*}

# Targets
SRC="$MODDIR/system/product/media/bootanimation.zip"
DST="/product/media/bootanimation.zip"

log -t myandro "post-mount start SRC=$SRC DST=$DST"

[ -f "$SRC" ] || {
  log -t myandro "missing source zip"
  exit 0
}

# Wait for target
i=0
while [ $i -lt 10 ]; do
  [ -e "$DST" ] && break
  i=$((i+1))
  sleep 1
done

[ -e "$DST" ] || {
  log -t myandro "missing destination file"
  exit 0
}

# Bind
mount -o bind "$SRC" "$DST"
rc=$?
log -t myandro "bind mount rc=$rc"

# List
ls -li "$SRC" "$DST" 2>/dev/null | log -t myandro

exit 0