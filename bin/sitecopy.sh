#!/bin/bash --login

usage()
{
cat << EOF
usage: $0 options OLD_DOMAIN NEW_DOMAIN

Copies a WordPress site (including db) from one domain to another
OLD_DOMAIN - Existing site to copy
NEW_DOMAIN - Site to overwrite with the copy

OPTIONS:
   -h                   Show this message
   --artifactdir=PATH   Place to put backups and migration artifacts. Defaults to working directory.
   --oldsitedir=PATH    Server address. Defaults to '~/domains/OLD_DOMAIN/html'
   --newsitedir=PATH    Server root password. Defaults to '~/domains/NEW_DOMAIN/html'
EOF
}

quiet=0
artifact_dir="./"
oldsite_dir=""
newsite_dir=""

while :
do
    case $1 in
        -h | --help | -\? )
            usage
            exit 0
            ;;
        --artifactdir=*)
            eval artifact_dir=${1#*=}
            if [[ ! -d "$artifact_dir" ]]; then
                echo "Artifact directory doesn't exist: '$artifact_dir'" >&2
                exit 1
            fi
            shift
            ;;
        --oldsitedir=*)
            eval oldsite_dir=${1#*=}
            
            # Make sure old site directory exists
            if [[ ! -d "$oldsite_dir" ]]; then
                echo "Old site directory doesn't exist: '$oldsite_dir'" >&2
                exit 1
            fi
            
            # Make sure old site directory has a wp-config.php file
            if [[ ! -e "$oldsite_dir/wp-config.php" ]]; then
                echo "Old site directory doesn't appear to be a WordPress site: '$oldsite_dir'" >&2
                exit 1
            fi
            shift
            ;;
        --newsitedir=*)
            eval newsite_dir=${1#*=}
            
            # Make sure new site directory exists
            if [[ ! -d "$newsite_dir" ]]; then
                echo "New site directory doesn't exist: '$newsite_dir'" >&2
                exit 1
            fi
            
            # Make sure new site directory has a wp-config.php file
            if [[ ! -e "$newsite_dir/wp-config.php" ]]; then
                echo "New site directory doesn't appear to be a WordPress site: '$newsite_dir'" >&2
                exit 1
            fi
            
            shift
            ;;
        --) # End of all options
            shift
            break
            ;;
        -*) # Unknown option
            echo "WARN: Unknown option (ignored): $1" >&2
            shift
            ;;
        *)  # No more options. Stop while loop
            break
            ;;
    esac
done

bin_dir=$(dirname $0)
if [[ "$#" != "2" ]]; then
    usage
    exit 1
fi

#
# Setup artifact directory for this run
#
if [[ ! -d $artifact_dir ]]; then
    echo "Artifact directory does not exist '$artifact_dir'" 1>&2
    exit 1
fi
# Add a directory in the artifact directory for this run
timestamp=`date +%Y%m%d%H%M%S`
artifact_dir="$artifact_dir/$timestamp"
mkdir $artifact_dir
if [[ ! -d $artifact_dir ]]; then
    echo "Could not create artifact directory for this run '$artifact_dir'" 1>&2
    exit 1
fi

# domains to work with
old_domain=$1
new_domain=$2

# If site web root directories weren't set, set to MediaTemple defaults
if [[ "$oldsite_dir" -eq "" ]]; then
    oldsite_dir="$HOME/domains/$old_domain/html"
fi

# If site web root directories weren't set, set to MediaTemple defaults
if [[ "$newsite_dir" -eq "" ]]; then
    newsite_dir="$HOME/domains/$new_domain/html"
fi

# Backup site to overwrite
echo "Backing up $new_domain..."
tar cf $artifact_dir/$new_domain.tar --directory $newsite_dir . || exit $?
# Create a backup of the database we're going to overwrite
$bin_dir/wpdbdump.sh $newsite_dir/wp-config.php >  $artifact_dir/$new_domain.dbdump.sql || exit $?

tar uf $artifact_dir/$new_domain.tar --directory $artifact_dir $new_domain.dbdump.sql || exit $?
gzip -f $artifact_dir/$new_domain.tar || exit $?
rm $artifact_dir/$new_domain.dbdump.sql || exit $?

# Create archive of site to copy
echo "Creating $old_domain archive..."
tar cf $artifact_dir/$old_domain.tar --directory $oldsite_dir . || exit $?

# Create db dump of site to copy
echo "Dumping $old_domain db..."
$bin_dir/wpdbdump.sh $oldsite_dir/wp-config.php >  $artifact_dir/$old_domain.dbdump.sql || exit $?
cp $artifact_dir/$old_domain.dbdump.sql $artifact_dir/$new_domain.new.sql || exit $?
# switch db table prefixes to new domains prefix
old_domain_prefix=$(cat $oldsite_dir/wp-config.php | grep table_prefix | cut -d \' -f 2 | sed 's/[]\/()$*.^|[]/\\\\&/g')
new_domain_prefix=$(cat $newsite_dir/wp-config.php | grep table_prefix | cut -d \' -f 2 | sed 's/[\/&]/\\\\&/g')
sed -i s/$old_domain_prefix/$new_domain_prefix/g $artifact_dir/$new_domain.new.sql || exit $?

# Preserve the new site's wp-config.php file
cp $newsite_dir/wp-config.php $artifact_dir/$new_domain.wp-config.php || exit $?

# Move copied site into place
echo "Overwrite $new_domain with $old_domain's code (except for wp-config.php)..."
rm -rf $newsite_dir/* || exit $?
tar xf $artifact_dir/$old_domain.tar --directory $newsite_dir || exit $?
# Remove old site backups and log files
rm -f $newsite_dir/wp-content/updraft/log.* $newsite_dir/wp-content/updraft/backup*
escaped_old_domain=$(echo $old_domain | sed 's/[]\/()$*.^|[]/\\\\&/g')
escaped_new_domain=$(echo $new_domain | sed 's/[\/&]/\\\\&/g')
# Replace all references in site files (non db) to old domain with new domain
grep -RZl "$old_domain" $newsite_dir | xargs -0 sed -i s/$escaped_old_domain/$escaped_new_domain/g
cp $artifact_dir/$new_domain.wp-config.php $newsite_dir/wp-config.php || exit $?

# Update new domain's db
echo "Overwrite $new_domain's db with copy of $old_domain's (with $old_domain references replaced)..."
$bin_dir/wpdbclear.sh $old_domain $new_domain $newsite_dir/wp-config.php $artifact_dir/$new_domain.new.sql || exit $?

echo "DONE! Try loading $new_domain in your browser"
