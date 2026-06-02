#!/system/bin/sh

# Module location
MODDIR=${0%/*}

# Targets
SRC="$MODDIR/system/product/media/bootanimation.zip"
DST="/product/media/bootanimation.zip"

# Have we our own file
[ -f "$SRC" ] || exit 0

# Safely wait for our target
i=0
while [ $i -lt 10 ]; do
  [ -d /product/media ] && break
  i=$((i+1))
  sleep 1
done

# If not here yet we exit
[ -d /product/media ] || exit 0

# Bind our source to the target
mount -o bind "$SRC" "$DST" 2>/dev/null || true

exit 0
