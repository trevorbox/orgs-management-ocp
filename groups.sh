#!/bin/bash

set -ex

export admin_password=$(oc get secret credential-ocp-keycloak -n keycloak-operator -o jsonpath='{.data.ADMIN_PASSWORD}' | base64 -d)
export keycloak_podip=$(oc get pod keycloak-0 -n keycloak-operator -o jsonpath={.status.podIP})

echo "* Request for authorization"

export keycloak_route=$(oc get route keycloak -n keycloak-operator -o jsonpath='{.spec.host}')

export TKN=$(curl -X POST "https://${keycloak_route}/auth/realms/master/protocol/openid-connect/token" \
 -H "Content-Type: application/x-www-form-urlencoded" \
 -d "username=admin" \
 -d "password=${admin_password}" \
 -d 'grant_type=password' \
 -d 'client_id=admin-cli' | jq -r '.access_token')

curl -X GET "https://${keycloak_route}/auth/admin/realms" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TKN" | jq .

curl -X GET "https://${keycloak_route}/auth/admin/realms/ocp/groups" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TKN" | jq .

curl -X GET "https://${keycloak_route}/auth/admin/realms/ocp/groups/e8af1625-83be-48b2-afb4-44311a1a27e4" \
-H "Accept: application/json" \
-H "Authorization: Bearer $TKN" | jq .
