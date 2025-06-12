#!/bin/bash
set -e

MJOLNIR_USERNAME=mjolnir
MJOLNIR_PASSWD=$(dd if=/dev/urandom bs=16 count=1 2>/dev/null | base64 )

printf "$MJOLNIR_USERNAME\n$MJOLNIR_PASSWD\n$MJOLNIR_PASSWD\ny\n" | docker run -i --network=host -v /opt/synapse-chat.example.org/:/data:ro --entrypoint register_new_matrix_user matrixdotorg/synapse -c /data/homeserver.yaml http://localhost:8008 2>&1 >/dev/null

SYNAPSE_OUTPUT=$(curl -X POST -H 'Content-Type: application/json' -d "{\"identifier\":{\"type\": \"m.id.user\", \"user\": \"$MJOLNIR_USERNAME\"}, \"password\": \"$MJOLNIR_PASSWD\", \"type\": \"m.login.password\"}" http://localhost:8008/_matrix/client/v3/login 2>/dev/null)


SYNAPSE_OUTPUT=$(printf "$SYNAPSE_OUTPUT" | grep -o '"access_token":"[^"]*' | grep -o '[^"]*$')

echo Mjolnir account has the password $MJOLNIR_PASSWD
printf "Access Token is\n$SYNAPSE_OUTPUT\n"

umask 0077

printf "Username: $MJOLNIR_USERNAME\nPassword: $MJOLNIR_PASSWD\nAccess Token: $SYNAPSE_OUTPUT\n" > /root/mjolnir-user.txt

echo Credentials have been saved to /root/mjolnir-user.txt

rm -- $0
