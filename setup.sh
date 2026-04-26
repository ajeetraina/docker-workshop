#!/usr/bin/env bash
#
# apply-devboard-project.sh
#
# Replaces the empty Playwright Browser Testing project under lab8 with a
# real DevBoard end-to-end project page.
#
# Modifies:
#   - docs/lab8/projects/devboard.md                    (new, ~290 lines)
#   - docs/lab8/projects/playwright-browser-testing.md  (deleted)
#   - mkdocs.yml: Playwright nav entry -> DevBoard
#
# Run from the root of your docker-workshop checkout:
#   git clone https://github.com/ajeetraina/docker-workshop.git
#   cd docker-workshop
#   bash /path/to/apply-devboard-project.sh
#
# Flags:
#   --no-push   create branch + commit but don't push
#   --no-build  skip the mkdocs build verification step
#

set -eo pipefail

BRANCH="add-devboard-project"
REMOTE="origin"
PUSH=1
BUILD=1

for arg in "$@"; do
  case "$arg" in
    --no-push)  PUSH=0 ;;
    --no-build) BUILD=0 ;;
    -h|--help)
      sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *)
      echo "unknown flag: $arg" >&2
      exit 2
      ;;
  esac
done

# ---------- sanity checks ---------------------------------------------------

command -v git >/dev/null 2>&1    || { echo "error: git not found"    >&2; exit 1; }
command -v base64 >/dev/null 2>&1 || { echo "error: base64 not found" >&2; exit 1; }

if [[ ! -d .git || ! -f mkdocs.yml || ! -d docs/lab8 ]]; then
  echo "error: run from the root of your docker-workshop checkout" >&2
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "error: working tree has uncommitted changes; commit or stash first" >&2
  git status --short
  exit 1
fi

# ---------- branch ----------------------------------------------------------

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  echo "branch $BRANCH already exists; checking it out" >&2
  git checkout "$BRANCH"
else
  git checkout -b "$BRANCH"
fi

# ---------- decode + apply patch -------------------------------------------

PATCH_FILE="$(mktemp -t devboard.XXXXXX.patch)"
MSG_FILE="$(mktemp -t devboard-msg.XXXXXX.txt)"
trap 'rm -f "$PATCH_FILE" "$MSG_FILE"' EXIT

base64 -d > "$PATCH_FILE" <<'PATCH_B64_EOF'
ZGlmZiAtLWdpdCBhL2RvY3MvbGFiOC9wcm9qZWN0cy9kZXZib2FyZC5tZCBiL2RvY3MvbGFiOC9w
cm9qZWN0cy9kZXZib2FyZC5tZApuZXcgZmlsZSBtb2RlIDEwMDY0NAppbmRleCAwMDAwMDAwMC4u
ZTc1YjUwNDUKLS0tIC9kZXYvbnVsbAorKysgYi9kb2NzL2xhYjgvcHJvamVjdHMvZGV2Ym9hcmQu
bWQKQEAgLTAsMCArMSwyOTMgQEAKKyMgRGV2Qm9hcmQg4oCUIEZpeCBhIFJlYWwgQnVnIEluc2lk
ZSBhIFNhbmRib3gKKworU28gZmFyIGVhY2ggbW9kdWxlIG9mIHRoaXMgbGFiIGhhcyBmb2N1c2Vk
IG9uICpvbmUqIHByaW1pdGl2ZSDigJQgaXNvbGF0aW9uLAorc2VjcmV0IGluamVjdGlvbiwgbmV0
d29yayBwb2xpY3ksIGJyYW5jaCBtb2RlLiBUaGlzIHByb2plY3QgdGllcyB0aGVtIGFsbAordG9n
ZXRoZXIgYWdhaW5zdCBhIHJlYWwgY29kZWJhc2U6ICoqRGV2Qm9hcmQqKiwgYSBGYXN0QVBJICsg
TmV4dC5qcyBpc3N1ZQordHJhY2tlciB3aXRoIGZpdmUgZG9jdW1lbnRlZCBpbnRlbnRpb25hbCBi
dWdzLgorCitZb3UnbGwgcGljayBvbmUgb2YgdGhlbSwgcG9pbnQgYW4gYWdlbnQgYXQgaXQgaW5z
aWRlIGBzYnhsYWJgLCB3YXRjaCBpdAoraW52ZXN0aWdhdGUgYW5kIGZpeCwgdGhlbiByZXZpZXcg
YW5kIG1lcmdlIOKAlCB3aXRob3V0IHRoZSBhZ2VudCBldmVyIHRvdWNoaW5nCit5b3VyIGhvc3Qg
Y3JlZGVudGlhbHMgb3IgbWFraW5nIGEgbmV0d29yayBjYWxsIHlvdSBkaWRuJ3QgYWxsb3cuCisK
Ky0tLQorCisjIyBXaGF0IHlvdSdsbCBidWlsZAorCitCeSB0aGUgZW5kIG9mIHRoaXMgcHJvamVj
dCB5b3UnbGwgaGF2ZToKKworLSBBIHJ1bm5pbmcgRGV2Qm9hcmQgc3RhY2sgKFBvc3RncmVzICsg
RmFzdEFQSSArIE5leHQuanMpIG9uIHlvdXIgaG9zdAorLSBBIHJ1bm5pbmcgYWdlbnQgaW5zaWRl
IGBzYnhsYWJgIHdpdGggcmVhZC93cml0ZSBhY2Nlc3MgdG8gdGhlIERldkJvYXJkIHJlcG8KKy0g
QSBmaXggZm9yIG9uZSBvZiB0aGUga25vd24gYnVncywgbGFuZGVkIG9uIGl0cyBvd24gR2l0IGJy
YW5jaAorLSBBIHBhc3NpbmcgYHB5dGVzdGAgcnVuIGluc2lkZSB0aGUgc2FuZGJveCBwcm92aW5n
IHRoZSBmaXgKKy0gQSBjbGVhbiBkaWZmIHlvdSByZXZpZXdlZCBiZWZvcmUgbWVyZ2luZworCist
LS0KKworIyMgVGhlIGNvZGViYXNlCisKK0RldkJvYXJkIGlzIGEgc21hbGwgYnV0IHJlYWxpc3Rp
YyBwcm9qZWN0IHRyYWNrZXIuIEl0J3MgdGhlIHNhbWUgcmVwbyB0aGUKK2xhYnNwYWNlIGNsb25l
cyBpbnRvIGB+L3NieC1sYWJgIOKAlCBpZiB5b3UndmUgd29ya2VkIHRocm91Z2ggTW9kdWxlIDIs
IHlvdQorYWxyZWFkeSBoYXZlIGl0LgorCitgYGAKK2RldmJvYXJkLwor4pSc4pSA4pSAIGJhY2tl
bmQvICAgICAgICAgICAgICAgICAgICAjIEZhc3RBUEkgKyBTUUxBbGNoZW15ICsgUG9zdGdyZVNR
TAor4pSCICAg4pSc4pSA4pSAIGFwcC8KK+KUgiAgIOKUgiAgIOKUnOKUgOKUgCBtYWluLnB5Civi
lIIgICDilIIgICDilJzilIDilIAgbW9kZWxzLnB5CivilIIgICDilIIgICDilJzilIDilIAgcm91
dGVycy8KK+KUgiAgIOKUgiAgIOKUgiAgIOKUnOKUgOKUgCBhdXRoLnB5CivilIIgICDilIIgICDi
lIIgICDilJzilIDilIAgcHJvamVjdHMucHkKK+KUgiAgIOKUgiAgIOKUgiAgIOKUnOKUgOKUgCBp
c3N1ZXMucHkgICAgICAgIyBtb3N0IG9mIHRoZSBidWdzIGxpdmUgaGVyZQor4pSCICAg4pSCICAg
4pSCICAg4pSU4pSA4pSAIGNvbW1lbnRzLnB5CivilIIgICDilIIgICDilJTilIDilIAgc2Vydmlj
ZXMvCivilIIgICDilIIgICAgICAg4pSU4pSA4pSAIG5vdGlmaWNhdGlvbnMucHkKK+KUgiAgIOKU
lOKUgOKUgCB0ZXN0cy8KK+KUgiAgICAgICDilJTilIDilIAgdGVzdF9pc3N1ZXMucHkgICAgICAj
IHRlc3RzIHRoYXQgZXhwb3NlIHRoZSBrbm93biBidWdzCivilJzilIDilIAgZnJvbnRlbmQvICAg
ICAgICAgICAgICAgICAgICMgTmV4dC5qcyAxNCBBcHAgUm91dGVyICsgVGFpbHdpbmQKK+KUlOKU
gOKUgCBkb2NrZXItY29tcG9zZS55bWwKK2BgYAorCitJZiB5b3UgZG9uJ3QgaGF2ZSBpdCBjbG9u
ZWQgeWV0OgorCitgYGBiYXNoCitnaXQgY2xvbmUgaHR0cHM6Ly9naXRodWIuY29tL2RvY2tlcnNh
bXBsZXMvc2J4LXF1aWNrc3RhcnQgfi9zYngtbGFiCitjZCB+L3NieC1sYWIKK2BgYAorCistLS0K
KworIyMgVGhlIGJ1Z3MKKworRGV2Qm9hcmQgc2hpcHMgd2l0aCBmaXZlIGludGVudGlvbmFsIGlz
c3Vlcywgb3JkZXJlZCByb3VnaGx5IGVhc2llc3QgdG8gaGFyZGVzdDoKKworfCAjIHwgQnVnIHwg
RmlsZSB8Cit8LS0tfC0tLXwtLS18Cit8IDEgfCAqKlBhZ2luYXRpb24gb2ZmLWJ5LW9uZSoqIOKA
lCBgbGlzdF9pc3N1ZXNgIHVzZXMgYHBhZ2UgKiBwYWdlX3NpemVgIGluc3RlYWQgb2YgYChwYWdl
IC0gMSkgKiBwYWdlX3NpemVgLCBzbyBwYWdlIDEgYWx3YXlzIHNraXBzIGl0ZW1zLiB8IGBiYWNr
ZW5kL2FwcC9yb3V0ZXJzL2lzc3Vlcy5weWAgfAorfCAyIHwgKipgdXBkYXRlZF9hdGAgbmV2ZXIg
dXBkYXRlcyoqIOKAlCBTUUxBbGNoZW15IGB1cGRhdGVkX2F0YCBjb2x1bW5zIGFyZSBtaXNzaW5n
IGBvbnVwZGF0ZT1kYXRldGltZS51dGNub3dgLiB8IGBiYWNrZW5kL2FwcC9tb2RlbHMucHlgIHwK
K3wgMyB8ICoqTWlzc2luZyBhdXRob3JpemF0aW9uIG9uIGlzc3VlIHVwZGF0ZSoqIOKAlCBhbnkg
cHJvamVjdCBtZW1iZXIgY2FuIGVkaXQgYW55IGlzc3VlLiB8IGBiYWNrZW5kL2FwcC9yb3V0ZXJz
L2lzc3Vlcy5weWAgfAorfCA0IHwgKipTZWFyY2ggbm90IGltcGxlbWVudGVkKiog4oCUIGBHRVQg
L3Byb2plY3RzL3tpZH0vaXNzdWVzL3NlYXJjaGAgcmV0dXJucyBgNTAxYC4gfCBgYmFja2VuZC9h
cHAvcm91dGVycy9pc3N1ZXMucHlgIHwKK3wgNSB8ICoqRW1haWwgbm90aWZpY2F0aW9ucyBhcmUg
c3R1YnMqKiDigJQgYHNlcnZpY2VzL25vdGlmaWNhdGlvbnMucHlgIGxvZ3MgYnV0IGRvZXNuJ3Qg
c2VuZC4gfCBgYmFja2VuZC9hcHAvc2VydmljZXMvbm90aWZpY2F0aW9ucy5weWAgfAorCitUaGUg
d2Fsa3Rocm91Z2ggYmVsb3cgdXNlcyAqKmJ1ZyAjMSAocGFnaW5hdGlvbikqKiBiZWNhdXNlIGl0
J3MgdGhlIGNsZWFuZXN0CitkZW1vbnN0cmF0aW9uIOKAlCBzaW5nbGUgZnVuY3Rpb24sIGNsZWFy
IHJvb3QgY2F1c2UsIGV4aXN0aW5nIHRlc3QgY292ZXJhZ2UuCitUaGUgc2FtZSB3b3JrZmxvdyB3
b3JrcyBmb3IgYW55IG9mIHRoZW0uCisKKy0tLQorCisjIyBTdGVwIDEg4oCUIEJvb3QgRGV2Qm9h
cmQgb24geW91ciBob3N0CisKK0luIGEgaG9zdCB0ZXJtaW5hbCwgZnJvbSBgfi9zYngtbGFiYDoK
KworYGBgYmFzaAorZG9ja2VyIGNvbXBvc2UgdXAgLS1idWlsZCAtZAorYGBgCisKK1dhaXQgZm9y
IGFsbCB0aHJlZSBzZXJ2aWNlcyB0byBiZSBoZWFsdGh5OgorCitgYGBiYXNoCitkb2NrZXIgY29t
cG9zZSBwcworYGBgCisKK0V4cGVjdGVkIG91dHB1dDogYGRiYCwgYGJhY2tlbmRgLCBhbmQgYGZy
b250ZW5kYCBhbGwgYHJ1bm5pbmdgLiBUaGUgQVBJIGlzIGF0CitgaHR0cDovL2xvY2FsaG9zdDo4
MDAwL2RvY3NgIGFuZCB0aGUgVUkgYXQgYGh0dHA6Ly9sb2NhbGhvc3Q6MzAwMGAuCisKKz4gKipX
aHkgb24gdGhlIGhvc3QgYW5kIG5vdCBpbiB0aGUgc2FuZGJveD8qKiBEZXZCb2FyZCBpcyB0aGUg
KmFwcGxpY2F0aW9uKi4KKz4gVGhlIGFnZW50J3Mgam9iIGlzIHRvIHJlYWQgYW5kIG1vZGlmeSBp
dHMgc291cmNlIGZpbGVzIOKAlCBub3QgdG8gcnVuIGl0LgorPiBSdW5uaW5nIHRoZSBzdGFjayBv
biB0aGUgaG9zdCBtZWFucyB5b3UgY2FuIHBva2UgYXQgYGxvY2FsaG9zdDozMDAwYCB3aGlsZQor
PiB0aGUgYWdlbnQgd29ya3MuCisKKy0tLQorCisjIyBTdGVwIDIg4oCUIENvbmZpcm0gdGhlIGJ1
ZyBleGlzdHMKKworSGl0IHRoZSBpc3N1ZXMgZW5kcG9pbnQgd2l0aCBgcGFnZT0xYCBhbmQgYSBz
bWFsbCBwYWdlIHNpemU6CisKK2BgYGJhc2gKK2N1cmwgLXMgImh0dHA6Ly9sb2NhbGhvc3Q6ODAw
MC9wcm9qZWN0cy8xL2lzc3Vlcz9wYWdlPTEmcGFnZV9zaXplPTIiIHwganEgJy5bXSB8IC5pZCcK
K2BgYAorCitZb3UnbGwgc2VlIGlzc3VlcyBgM2AgYW5kIGA0YCDigJQgKm5vdCogYDFgIGFuZCBg
MmAuIFRoYXQncyB0aGUgYnVnLgorCitUaGUgdGVzdCBzdWl0ZSBhbHJlYWR5IGhhcyBhIGNhc2Ug
dGhhdCBmYWlscyBiZWNhdXNlIG9mIHRoaXM6CisKK2BgYGJhc2gKK2RvY2tlciBjb21wb3NlIGV4
ZWMgYmFja2VuZCBweXRlc3QgdGVzdHMvdGVzdF9pc3N1ZXMucHk6OnRlc3RfcGFnaW5hdGlvbl9m
aXJzdF9wYWdlIC12CitgYGAKKworRXhwZWN0ZWQ6IGBGQUlMRURgLiBHb29kIOKAlCB0aGF0J3Mg
YSBmYWlsaW5nIHRlc3QgdGhlIGFnZW50IHdpbGwgdHVybiBncmVlbi4KKworLS0tCisKKyMjIFN0
ZXAgMyDigJQgUnVuIHRoZSBhZ2VudCBvbiB0aGUgY29kZWJhc2UgaW4gYnJhbmNoIG1vZGUKKwor
WW91J3ZlIHVzZWQgKipkaXJlY3QgbW9kZSoqIHNvIGZhciAoTW9kdWxlIDYpLiBGb3IgdGhpcyBl
eGVyY2lzZSwgdXNlCisqKmJyYW5jaCBtb2RlKiogaW5zdGVhZCDigJQgdGhlIGFnZW50IHdvcmtz
IG9uIGl0cyBvd24gR2l0IHdvcmt0cmVlIGFuZCB5b3UKK3JldmlldyB0aGUgZGlmZiBiZWZvcmUg
bWVyZ2luZy4KKworRnJvbSB0aGUgaG9zdCwgaW4gYH4vc2J4LWxhYmA6CisKK2BgYGJhc2gKK3Ni
eCBydW4gc2J4bGFiIC0tYnJhbmNoIGZpeC9wYWdpbmF0aW9uCitgYGAKKworVGhlIHNhbmRib3gg
c3RhcnRzIHVwLCBjcmVhdGVzIGEgd29ya3RyZWUgYXQgYH4vc2J4LWxhYi1zYnhsYWItZml4LXBh
Z2luYXRpb25gLAorYW5kIGRyb3BzIHlvdSBpbnRvIHRoZSBhZ2VudCBwcm9tcHQuIFRoZSB0cnVz
dCBwcm9tcHQgYXBwZWFycyBvbmNlIOKAlCBjaG9vc2UKKyoqMS4gWWVzLCBjb250aW51ZSoqLgor
CistLS0KKworIyMgU3RlcCA0IOKAlCBCcmllZiB0aGUgYWdlbnQKKworUGFzdGUgdGhpcyBwcm9t
cHQ6CisKK2BgYAorUmVhZCBiYWNrZW5kL2FwcC9yb3V0ZXJzL2lzc3Vlcy5weSBhbmQgYmFja2Vu
ZC90ZXN0cy90ZXN0X2lzc3Vlcy5weS4KK1RoZXJlJ3MgYSBrbm93biBwYWdpbmF0aW9uIGJ1ZyBp
biBsaXN0X2lzc3VlczogaXQgc2tpcHMgcGFnZSAqIHBhZ2Vfc2l6ZQoraXRlbXMgaW5zdGVhZCBv
ZiAocGFnZSAtIDEpICogcGFnZV9zaXplLCBzbyBwYWdlIDEgcmV0dXJucyB0aGUgd3JvbmcKK3Jl
c3VsdHMuCisKKzEuIExvY2F0ZSB0aGUgYnVnLgorMi4gRml4IGl0LgorMy4gUnVuIHRoZSB0ZXN0
IHRoYXQgZXhlcmNpc2VzIGl0OiBweXRlc3QgdGVzdHMvdGVzdF9pc3N1ZXMucHk6OnRlc3RfcGFn
aW5hdGlvbl9maXJzdF9wYWdlIC12Cis0LiBSdW4gdGhlIGZ1bGwgaXNzdWVzIHRlc3QgZmlsZSBv
bmNlIGl0IHBhc3Nlcy4KKzUuIFN1bW1hcmlzZSB0aGUgY2hhbmdlLgorYGBgCisKK1RoZSBhZ2Vu
dCB3aWxsOgorCistIFJlYWQgdGhlIHR3byBmaWxlcyB1c2luZyBpdHMgYGZpbGVzeXN0ZW1gIHRv
b2wKKy0gRWRpdCBgbGlzdF9pc3N1ZXNgICh0eXBpY2FsbHkgcmVwbGFjaW5nIGBza2lwID0gcGFn
ZSAqIHBhZ2Vfc2l6ZWAgd2l0aCBgc2tpcCA9IChwYWdlIC0gMSkgKiBwYWdlX3NpemVgKQorLSBS
dW4gcHl0ZXN0IGluc2lkZSB0aGUgc2FuZGJveCB2aWEgdGhlIGBzaGVsbGAgdG9vbAorCitXYXRj
aCB0aGUgb3V0cHV0LiBJbnNpZGUgYHNieGxhYmAsIGBweXRlc3RgIGhhcyBhY2Nlc3MgdG8gYHB5
cGkub3JnYCBhbmQKK2BmaWxlcy5weXRob25ob3N0ZWQub3JnYCAoZGVmYXVsdCBuZXR3b3JrIHBv
bGljeSkgYnV0IGNhbm5vdCByZWFjaCB5b3VyIGhvc3QKK2ZpbGVzeXN0ZW0uCisKKy0tLQorCisj
IyBTdGVwIDUg4oCUIFZlcmlmeSB3aGF0IGp1c3QgaGFwcGVuZWQKKworSW4gYSBzZXBhcmF0ZSBo
b3N0IHRlcm1pbmFsLCB3aGlsZSB0aGUgYWdlbnQgaXMgc3RpbGwgcnVubmluZzoKKworYGBgYmFz
aAorc2J4IGxzCitgYGAKKworWW91J2xsIHNlZSBgc2J4bGFiYCB3aXRoIHN0YXR1cyBgcnVubmlu
Z2AgYW5kIHRoZSB3b3JrdHJlZSBwYXRoLiBOb3cgbG9vayBhdAordGhlIHdvcmt0cmVlIGZyb20g
dGhlIGhvc3Q6CisKK2BgYGJhc2gKK2NkIH4vc2J4LWxhYi1zYnhsYWItZml4LXBhZ2luYXRpb24K
K2dpdCBkaWZmCitgYGAKKworWW91IHNob3VsZCBzZWUgdGhlIG9uZS1saW5lIGZpeCB0byBgbGlz
dF9pc3N1ZXNgLiBUaGUgaG9zdCdzIG1haW4gd29ya3RyZWUgYXQKK2B+L3NieC1sYWJgIGlzIHVu
dG91Y2hlZCDigJQgYGdpdCBzdGF0dXNgIHRoZXJlIGlzIHN0aWxsIGNsZWFuLgorCitgYGBiYXNo
CitjZCB+L3NieC1sYWIKK2dpdCBzdGF0dXMgICAjIGNsZWFuCitgYGAKKworT3BlbiB0aGUgbmV0
d29yayBwYW5lbCBvZiB0aGUgZGFzaGJvYXJkIHdoaWxlIHlvdSdyZSBhdCBpdDoKKworYGBgYmFz
aAorc2J4CisjIHByZXNzIFRhYiB0byBzd2l0Y2ggdG8gTmV0d29yaworYGBgCisKK1lvdSdsbCBz
ZWUgYWxsb3dlZCBjb25uZWN0aW9ucyB0byBgcHlwaS5vcmdgICh0aGUgYWdlbnQgaW5zdGFsbGlu
ZyB0ZXN0IGRlcHMpCithbmQgbm90aGluZyB0byBgfi8uYXdzYCwgYH4vLnNzaGAsIG9yIGFueSBo
b3N0IHNlcnZpY2UuIFRoZSBwcm9vZiByZW1haW5zIHRoZQorc2FtZSBhcyBpbiBNb2R1bGUgMyDi
gJQgb25seSBub3cgeW91J3JlIHJ1bm5pbmcgaXQgb24gYSByZWFsIGNvZGViYXNlIGNoYW5nZS4K
KworLS0tCisKKyMjIFN0ZXAgNiDigJQgUmV2aWV3IGFuZCBtZXJnZQorCitCYWNrIGluIGB+L3Ni
eC1sYWItc2J4bGFiLWZpeC1wYWdpbmF0aW9uYDoKKworYGBgYmFzaAorIyBSZS1ydW4gdGhlIHRl
c3Qgb24gdGhlIGhvc3QgdG8gZG91YmxlLWNoZWNrCitkb2NrZXIgY29tcG9zZSBleGVjIGJhY2tl
bmQgcHl0ZXN0IHRlc3RzL3Rlc3RfaXNzdWVzLnB5IC12CitgYGAKKworSWYgaXQncyBncmVlbiwg
bWVyZ2U6CisKK2BgYGJhc2gKK2NkIH4vc2J4LWxhYgorZ2l0IG1lcmdlIHNieGxhYi9maXgtcGFn
aW5hdGlvbgorZ2l0IGJyYW5jaCAtZCBzYnhsYWIvZml4LXBhZ2luYXRpb24KK2BgYAorCitUaGUg
YWdlbnQncyBicmFuY2ggaXMgZ29uZSwgdGhlIGZpeCBpcyBvbiBgbWFpbmAsIGFuZCB5b3VyIHdv
cmtpbmcgdHJlZQorbWF0Y2hlcyB3aGF0IHlvdSByZXZpZXdlZC4KKworLS0tCisKKyMjIFN0ZXAg
NyDigJQgVGVhciBkb3duCisKK2BgYGJhc2gKK3NieCBzdG9wIHNieGxhYgorZG9ja2VyIGNvbXBv
c2UgZG93bgorYGBgCisKK2BzYnggc3RvcGAgaGFsdHMgdGhlIFZNOyB0aGUgd29ya3RyZWUgb24g
eW91ciBob3N0IHN0YXlzIHNvIHlvdSBjYW4gcmUtZW50ZXIKK2l0IGxhdGVyLiBgZG9ja2VyIGNv
bXBvc2UgZG93bmAgc3RvcHMgRGV2Qm9hcmQuCisKKy0tLQorCisjIyBQaWNrIGFub3RoZXIgYnVn
CisKK1NhbWUgZmxvdywgZGlmZmVyZW50IGJyaWVmLiBBIGZldyBzdWdnZXN0aW9ucyBmb3IgcHJv
bXB0czoKKworKipCdWcgIzIg4oCUIGB1cGRhdGVkX2F0YCBuZXZlciB1cGRhdGVzOioqCisKK2Bg
YAorYmFja2VuZC9hcHAvbW9kZWxzLnB5IGRlZmluZXMgdXBkYXRlZF9hdCBjb2x1bW5zIHRoYXQg
bmV2ZXIgY2hhbmdlIGFmdGVyCitjcmVhdGlvbi4gVGhleSdyZSBtaXNzaW5nIHRoZSBvbnVwZGF0
ZSBwYXJhbWV0ZXIgb24gdGhlIENvbHVtbiBkZWZpbml0aW9uLgorRmluZCBldmVyeSBhZmZlY3Rl
ZCBtb2RlbCwgYWRkIG9udXBkYXRlPWRhdGV0aW1lLnV0Y25vdywgYW5kIHdyaXRlIGEgdGVzdAor
dGhhdCB1cGRhdGVzIGFuIGlzc3VlIGFuZCBhc3NlcnRzIHVwZGF0ZWRfYXQgY2hhbmdlZC4KK2Bg
YAorCisqKkJ1ZyAjNCDigJQgaW1wbGVtZW50IHNlYXJjaCoqICh0aGUgbGFic3BhY2Ugc2hpcHMg
YSBwcm9tcHQgZm9yIHRoaXMgaW4KK2Bwcm9tcHRzL2ltcGxlbWVudC1zZWFyY2gudHh0YCk6CisK
K2BgYAorSW1wbGVtZW50IHRoZSBpc3N1ZSBzZWFyY2ggZW5kcG9pbnQgaW4gYmFja2VuZC9hcHAv
cm91dGVycy9pc3N1ZXMucHkuCitHRVQgL2lzc3Vlcy9zZWFyY2g/cT0gY3VycmVudGx5IHJldHVy
bnMgNTAxLiBJdCBzaG91bGQgc2VhcmNoIHRpdGxlIGFuZAorZGVzY3JpcHRpb24gY2FzZS1pbnNl
bnNpdGl2ZWx5ICh1c2UgSXNzdWUudGl0bGUuaWxpa2UoZiIle3F9JSIpKSBhbmQgcmV0dXJuCit0
aGUgc2FtZSBzY2hlbWEgYXMgbGlzdF9pc3N1ZXMuIE1ha2UgdGhlIGV4aXN0aW5nIHNlYXJjaCB0
ZXN0cyBwYXNzLgorYGBgCisKKyoqQnVnICM1IOKAlCBpbXBsZW1lbnQgZW1haWwgbm90aWZpY2F0
aW9ucyoqIChhIG1vcmUgb3Blbi1lbmRlZCB0YXNrIOKAlCBuZWVkcworU01UUCBjb25maWcgYW5k
IGdyYWNlZnVsbHkgaGFuZGxpbmcgaXRzIGFic2VuY2UpOgorCitgYGAKK3NlcnZpY2VzL25vdGlm
aWNhdGlvbnMucHkgaGFzIGEgc3R1YiBzZW5kX3N0YXR1c19jaGFuZ2Vfbm90aWZpY2F0aW9uLgor
SW1wbGVtZW50IGl0IHVzaW5nIHNtdHBsaWIgKG5vIG5ldyBkZXBlbmRlbmNpZXMpLiBSZWFkIFNN
VFAgY29uZmlnIGZyb20KK1NNVFBfSE9TVC9QT1JUL1VTRVIvUEFTUyBlbnYgdmFycyBhbmQgd2Fy
bi1hbmQtcmV0dXJuIHdoZW4gbWlzc2luZy4KK0luY2x1ZGUgdGhlIGlzc3VlIHRpdGxlLCBvbGQg
c3RhdHVzLCBuZXcgc3RhdHVzLCBhbmQgYSBVUkwgaW4gdGhlIGJvZHkuCitBZGQgYSB0ZXN0IHRo
YXQgbW9ja3Mgc210cGxpYi5TTVRQIGFuZCBhc3NlcnRzIHNlbmRfbWVzc2FnZSB3YXMgY2FsbGVk
LgorYGBgCisKK0ZvciAjNSwgbm90aWNlIHRoZSBhZ2VudCB3aWxsIG5lZWQgdG8gbWFrZSBvdXRi
b3VuZCBTTVRQIGNvbm5lY3Rpb25zIHRvCit2ZXJpZnkgYmVoYXZpb3VyIOKAlCBidXQgdGhlIGRl
ZmF1bHQgYEJhbGFuY2VkYCBwb2xpY3kgZG9lc24ndCBhbGxvdyBhcmJpdHJhcnkKK1NNVFAuIFRo
aXMgaXMgYSBnb29kIG1vbWVudCB0byByZXZpc2l0IE1vZHVsZSA1OiBlaXRoZXIgYWRkIGFuIGBh
bGxvd2AgcnVsZQorZm9yIHlvdXIgdGVzdCBTTVRQIGhvc3QsIG9yIGhhdmUgdGhlIGFnZW50IHJl
bHkgZW50aXJlbHkgb24gbW9ja2VkIHRyYW5zcG9ydAorYW5kIG5ldmVyIGFjdHVhbGx5IG9wZW4g
YSBzb2NrZXQuCisKKy0tLQorCisjIyDinIUgQ2hlY2twb2ludAorCitZb3UndmUgbm93IHJ1biB0
aGUgZnVsbCBzYW5kYm94IHdvcmtmbG93IGVuZC10by1lbmQ6CisKKy0gW3hdIFJlYWwgY29kZWJh
c2UgKERldkJvYXJkKSBydW5uaW5nIG9uIHRoZSBob3N0CistIFt4XSBSZWFsIGFnZW50IGluc2lk
ZSB0aGUgc2FuZGJveCwgcmVhZGluZyBhbmQgbW9kaWZ5aW5nIHNvdXJjZQorLSBbeF0gUmVhbCBm
aXggbGFuZGVkIG9uIGEgYnJhbmNoLCB3aXRoIGEgcGFzc2luZyB0ZXN0CistIFt4XSBSZXZpZXdl
ZCB0aGUgZGlmZiBiZWZvcmUgaXQgdG91Y2hlZCBtYWluCistIFt4XSBWZXJpZmllZCDigJQgdmlh
IGBzYnggbHNgIGFuZCB0aGUgbmV0d29yayBwYW5lbCDigJQgdGhhdCB0aGUgYWdlbnQgb25seQor
ICAgICAgcmVhY2hlZCB3aGF0IHRoZSBwb2xpY3kgYWxsb3dlZAorCitUaGF0J3MgdGhlIGNvbXBs
ZXRlIGxvb3AgdGhlIHJlc3Qgb2YgdGhpcyBsYWIgd2FzIGJ1aWxkaW5nIHRvd2FyZC4KZGlmZiAt
LWdpdCBhL2RvY3MvbGFiOC9wcm9qZWN0cy9wbGF5d3JpZ2h0LWJyb3dzZXItdGVzdGluZy5tZCBi
L2RvY3MvbGFiOC9wcm9qZWN0cy9wbGF5d3JpZ2h0LWJyb3dzZXItdGVzdGluZy5tZApkZWxldGVk
IGZpbGUgbW9kZSAxMDA2NDQKaW5kZXggZTY5ZGUyOWIuLjAwMDAwMDAwCmRpZmYgLS1naXQgYS9t
a2RvY3MueW1sIGIvbWtkb2NzLnltbAppbmRleCBmN2I2ZjY5NC4uMmQ1YzhhYjYgMTAwNjQ0Ci0t
LSBhL21rZG9jcy55bWwKKysrIGIvbWtkb2NzLnltbApAQCAtMTEzLDcgKzExMyw3IEBAIG5hdjoK
ICAgICAgICAgLSBSdW5uaW5nIE9wZW4tU291cmNlIE1vZGVsczogbGFiOC9wcm9qZWN0cy9sb2Nh
bC1tb2RlbHMubWQKICAgICAgICAgLSBBSSBHb3Zlcm5hbmNlIGF0IFNjYWxlOiBsYWI4L3Byb2pl
Y3RzL2dvdmVybmFuY2Utc3VtbWFyeS5tZAogICAgICAgLSBQcm9qZWN0czoKLSAgICAgICAgLSBQ
bGF5d3JpZ2h0IEJyb3dzZXIgVGVzdGluZzogbGFiOC9wcm9qZWN0cy9wbGF5d3JpZ2h0LWJyb3dz
ZXItdGVzdGluZy5tZAorICAgICAgICAtIERldkJvYXJkOiBsYWI4L3Byb2plY3RzL2RldmJvYXJk
Lm1kCiAgIC0gRG9ja2VyIGFuZCBTZWN1cml0eToKICAgICAtIERvY2tlciBIYXJkZW5lZCBJbWFn
ZXM6CiAgICAgICAtIE92ZXJ2aWV3OiBsYWI5L2RoaS9vdmVydmlldy5tZAo=
PATCH_B64_EOF

PATCH_SIZE=$(wc -c < "$PATCH_FILE")
echo "decoded patch: $PATCH_SIZE bytes"

echo "applying patch..."
if git apply --check "$PATCH_FILE" 2>/dev/null; then
  git apply --whitespace=nowarn "$PATCH_FILE"
else
  echo "patch doesn't apply cleanly. trying 3-way merge..." >&2
  git apply --3way --whitespace=nowarn "$PATCH_FILE"
fi

# ---------- verify (optional) ----------------------------------------------

if [[ "$BUILD" == "1" ]]; then
  if command -v mkdocs >/dev/null 2>&1; then
    echo "running mkdocs build to verify..."
    if mkdocs build --clean --site-dir /tmp/devboard-build-check >/dev/null 2>&1; then
      echo "  mkdocs build: OK"
      rm -rf /tmp/devboard-build-check
    else
      echo "  mkdocs build: FAILED — re-running to show output:" >&2
      mkdocs build --clean --site-dir /tmp/devboard-build-check
      exit 1
    fi
  else
    echo "skipping build check (mkdocs not installed). install with:" >&2
    echo "  pip install mkdocs mkdocs-material" >&2
  fi
fi

# ---------- commit ----------------------------------------------------------

git add -A

cat > "$MSG_FILE" <<'COMMIT_MSG_EOF'
Replace empty Playwright project with DevBoard end-to-end walkthrough

The Playwright Browser Testing entry under lab8/Projects pointed at an
empty file. Replacing it with DevBoard, the FastAPI + Next.js issue tracker
that the rest of the lab uses (cloned by Module 0 into ~/sbx-lab from
dockersamples/sbx-quickstart).

The new project page ties the lab's primitives (isolation, secrets,
network policy, branch mode) into a single end-to-end workflow:

- Boot DevBoard on the host
- Confirm one of the five documented intentional bugs (pagination off-by-one)
- Run the agent inside sbxlab in branch mode
- Brief it on the bug, watch it investigate and fix
- Verify with sbx ls + the network panel that nothing escaped the VM
- Review the diff on the host worktree, merge cleanly
- Suggested follow-ups for the other four bugs

Source: https://github.com/dockersamples/sbx-quickstart
COMMIT_MSG_EOF

git commit -F "$MSG_FILE"

echo
echo "committed on branch: $BRANCH"
git --no-pager log -1 --stat | head -25

# ---------- push and PR URL -------------------------------------------------

if [[ "$PUSH" == "1" ]]; then
  echo
  echo "pushing to $REMOTE..."
  git push -u "$REMOTE" "$BRANCH"

  REMOTE_URL="$(git remote get-url "$REMOTE")"
  REPO_PATH="$(echo "$REMOTE_URL" | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')"
  DEFAULT_BRANCH="$(git remote show "$REMOTE" 2>/dev/null | sed -n 's/.*HEAD branch: //p' | head -1)"
  if [[ -z "$DEFAULT_BRANCH" ]]; then DEFAULT_BRANCH="master"; fi

  echo
  echo "open this URL to create the PR:"
  echo "  https://github.com/$REPO_PATH/compare/$DEFAULT_BRANCH...$BRANCH?quick_pull=1"
  echo

  if command -v gh >/dev/null 2>&1; then
    echo "or run: gh pr create --fill --base $DEFAULT_BRANCH"
  fi
else
  echo
  echo "skipped push (--no-push). when ready:"
  echo "  git push -u $REMOTE $BRANCH"
fi

echo "done."
