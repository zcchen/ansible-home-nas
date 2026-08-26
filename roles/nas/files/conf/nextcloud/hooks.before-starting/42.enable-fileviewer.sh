#!/usr/bin/env bash

cd /var/www/html/


FORMATS_DISABLED=(
    # office
    docx xlsx pptx vsdx
    # documents
    ofd pdf typ typst
    # ebooks
    epub umd
    # images
    avif bmp gif heic heif ico jpg jpeg jxl png svg tiff tif webp
    # video & audio
    aac flac m3u8 m4a midi mid mp3 mp4 mpeg ogg oga opus wav weba webm
    # codes
    md markdown
)

val_txt=""
for f in "${FORMATS_DISABLED[@]}"; do
    if [ -z "${val_txt}" ]; then
        val_txt="\"format:$f\""
    else
        val_txt="${val_txt},\"format:$f\""
    fi
done

php occ app:enable fileviewer
php occ config:app:set fileviewer disabled_format_ids --value="[$val_txt]"

