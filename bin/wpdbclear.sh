#!/bin/bash --login

usage()
{
cat << EOF
usage: $0 OLD_DOMAIN NEW_DOMAIN PATH_TO_WP_CONFIG_FILE PATH_TO_DUMPED_DB_FILE
EOF
}

bin_dir=$(dirname $0)
if [[ "$#" != "4" ]]; then
    usage
    exit 1
fi

if [[ ! -f $3 ]]; then
    echo "File does not exist: '$3'"
    exit 1
fi

if [[ ! -f $4 ]]; then
    echo "File does not exist: '$4'"
    exit 1
fi

old_domain=$1
new_domain=$2
wp_config_path=$3
db_to_import_path=$4

db_name=$($bin_dir/wpdbgetcred.sh $wp_config_path name) || exit $?
db_user=$($bin_dir/wpdbgetcred.sh $wp_config_path user) || exit $?
db_pass=$($bin_dir/wpdbgetcred.sh $wp_config_path password) || exit $?
db_host=$($bin_dir/wpdbgetcred.sh $wp_config_path host) || exit $?

# nuke old db and replace with empty new one
mysql -u $db_user -p"$db_pass" -h $db_host $db_name -e "drop database $db_name; create database $db_name;" || exit $?
echo "Deleted $db_name and recreated it!"

# import new database
mysql -u $db_user -p"$db_pass" -h $db_host $db_name < $db_to_import_path || exit $?

# Fix the urls
$bin_dir/search-replace-db/srdb.cli.php -v -u $db_user -p"$db_pass" -h $db_host -n $db_name -s $old_domain -r $new_domain || exit $?
