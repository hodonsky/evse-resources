#!/bin/bash

export AWS_ACCESS_KEY_ID=key
export AWS_SECRET_ACCESS_KEY=secret

dyn(){
  aws --region us-east-1 dynamodb --endpoint http://authdb:7000/ $@
}

USER_CREDENTIALS=$(dyn list-tables | grep UserCredentials | xargs)
if ! [[ $USER_CREDENTIALS = "UserCredentials" ]] ; then
  dyn create-table \
    --table-name UserCredentials \
    --attribute-definitions \
      AttributeName=email,AttributeType=S \
    --key-schema \
      AttributeName=email,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=3,WriteCapacityUnits=3
  dyn batch-write-item \
    --request-items file:///./.scripts/dynamodb/table_UserCredentials.dynadb.json
fi

JTI_TOKENS=$(dyn list-tables | grep JTI_Tokens | xargs)
if ! [[ $JTI_TOKENS = "JTI_Tokens" ]]; then
  dyn create-table \
    --table-name JTI_Tokens \
    --attribute-definitions \
      AttributeName=token,AttributeType=S \
    --key-schema \
      AttributeName=token,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=3,WriteCapacityUnits=3
fi
