#!/bin/sh
ROOT_CN=lconf
ROOT_DN=dc=$ROOT_CN,dc=icinga,dc=org
BIND_DN=cn=Manager,$ROOT_DN
BIND_PW=secret

install -o ldap -g ldap /usr/share/doc/openldap-servers*/DB_CONFIG.example /var/lib/ldap/DB_CONFIG

sed -i "s/dc=my-domain,dc=com/$ROOT_DN/" \
 '/etc/openldap/slapd.d/cn=config/olcDatabase={1}bdb.ldif'
sed -i "s/dc=my-domain,dc=com/$ROOT_DN/" \
 '/etc/openldap/slapd.d/cn=config/olcDatabase={2}monitor.ldif'
echo olcRootPW: `slappasswd -s $BIND_PW` \
 >> '/etc/openldap/slapd.d/cn=config/olcDatabase={1}bdb.ldif'

### Prepare LDIF schema ###
echo 'include /etc/openldap/schema/core.schema
include /etc/openldap/schema/netways.schema' > /tmp/lconf_schema_import.conf
mkdir /tmp/lconf_schema_import
slaptest -f /tmp/lconf_schema_import.conf -F /tmp/lconf_schema_import

# Schema files have numbers like {0} starting with zero in their name
# The number of the next valid entry is therefore the number of those files:
SCHEMA_NUM=`find '/etc/openldap/slapd.d/cn=config/cn=schema' -type f -name "cn=*" | wc -l`

# Remove useless/invalid entries
sed -ri 's/^(structural|creat|entry|modif).+//g' '/tmp/lconf_schema_import/cn=config/cn=schema/cn={1}netways.ldif'
sed -i "s/{1}netways/{$SCHEMA_NUM}netways/g" '/tmp/lconf_schema_import/cn=config/cn=schema/cn={1}netways.ldif'
sed -ri "s/^(dn: .+)/\1,cn=schema,cn=config/g" '/tmp/lconf_schema_import/cn=config/cn=schema/cn={1}netways.ldif'

### Create ACLs ###
# Increment existing olcAccess indexes by 1:
perl -i -e 'while (<>) {
s{^(olcAccess: \{)(\d+)(\}.+)}{$n=$2+1; "$1$n$3"}e;
print }' '/etc/openldap/slapd.d/cn=config/olcDatabase={0}config.ldif'
sed -ri "s/(olcAccess: \{1\}.+)/olcAccess: {0}to *  by dn=$BIND_DN write\n\1/" '/etc/openldap/slapd.d/cn=config/olcDatabase={0}config.ldif'

# Unlimited results:
sed -ri 's/^(cn: config)$/\1\nolcSizeLimit: unlimited/' '/etc/openldap/slapd.d/cn=config.ldif'

service slapd restart

echo "wait for running slapd "
# wait for slapd running
for i in 1 2 3 4 5 6 7 8 9 10 ; do
    if ! netstat -tnl | grep -q 389; then
        printf '.'
        sleep 1
    else
        break
    fi
done

# Create root DN:
echo "dn: $ROOT_DN
dc: $ROOT_CN
objectClass: top
objectClass: domain" | ldapadd -x -D "$BIND_DN" -w "$BIND_PW"

# Import converted schema file:
ldapadd -x -D "$BIND_DN" -w "$BIND_PW" -f '/tmp/lconf_schema_import/cn=config/cn=schema/cn={1}netways.ldif'
# Alternative (no access to cn=config with your bind dn):
# cp '/tmp/lconf_schema_import/cn=config/cn=schema/cn={1}netways.ldif' "/etc/openldap/slapd.d/cn=config/cn=schema/cn={$SCHEMA_NUM}netways.ldif"

## Cleanup ###
rm -rf /tmp/lconf_schema_import -f /tmp/lconf_schema_import.conf

