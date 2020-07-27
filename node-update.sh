#!/bin/bash
## - SET API secret for running auto backup
CATTLE_ACCESS_KEY=a
CATTLE_SECRET_KEY=b

## - Set project id to ensure correct context
PROJECT_ID=c-xg698:p-ls57h

## - Create auto backup
curl -I -k -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' 'https://rancher.example.com/v3/clusters/c-xg698?action=backupEtcd' | grep 200


## - set context
/usr/bin/rancher context switch ${PROJECT_ID}

## - iterate over work nodes first

for n in `/usr/bin/rancher nodes ls `;
do;

echo -e "checking ok to proceed"
INACTIVE_COUNT=`rancher node ls | grep -v ID | grep -v active | wc -l`
LOOP_COUNT=0
LOOP_MAX=60

while [ $INACTIVE_COUNT -gt 0 ];
do
echo "Inactive nodes found, waiting..."
sleep 10
LOOP_COUNT=$[$LOOP_COUNT+1]
if [ $LOOP_COUNT -gt $LOOP_MAX ];
then
exit
fi
done


echo -e "rebuilding node $n"
/usr/bin/rancher kubectl drain --force=true --grace-period=1 --delete-local-data=true $n
if [ $? -gt 0 ];
then
  echo "drain command failed!"
  exit
fi

echo -e "removing node $n"
/usr/bin/rancher node rm $n
if [ $? -gt 0 ];
then
  echo "delete command failed! Check Rancher"
  exit
fi




