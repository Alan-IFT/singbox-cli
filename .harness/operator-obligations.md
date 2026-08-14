# Operator obligations

Steps a **human** must perform on a host this project's agents cannot reach. Ids are permanent:
append with the next unused id, never renumber, never delete a discharged row (mark it).

| id | obligation | why an agent cannot do it | opened by |
|---|---|---|---|
| 1 | After installing a build that carries T-20, run `sc doctor` as root on a real install and confirm: the report prints all nine sections, exits with the mapped status (0 / 1 / 2), and the service witness (`systemctl is-active sing-box`, the TUN device, the Clash API port) is unchanged before and after. | AC-B14's subject is the *shipped invocation* — the installed `/usr/local/bin/sc` running as root against the live service. Installing a candidate over `/usr/local/bin/sc` is forbidden by `02_SOLUTION_DESIGN.md` K-18, and no agent in this pool holds an interactive root credential. Stage 6 reported it **BLOCKED** rather than substituting a weaker artifact check (the R-31 / R-41 / R-47 precedent). | T-20 `doctor-extended-checks`, stage 6 |
