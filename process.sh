#!/bin/bash

set -ex

export admin_password=$(oc get secret credential-ocp-keycloak -n keycloak-operator -o jsonpath='{.data.ADMIN_PASSWORD}' | base64 -d)
export keycloak_route=$(oc get route keycloak -n keycloak-operator -o jsonpath='{.spec.host}')
export realm=ocp

login() {
  export TKN=$(curl -X POST "https://${keycloak_route}/auth/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin" \
    -d "password=${admin_password}" \
    -d 'grant_type=password' \
    -d 'client_id=admin-cli' | jq -r '.access_token')
}

get_top_ids () {
  export ids=$(jq -r '.[].id' out.json)
}

get_subGroups () {  

  subGroups=$(jq -r '.subGroups[] | "{\"id\": \"\(.id)\", \"name\": \"\(.name)\"}"' group.json)

  if [ ! -z "$subGroups" ]; then
    while read -r line
    do
        get_group $(echo $line | jq -r '.id')
        get_subGroups
    done <<< "$subGroups"
  fi
}

get_groups () {
    curl -X GET "https://${keycloak_route}/auth/admin/realms/${realm}/groups" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $TKN" | jq . > out.json
}

get_group () {
    group=$(curl -X GET "https://${keycloak_route}/auth/admin/realms/${realm}/groups/$1" \
    -H "Accept: application/json" \
    -H "Authorization: Bearer $TKN" | jq .)
    echo $group > group.json
}

login

get_groups

get_top_ids

while read -r line
do
    get_group $line

    get_subGroups
done <<< "$ids"