#!/bin/bash --login

bin_dir=$(dirname $0)
if [[ "$#" == "0" ]]; then
    echo "Usage: '$bin_dir/wpdblogin.sh PATH_TO_WP_CONFIG'"
    exit 1
fi
wp_config_path=$1

if [[ ! -f $1 ]]; then
    echo "File does not exist: '$1'" 1>&2
    exit 1
fi

# Pull db credential out of wp-config.php file
db_name=$($bin_dir/wpdbgetcred.sh $1 name) || exit $?
db_user=$($bin_dir/wpdbgetcred.sh $1 user) || exit $?
db_pass=$($bin_dir/wpdbgetcred.sh $1 password) || exit $?
db_host=$($bin_dir/wpdbgetcred.sh $1 host) || exit $?

mysql -u $db_user -p"$db_pass" -h $db_host $db_name || exit $?
