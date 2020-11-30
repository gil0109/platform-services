#!/bin/bash

if [[ $UID -ge 10000 ]]; then
    GID=$(id -g)
    sed -e "s/^postgres:x:[^:]*:[^:]*:/postgres:x:$UID:$GID:/" /etc/passwd > /tmp/passwd
    cat /tmp/passwd > /etc/passwd
    rm /tmp/passwd
fi

# FIX -> FATAL:  data directory "..." has group or world access
mkdir -p "$PATRONI_POSTGRESQL_DATA_DIR"
chmod 700 "$PATRONI_POSTGRESQL_DATA_DIR"

# bootstrap:
#  post_bootstrap: /usr/share/scripts/patroni/post_init.sh

cat > /home/postgres/patroni.yml <<__EOF__
loop_wait: 3
master_start_timeout: 0
postgresql:
  use_pg_rewind: true
  parameters:
    max_connections: ${POSTGRESQL_MAX_CONNECTIONS:-100}
    max_prepared_transactions: ${POSTGRESQL_MAX_PREPARED_TRANSACTIONS:-0}
    max_locks_per_transaction: ${POSTGRESQL_MAX_LOCKS_PER_TRANSACTION:-64}
__EOF__

mkdir /home/postgres/.config
mkdir /home/postgres/.config/patroni
cp /home/postgres/patroni.yml /home/postgres/.config/patroni/patronictl.yaml 

unset PATRONI_SUPERUSER_PASSWORD PATRONI_REPLICATION_PASSWORD
export KUBERNETES_NAMESPACE=$PATRONI_KUBERNETES_NAMESPACE
export POD_NAME=$PATRONI_NAME

exec /usr/bin/python3 /usr/local/bin/patroni /home/postgres/patroni.yml