#!/system/bin/sh

MODDIR=${0%/*}
SRC="$MODDIR/system/product/media/bootanimation.zip"

[ -f "$SRC" ] || exit 0

# Bind over every bootanimation location that actually exists.
for DST in \
    /apex/com.android.bootanimation/etc/bootanimation.zip \
    /product/media/bootanimation.zip \
    /product/media/bootanimation-dark.zip \
    /system/product/media/bootanimation.zip \
    /system/product/media/bootanimation-dark.zip \
    /system/media/bootanimation.zip \
    /oem/media/bootanimation.zip
do
    [ -e "$DST" ] || continue

    CTX="$(ls -Z "$DST" 2>/dev/null | awk '{print $1}')"
    [ -n "$CTX" ] && chcon "$CTX" "$SRC" 2>/dev/null

    mount --bind "$SRC" "$DST" 2>/dev/null
done

exit 0