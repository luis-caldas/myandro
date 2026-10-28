#!/system/bin/sh

MODDIR=${0%/*}
SRC="$MODDIR/bootanimation.zip"

[ -f "$SRC" ] || exit 0

# post-fs-data runs before apexd has mounted the normal APEXes

(
    i=0

    while [ "$i" -lt 500 ]; do
        state="$(getprop apexd.status)"

        case "$state" in
            activated|ready)
                break
                ;;
        esac

        i=$((i + 1))
        sleep 0.02
    done

    # Match lookup order

    if [ -r /apex/com.android.bootanimation/etc/bootanimation.zip ]; then

        DST=/apex/com.android.bootanimation/etc/bootanimation.zip

    else

        NAME="$(getprop ro.product.bootanim.file)"

        if [ -z "$NAME" ]; then
            if [ "$(getprop ro.boot.theme)" = "1" ]; then
                NAME=bootanimation-dark.zip
            else
                NAME=bootanimation.zip
            fi
        fi

        if [ -r "/product/media/$NAME" ]; then
            DST="/product/media/$NAME"

        elif [ -r /oem/media/bootanimation.zip ]; then
            DST=/oem/media/bootanimation.zip

        elif [ -r /system/media/bootanimation.zip ]; then
            DST=/system/media/bootanimation.zip

        else
            exit 0
        fi
    fi

    mount -o bind "$SRC" "$DST"

) >/dev/null 2>&1 &

exit 0