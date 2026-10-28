#!/system/bin/sh

MODDIR=${0%/*}
SRC="$MODDIR/bootanimation.zip"

[ -f "$SRC" ] || exit 0

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
    mount --bind "$SRC" "$DST" 2>/dev/null
done

exit 0