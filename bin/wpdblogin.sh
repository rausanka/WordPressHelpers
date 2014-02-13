#!/bin/bash --login

usage()
{
cat << EOF
usage: $0 PATH_TO_WP_CONFIG
EOF
}

bin_dir=$(dirname $0)
if [[ "$#" != "1" ]]; then
    usage
    exit 1
fi

wp_config_path=$1
if [[ ! -f $wp_config_path ]]; then
    echo "File does not exist: '$wp_config_path'" 1>&2
    exit 1
fi

# Pull db credential out of wp-config.php file
db_name=$($bin_dir/wpdbgetcred.sh $wp_config_path name) || exit $?
db_user=$($bin_dir/wpdbgetcred.sh $wp_config_path user) || exit $?
db_pass=$($bin_dir/wpdbgetcred.sh $wp_config_path password) || exit $?
db_host=$($bin_dir/wpdbgetcred.sh $wp_config_path host) || exit $?

mysql -u $db_user -p"$db_pass" -h $db_host $db_name || exit $?
