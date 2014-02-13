#!/bin/bash --login

bin_dir=$(dirname $0)
if [[ "$#" != "1" ]]; then
    echo "Usage: '$bin_dir/wpdbdump.sh PATH_TO_WP_CONFIG_FILE'"
    exit 1
fi

if [[ ! -f $1 ]]; then
    echo "File does not exist: '$1'" 1>&2
    exit 1
fi

# Pull db credential out of wp-config.php file
db_name=$($bin_dir/wpdbgetcred.sh $1 name) || exit $?
db_user=$($bin_dir/wpdbgetcred.sh $1 user) || exit $?
db_pass=$($bin_dir/wpdbgetcred.sh $1 password) || exit $?
db_host=$($bin_dir/wpdbgetcred.sh $1 host) || exit $?

# Only dump the tables with the correct prefix
table_prefix=$(cat $1 | grep table_prefix | cut -d \' -f 2)
tables=$(mysql -h $db_host -u $db_user -p"$db_pass" $db_name --silent -e "show tables like '$table_prefix%'") || exit $?

# dump the db to standard out
mysqldump --single-transaction -u $db_user -p"$db_pass" -h $db_host $db_name --tables $tables || exit $?
