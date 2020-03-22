#!/usr/bin/env bash
set -euo pipefail

exithandler() {
    if [ "$?" != "0" ]; then
        echo "exiting after error"
    fi
}
trap exithandler EXIT

assertargnotempty() {
    local var="$1"
    local value="${!var}"

    local var_stripprefix="${var#GH_ACTION_MINIO_MIRROR__}"
    local action_input="${var_stripprefix,,*}"

    printf "checking GithHub Action variable %-7s (corresponds to entrypoint.sh env var %s)\n" "$action_input" "$var"

    if [ -z "$value" -o "$value" == '""' ]; then
        echo "entrypoint.sh env arg $var is empty or has \"\" as value"
        echo "perhaps GitHub Action variable \"$action_input\" is not set or empty"
        exit 1
    fi
}

assertargnotempty GH_ACTION_MINIO_MIRROR__HOST
assertargnotempty GH_ACTION_MINIO_MIRROR__BUCKET
assertargnotempty GH_ACTION_MINIO_MIRROR__DST
assertargnotempty GH_ACTION_MINIO_MIRROR__SRC

# set MC_HOST_<alias> variable (consumed by mc command)
export MC_HOST_gh_action_minio_upload_host="$GH_ACTION_MINIO_MIRROR__HOST"

DST="gh_action_minio_upload_host/$GH_ACTION_MINIO_MIRROR__BUCKET/$GH_ACTION_MINIO_MIRROR__DST/"
if [ ! -e "$GH_ACTION_MINIO_MIRROR__SRC" ]; then
    echo "source \"$GH_ACTION_MINIO_MIRROR__SRC\" does not exist"
    exit 2
fi
SRC="$GH_ACTION_MINIO_MIRROR__SRC"

args=("$@")
mc mirror "${args[@]}" "$SRC" "$DST"
echo success
