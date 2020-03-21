#!/usr/bin/env bash
set -euo pipefail

ALIAS="$1"
USER="$2"
BUCKET="$3"
REPLACE="$4"
replace() {
    [ "$REPLACE" == "replace" ]
}

SECRET="$(pwgen 40)"


POLICYNAME="$BUCKET:rw"

BUCKET_RW=$(envsubst <<EOF
{
    "Version":"2012-10-17",
    "Statement":[
        {
            "Resource":["arn:aws:s3:::$BUCKET/*"],
            "Effect":"Allow",
            "Action":["s3:*"]
        }
    ]
}
EOF
)


ALIAS_URL="$(mc config host list "$ALIAS" --json | jq -r .URL)"
ALIAS_URL_NO_PROTOCOL="${ALIAS_URL#*://}"
ALIAS_URL_PROTOCOL="${ALIAS_URL%"$ALIAS_URL_NO_PROTOCOL"}"
if [ "$ALIAS_URL_PROTOCOL$ALIAS_URL_NO_PROTOCOL" != "$ALIAS_URL" ]; then
    echo "implementation error: cannot parse alias url $ALIAS_URL"
    echo "protocol: $ALIAS_URL_PROTOCOL"
    echo "remainder: $ALIAS_URL_NO_PROTOCOL"
    exit 3
fi
echo "alias url is $ALIAS_URL"
echo "  protocol: $ALIAS_URL_PROTOCOL"

if ! replace; then
    (mc admin user info "$ALIAS" "$USER" 2>&1 | grep "does not exist") || (echo "user $USER already exists"; exit 1)
fi
if ! replace; then
    (mc admin policy info "$ALIAS" "$POLICYNAME" 2>&1 | grep "is not found") || (echo "policy $POLICYNAME already exists"; exit 1)
fi
# no need to check that bucket exists, can't recreate it

echo "creating bucket $BUCKET"
mc mb "$ALIAS/$BUCKET"

echo "creating policy $POLICYNAME:"
echo "$BUCKET_RW"
echo
echo

echo "$BUCKET_RW" | mc admin policy add "$ALIAS" "$POLICYNAME"  /dev/stdin

echo "creating user $USER"
echo "with secret $SECRET"

mc admin user add "$ALIAS" "$USER" "$SECRET"

echo "setting above bucket policy for user"

mc admin policy set "$ALIAS" "$POLICYNAME" "user=$USER" 

echo SUCCESS
echo Use the following environment variable to impersonate the user create above:
echo "MC_HOST_myalias=${ALIAS_URL_PROTOCOL}${USER}:${SECRET}@${ALIAS_URL_NO_PROTOCOL}"
