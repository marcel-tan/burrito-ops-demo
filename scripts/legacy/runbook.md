# Platform Runbook (legacy)

Last verified: 2024-03-11 by the platform on-call. Parts of this are known to be
stale — step 4 in particular, the `az aks create` flags changed in CLI 2.60 and
nobody has re-tested it since.

## New environment turn-up

1. Get the subscription id from the platform wiki page (not this repo).
2. `az login` as your admin account on the jump box, `az account set`.
3. `./provision-aks.sh <env>` — takes ~40 minutes. Watch it. If it dies partway,
   delete the resource group by hand and start over, otherwise you get
   "already exists" errors on the second run.
4. `./provision-storage.ps1 -Environment <env>` from the Windows jump box.
   Yes, this overlaps with step 3. Run it anyway; the digital team's ETL job
   needs the `etl-landing` container which step 3 does not create.
5. Set storage lifecycle rules in the portal: receipts → cool after 30 days,
   archive after 180.
6. Create the state storage account by hand if this is a new subscription
   (`rg-burritoworks-tfstate`). Note: prod was never migrated to remote state;
   the prod state file lives on the platform lead's laptop and is copied to the
   `Platform Infra` SharePoint folder after every apply.
7. Add the AKS cluster to the monitoring workspace in the portal.
8. Add the new NSG to the "allowed inbound" exception spreadsheet.
9. Email the network team the new VNet CIDR so they can add it to the store
   router ACLs (see `configure-store.sh`).

## Nightly release

1. Freeze at 21:00 local. Post in the release channel.
2. `./deploy-service.sh order-ahead prod <tag>` then
   `./deploy-service.sh catering prod <tag>`.
3. Watch the dashboards for 20 minutes.
4. If a service comes up unhealthy: `kubectl -n burritoworks-prod rollout undo`
   and post in the release channel.
5. Update the release spreadsheet.

Notes accumulated over time:

- Probes are patched off in prod (`deploy-service.sh`, `PROBES=off`) because the
  readiness probe flapped during the 2024 promo and took pods out of rotation.
  Somebody should look at the actual timeout values.
- Staging has no CPU/memory limits since the March load test.
- The `allow-promo-loadtest` NSG rule in prod (0.0.0.0/0 on 443) was for the
  vendor load generator. Still open.
- Store 214 and store 352 have a `permit ip any any` in their POS ACL from the
  2022 vendor tablet pilot.

## New store turn-up

1. Network engineer drives to the store or dials into the circuit.
2. `./configure-store.sh <site-id> <region>` from a laptop on the store LAN.
3. Copy the per-site ACL file from the nearest store, edit the addresses, and
   commit it to `infra/ansible/inventories/stores/host_vars/`.
4. Email the config used to the network team distribution list.
