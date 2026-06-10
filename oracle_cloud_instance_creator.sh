#!/bin/bash

source .env

if [[ -z "${TENANCY_ID}" ]]; then
    echo "TENANCY_ID is unset or empty. Please change in .env file"
    exit 1
else
    echo "TENANCY_ID is set correctly"
fi

# To verify that the authentication with Oracle cloud works
echo "Checking Connection with this request: "
oci iam compartment list
if [[ $? -ne 0 ]]; then
    echo "Connection to Oracle cloud is not working. Check your setup and config again!"
    exit 1
fi

# ----------------------CUSTOMIZE---------------------------------------------------------------------------------------

# Don't go too low or you run into 429 TooManyRequests
requestInterval="$REQUEST_INTERVAL" # seconds
backoffTime="$BACKOFF_TIME" # seconds

# VM params
cpus="$CPUs" # max 4 cores for all Arm-based VM shapes
ram="$RAM" # max 24gb memory for all Arm-based VM shapes
bootVolume="$BOOT_VOLUME" # disk size in gb, max 200gb for all Arm-based VM shapes

profile="$PROFILE" # OCI CLI profile name, default is "DEFAULT"

# ----------------------ENDLESS LOOP TO REQUEST AN ARM INSTANCE---------------------------------------------------------

text="Working hard to get you an instance up and running... Please wait. "
length=${#text}
# length=$(echo "$text" | wc -c)
# wc -c counts the newline, so we subtract 1 to get exact string length
# length=$((length - 1))
i=0

while true; do

    error_output=$(oci compute instance launch --no-retry  \
    --auth api_key \
    --profile "$profile" \
    --display-name "a1-${cpus}c${ram}g-$(date +%s)" \
    --compartment-id "$TENANCY_ID" \
    --image-id "$IMAGE_ID" \
    --subnet-id "$SUBNET_ID" \
    --assign-public-ip true \
    --availability-domain "$AVAILABILITY_DOMAIN" \
    --shape 'VM.Standard.A1.Flex' \
    --shape-config "{\"ocpus\":$cpus,\"memoryInGBs\":$ram}" \
    --boot-volume-size-in-gbs "$bootVolume" \
    --ssh-authorized-keys-file "$PATH_TO_PUBLIC_SSH_KEY" \
    --wait-for-state RUNNING \
    --max-wait-seconds 600 2>&1) || exit_code=$?

    # Check if the command was successful
    if [[ "$exit_code" -eq 0 ]]; then
        echo ""
        echo "$(date '+%Y-%m-%d %H:%M:%S'): Instance created successfully! Exiting."
        exit 0
    fi

    if echo "$error_output" | grep -qi "Out of host capacity"; then
        char="${text:$i:1}"
        # 1. Extract exactly one character (POSIX sh safe)
        # We use cut because it is lightweight and built into almost all containers
        # char=$(printf "%s" "$text" | cut -c $((i + 1)))
        echo -n "$char"
        # printf "%s" "$char"
        ((i++))
        # i=$((i + 1))
        if [ $i -eq $length ]; then
            i=0
        fi
        #echo "$(date '+%Y-%m-%d %H:%M:%S'): Out of host capacity. Retrying in $requestInterval seconds..."
        sleep $requestInterval
    elif echo "$error_output" | grep -qi "TooManyRequests\|429"; then
        echo ""
        echo "$(date '+%Y-%m-%d %H:%M:%S'): TooManyRequests. Retrying in $backoffTime seconds..."
        sleep $backoffTime
    elif echo "$error_output" | grep -qi "InvalidParameter\|LimitExceeded\|NotAuthorizedOrNotFound"; then
        echo ""
        echo "$(date '+%Y-%m-%d %H:%M:%S'): InvalidParameter, LimitExceeded or NotAuthorizedOrNotFound error. Check your setup and config again! Exiting."
        echo "Error details: $error_output"
        exit 1
    else
        echo ""
        echo "$(date '+%Y-%m-%d %H:%M:%S'): An unexpected error occurred. Check the error message below and adjust your setup if necessary. Retrying in $backoffTime seconds..."
        echo "Error details: $error_output"
        sleep $backoffTime
    fi

done
