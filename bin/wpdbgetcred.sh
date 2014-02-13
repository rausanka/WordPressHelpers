#!/bin/bash --login

usage()
{
cat << EOF
usage: $0 PATH_TO_WP_CONFIG CREDENTIAL_TO_GET
EOF
}

bin_dir=$(dirname $0)
if [[ "$#" != "2" ]]; then
    usage
    exit 1
fi

wp_config_path=$1
if [[ ! -f $wp_config_path ]]; then
    echo "File does not exist: '$wp_config_path'" 1>&2
    exit 1
fi

if [[ "$2" == "database" ]] || [[ "$2" == "name" ]]; then
    echo -n $(cat $wp_config_path | grep DB_NAME | cut -d \' -f 4)
    exit 0
elif [[ "$2" == "user" ]]; then
    echo -n $(cat $wp_config_path | grep DB_USER | cut -d \' -f 4)
    exit 0
elif [[ "$2" == "password" ]]; then
    echo -n $(cat $wp_config_path | grep DB_PASSWORD | cut -d \' -f 4)
    exit 0
elif [[ "$2" == "host" ]]; then
    raw_host=$(cat $wp_config_path | grep DB_HOST | cut -d \' -f 4)
    # Not a string, let's try an ENV variable
    if [[ $raw_host == "" ]]; then
        trimmed_host=$(cat $wp_config_path | grep DB_HOST | cut -d \{ -f 2 | cut -d \} -f 1)
        echo -n ${!trimmed_host}
    else
        echo -n $raw_host
    fi
    exit 0
else
    echo "Unknown credential: '$2'" 1>&2
    exit 1
fi
