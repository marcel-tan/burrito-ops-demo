# store_network_baseline_west

Copy of `store_network_baseline` taken in 2022 when the West region moved to the
newer switch model and needed a different VLAN numbering. The two roles have
drifted since: this one hardcodes the VLAN list, drops the `log` keyword on the
deny rules, and never got the syslog/NTP block. Nobody is sure which of the two
is authoritative for a West store built after 2023.
