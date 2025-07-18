#!/system/bin/sh

IS_LEGACY=0
TZ_EXTRACTED=${TMPDIR}/tzroller/tz_extracted
TZ_SETUP=${TMPDIR}/tzroller/tz_setup
TZ_COMPILED=${TMPDIR}/tzroller/tz_compiled
ZONEINFO_DIR=${TMPDIR}/tzroller/zoneinfo_dir

TZ_VERSION=
TZ_FILES=
EXEC_ZIC=

APEX_TZDIR="/system/apex/com.android.tzdata/etc/tz"
SYST_TZDIR="/system/usr/share/zoneinfo"


check_android_version () {
    ui_print "Let's detect what is the version of your Android"
    ui_print "Android api/sdk level: $API"
    case $API in
    23) ui_print "Android 6";;
    24) ui_print "Android 7";;
    25) ui_print "Android 7";;
    26) ui_print "Android 8";;
    27) ui_print "Android 8";;
    28) ui_print "Android 9";;
    29) ui_print "Android 10";;
    30) ui_print "Android 11";;
    31) ui_print "Android 12";;
    32) ui_print "Android 12";;  
    33) ui_print "Android 13";; 
    34) ui_print "Android 14";;
    35) ui_print "Android 15";;
    36) ui_print "Android 16";;
    *) ui_print "Unknown android version";;
    esac

    if [ "$API" -lt 23 ]; then
        abort "Error: only Android 6 and above are supported"
    fi

    if [ "$API" -lt 29 ]; then
        ui_print "Updating timezone data for android legacy"
        IS_LEGACY=1
    fi
}


tz_version() {
    ui_print "Getting latest version of tzdata ... "
    if [ -z "${TZ_VERSION}" ]; then
        TZ_VERSION=$(wget -q -O - "http://data.iana.org/time-zones/" | grep -o 'tzdb-[0-9]\{4\}[a-z]\{1\}' | grep -o '[0-9]\{4\}[a-z]\{1\}' | sort -u | tail -n1)
        [ -n "${TZ_VERSION}" ] || abort "Error: failed to get tzdata version from data.iana.org"
    fi
    ui_print "Found tzdata version: ${TZ_VERSION}"
}


tz_download() {
    ui_print "Downloading tzdata${TZ_VERSION}.tar.gz ... "
    [ -e "${TZ_EXTRACTED}" ] || mkdir -p "${TZ_EXTRACTED}"
    wget -q -O - "http://data.iana.org/time-zones/releases/tzdata${TZ_VERSION}.tar.gz" | tar xz -C "${TZ_EXTRACTED}"
    [ $? -eq 0 ] || abort "Error: failed to get tzdata database from data.iana.org"
}

tz_scan_files() {
    ui_print "Scaning timezone files ... "
    TZ_FILES=$(find "${TZ_EXTRACTED}" -type f ! -name 'backzone' | LC_ALL=C sort |
    while read f
    do
        if [ "$(grep -c '^Link' $f)" -gt 0 -o "$(grep -c '^Zone' $f)" -gt 0 ]; then
            echo "$f"
        fi
    done)
    [ -n "${TZ_FILES}" ] || abort "Error: failed to scan timezone files"
}

tz_setup_file() {
    ui_print "Generating timezone setup files ... "
    (cat ${TZ_FILES} | grep '^Link' | awk '{print $1" "$2" "$3}'
    (cat ${TZ_FILES} | grep '^Zone' | awk '{print $2}'
    cat ${TZ_FILES} | grep '^Link' | awk '{print $3}') | LC_ALL=C sort) > ${TZ_SETUP}
    [ -e "${TZ_SETUP}" ] || abort "Error: failed to setup timezone files"
}



set_binaries () {
    ui_print "Setting up binaries ... "
    if [ "$ARCH" = "arm" -o "$ARCH" = "arm64" ]; then
        EXEC_ZIC=$MODPATH/bin/zic-arm
    elif [ "$ARCH" = "x86" -o "$ARCH" = "x64" ]; then
        EXEC_ZIC=$MODPATH/bin/zic-x86
    else 
        abort "Error: unsupported system arch: ${ARCH}"
    fi

    chmod u+x $EXEC_ZIC || abort "Error: cannot chmod $EXEC_ZIC"
}



tz_compile() {
    ui_print "Compiling timezones ... "
    [ -e "${TZ_COMPILED}" ] || mkdir -p ${TZ_COMPILED}
    for tzfile in ${TZ_FILES}
    do
        [ "${tzfile##*/}" = "backward" ] && continue
        $EXEC_ZIC -d ${TZ_COMPILED} ${tzfile}
        [ $? -ne 0 ] && abort "Error: failed to compile timezone files"
    done
}


tz_compactor() {
    ui_print "Running ZoneCompactor for tzdata ... "
    [ -e "${ZONEINFO_DIR}" ] || mkdir ${ZONEINFO_DIR}
    if [ $IS_LEGACY = 0 ]; then
        dalvikvm -cp ${MODPATH}/bin/ZoneCompactor.dex ZoneCompactor ${TZ_SETUP} ${TZ_COMPILED} ${TZ_EXTRACTED}/zone.tab ${ZONEINFO_DIR} ${TZ_VERSION}
        [ $? -eq 0 ] || abort "Error: failed to compact timezone files"
    else
        dalvikvm -cp ${MODPATH}/bin/ZoneCompactorLegacy.dex ZoneCompactor ${TZ_SETUP} ${TZ_COMPILED} ${ZONEINFO_DIR} ${TZ_VERSION}
        [ $? -eq 0 ] || abort "Error: failed to compact timezone files"
    fi
}


tz_update() {
    ui_print "Updating tzdata for apex ..."
    mkdir -p "${MODPATH}${APEX_TZDIR}"
    cp ${ZONEINFO_DIR}/tzdata "${MODPATH}${APEX_TZDIR}/" || abort "Error: failed to update tzdata files"

    ui_print "Updating tzdata for system ..."
    mkdir -p "${MODPATH}${SYST_TZDIR}"
    cp ${ZONEINFO_DIR}/tzdata "${MODPATH}${SYST_TZDIR}/" || abort "Error: failed to update tzdata files"
}       

tz_update_legacy() {
    ui_print "Updating tzdata for legacy android ..."
    mkdir -p "${MODPATH}${SYST_TZDIR}"
    cp ${ZONEINFO_DIR}/zoneinfo.dat "${MODPATH}${SYST_TZDIR}/" || abort "Error: failed to update tzdata files"
} 



check_android_version
tz_version
tz_download
tz_scan_files
tz_setup_file
set_binaries
tz_compile
tz_compactor

if [ $IS_LEGACY = 0 ]; then
tz_update
else
tz_update_legacy
fi