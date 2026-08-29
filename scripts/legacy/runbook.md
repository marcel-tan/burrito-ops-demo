Environment turn-up and nightly release are handled by infra/terraform + infra/helm via azure-pipelines/ (see docs/provisioning.md).

## New store turn-up

1. Network engineer drives to the store or dials into the circuit.
2. `./configure-store.sh <site-id> <region>` from a laptop on the store LAN.
3. Copy the per-site ACL file from the nearest store, edit the addresses, and
   commit it to `infra/ansible/inventories/stores/host_vars/`.
4. Email the config used to the network team distribution list.
