#!/usr/bin/env bash

defFormatsPrint() {
    cat <<EOF
{
"doc":false, "docm":false, "dot":false, "dotm":false, "dotx":false, "epub":false, "fb2":false,
"fodt":false, "hml":false, "htm":false, "html":false, "hwp":false, "hwpx":false, "md":false,
"mht":false, "mhtml":false, "odt":false, "ott":false, "pages":false, "rtf":false, "stw":false,
"sxw":false, "txt":false, "wps":false, "xml":false, "csv":false, "fods":false, "numbers":false,
"ods":false, "ots":false, "tsv":false, "sxc":false, "xls":false, "xlsb":false, "xlsm":false,
"xlt":false, "xltm":false, "xltx":false, "fodp":false, "key":false, "odg":false, "odp":false,
"otp":false, "pot":false, "potm":false, "potx":false, "pps":false, "ppsm":false, "ppsx":false,
"ppt":false, "pptm":false, "sxi":false, "djvu":false, "docxf":false, "oform":false, "oxps":false,
"pdf":false, "xps":false, "vsdm":false, "vssm":false, "vssx":false, "vstm":false, "vstx":false,
"docx":true, "xlsx":true, "pptx":true, "vsdx":true
}
EOF
}
editFormatsPrint() {
    cat <<EOF
{
"epub":false, "fb2":false, "html":false, "odt":false, "ott":false, "rtf":false, "txt":false,
"csv":false, "ods":false, "ots":false, "tsv":false, "odp":false, "otp":false
}
EOF
}

cd /var/www/html/

echo ">>> Enable Plugin <onlyoffice>."
php occ app:enable onlyoffice

echo ">>> setup onlyoffice configs"
php occ config:app:set onlyoffice DocumentServerUrl --value="https://office.${DOMAIN_BASE}"
php occ config:app:set onlyoffice jwt_secret --value="${ONLYOFFICE__JWT_SECRET}"
php occ config:app:set onlyoffice DocumentServerInternalUrl --value="http://office/"
php occ config:app:set onlyoffice StorageUrl --value="http://files/"
# php occ onlyoffice:documentserver --check
php occ config:app:set onlyoffice defFormats --value="$(defFormatsPrint | jq -c)"
php occ config:app:set onlyoffice editFormats --value="$(editFormatsPrint | jq -c)"
echo ">>> onlyoffice is ready"
