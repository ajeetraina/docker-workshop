# Control the Network

This module assumes the **Balanced** policy from setup. Rules here use `--sandbox pi-lab`, so other sandboxes are unaffected.

## The default

```bash
sbx exec pi-lab curl -sS -o /dev/null -w "%{http_code}\n" https://github.com
sbx exec pi-lab curl -sS -o /dev/null -w "%{http_code}\n" https://example.com
```

Real output:

```
200
403
```

GitHub is on the allow list. `example.com` is not, so the request is refused.

## Allow a host

```bash
sbx policy allow network --sandbox pi-lab example.com
sbx exec pi-lab curl -sS -o /dev/null -w "%{http_code}\n" https://example.com
```

Real output:

```
Added rule 111c0a31-4434-4c81-8137-1809fa21be4d to policy local (scope: sandbox:pi-lab): example.com [tcp]
200
```

## Deny a host

```bash
sbx policy deny network --sandbox pi-lab github.com
sbx exec pi-lab curl -sS -o /dev/null -w "%{http_code}\n" https://github.com
```

Real output:

```
Added rule b9e09440-d8ae-40e4-875d-77671ea7f5f0 to policy local (scope: sandbox:pi-lab): github.com [tcp,udp]
403
```

Deny beats allow. In this v0.54.0 test, both changes took effect **without restarting** the sandbox.

## Read the audit log

```bash
sbx policy log pi-lab
```

Real output (shortened):

```
BLOCKED REQUESTS
SANDBOX   TYPE      HOST              REASON                                  COUNT
pi-lab    network   github.com:443    Denied by local rule                    1
pi-lab    network   example.com:443   No matching allow rule (default deny)   1

ALLOWED REQUESTS
pi-lab    network   example.com:443                                           1
pi-lab    network   github.com:443                                            1
```

## Remove the rule

```bash
sbx policy rm network --sandbox pi-lab --resource github.com
sbx exec pi-lab curl -sS -o /dev/null -w "%{http_code}\n" https://github.com
```

Real output (run from a script, with `--force` to skip the confirmation):

```
Removed rule from policy local: resources=github.com
200
```
