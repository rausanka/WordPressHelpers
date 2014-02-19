WordPressHelpers
================

A handy collection of shell scripts for working with WordPress installs (initially built for MediaTemple sites).

Main Script
===========
**sitecopy.sh** - Copies a wordpress site from one domain to another. Uses wpdbclear.sh, wpdbdump.sh, and [Search Replace DB](https://github.com/interconnectit/Search-Replace-DB).

Usage:
```
sitecopy.sh [options] old_domain new_domain

Options:
   -h                   Show this message
   --artifactdir=PATH   Place to put backups and migration artifacts. Defaults to working directory.
   --oldsitedir=PATH    Server address. Defaults to '~/domains/OLD_DOMAIN/html'
   --newsitedir=PATH    Server root password. Defaults to '~/domains/NEW_DOMAIN/html'
```

What `sitecopy.sh` does:
1. Creates a directory for artifacts (uses the current timestamp - YYYYmmddHHMMSS)
2. Backs up up the site to overwrite into the artifacts directory (new_domain)
  3. `tar`s the web root directory
  3. Dumps the database using `wpdbdump.sh`
  4. Adds the database dump to the site tar file
  5. `gzip`s the tar file
  6. Deletes the database dump
7. Backs up the domain to copy (old_domain)
8. Prepares copy of old_domain's database for new_domain
  8. Dumps old_domain's database using `wpdbdump.sh`
  9. Creates a copy of the old_domain db backup to be modified for new_domain
  10. Switches table prefixes in copy to match new_domain's `wp-config.php` prefix
11. Preserves new_domain's `wp-config.php` file for swapping into old_domain's source directory
12. Replaces new_domain's source code with old_domain's
  13. Nukes new_domain's source code
  14. Extracts old_domain's tar into new_domain's place
  15. Nukes any [updraft](https://wordpress.org/plugins/updraftplus/) backups or logs in new_domain
  16. Replaces all mentions of old_domain in new_domain's source code with new_domain
  17. Overwrites new_domain `wp-config.php` file with preserved version
18. Runs `wpclear.sh` to replace new_domain's database with old_domain copy
  19. Drops new_domain's database and re-creates it
  20. Imports copy of old_domain's database
  21. Runs Search Replace DB to replace all instances of old_domain with new_domain

Helper Scripts
==============
- **wpdbclear.sh** - Replaces a database with a dump file using the credentials in a wp-config.php file.
- **wpdbdump.sh** - Dumps a wordpress database using the credentials in a wp-config.php file.
- **wpdbgetcred.sh** - Gets a specified database credential from a wp-config.php file.
- **wpdblogin.sh** - Logs into a mysql prompt using the database credentials in a speficied wp-config.php file.
