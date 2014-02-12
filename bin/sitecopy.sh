#!/bin/bash --login

bin_dir=$(dirname $0)
if [[ "$#" != "2" ]]; then
    echo "Usage: '$bin_dir/sitecopy.sh OLD_DOMAIN NEW_DOMAIN'"
    exit 1
fi

TMP_DIR="~/tmp"
if [[ -d "$TMP_DIR" ]]; then
    mkdir $TMP_DIR
    if [[ -d "$TMP_DIR" ]]; then
        echo "Unable to create temp directory '$TMP_DIR'" 1>&2
        exit 1
    fi
fi
timestamp=`date +%Y%m%d%H%M%S`
TMP_DIR="$TMP_DIR/$timestamp"
mkdir $TMP_DIR

old_domain=$1
new_domain=$2

# Backup site to overwrite
echo "Backing up $new_domain..."
tar cf $TMP_DIR/$new_domain.tar --directory ~/domains/$new_domain html
$bin_dir/wpdbdump.sh ~/domains/$new_domain/html/wp-config.php >  $TMP_DIR/$new_domain.dbdump.sql
tar uf $TMP_DIR/$new_domain.tar --directory $TMP_DIR $new_domain.dbdump.sql
gzip -f $TMP_DIR/$new_domain.tar
rm $TMP_DIR/$new_domain.dbdump.sql

# Create archive of site to copy
echo "Creating $old_domain archive..."
tar cf $TMP_DIR/$old_domain.tar --directory ~/domains/$old_domain html

# Create db dump of site to copy
echo "Dumping $old_domain db..."
$bin_dir/wpdbdump.sh ~/domains/$old_domain/html/wp-config.php >  $TMP_DIR/$old_domain.dbdump.sql
cp $TMP_DIR/$old_domain.dbdump.sql $TMP_DIR/$new_domain.new.sql
# switch db table prefixes to new domains prefix
old_domain_prefix=`cat ~/domains/$old_domain/html/wp-config.php | grep table_prefix | cut -d \' -f 2 | sed 's/[]\/()$*.^|[]/\\\\&/g'`
new_domain_prefix=`cat ~/domains/$new_domain/html/wp-config.php | grep table_prefix | cut -d \' -f 2 | sed 's/[\/&]/\\\\&/g'`
sed -i s/$old_domain_prefix/$new_domain_prefix/g $TMP_DIR/$new_domain.new.sql

# Replace copied site's wp-config.php file with old site's
tar rf $TMP_DIR/$old_domain.tar --directory ~/domains/$new_domain html/wp-config.php

# Move copied site into place
echo "Overwrite $new_domain with $old_domain's code (except for wp-config.php)..."
rm -rf ~/domains/$new_domain/html
tar xf $TMP_DIR/$old_domain.tar --directory ~/domains/$new_domain

# Update new domain's db
echo "Overwrite $new_domain's db with copy of $old_domain's (with $old_domain references replaced)..."
$bin_dir/wpdbclear.sh $old_domain $new_domain ~/domains/$new_domain/html/wp-config.php $TMP_DIR/$new_domain.new.sql

echo "DONE! Try loading $new_domain in your browser"
