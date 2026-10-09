#!/bin/sh
set -eu

usage() {
  echo "Usage: $0 [pier]"
  echo "Copies desk/ into the mounted omart/ of a pier."
  echo "Default pier: \$HOME/urbit/zod"
  echo "Example: $0"
  echo "         $0 /home/ahlmark/urbit/zod"
  exit 1
}

case "${1:-}" in
  -h|--help) usage ;;
esac

PIER=${1:-"$HOME/urbit/zod"}

if [ ! -d "$PIER/omart" ]; then
  echo "No omart/ in $PIER — |new-desk %omart then |mount %omart, then retry."
  exit 1
fi

REPO=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DESK="$REPO/desk"

if [ ! -f "$DESK/app/omart.hoon" ]; then
  echo "Missing $DESK/app/omart.hoon"
  exit 1
fi

# Remove only the retired transport files that earlier releases installed.
rm -f "$PIER/omart/lib/gossip.hoon" "$PIER/omart/mar/gossip/rumor.hoon"
cp -R "$DESK/lib" "$DESK/sur" "$DESK/mar" "$DESK/gen" "$PIER/omart/"
mkdir -p "$PIER/omart/app"
cp "$DESK/app/omart.hoon" "$PIER/omart/app/"
cp "$DESK/desk.bill" "$PIER/omart/"
if [ -d "$DESK/web" ]; then
  rm -rf "$PIER/omart/web"
  cp -R "$DESK/web" "$PIER/omart/web"
fi
if [ -f "$DESK/sys.kelvin" ]; then
  echo "Not copying sys.kelvin (keep the pier's)."
fi
cp "$DESK/desk.docket-0" "$PIER/omart/" 2>/dev/null || true

missing=
for f in default-agent.hoon dbug.hoon verb.hoon skeleton.hoon server.hoon; do
  if [ -f "$PIER/base/lib/$f" ]; then
    cp "$PIER/base/lib/$f" "$PIER/omart/lib/"
  else
    missing="$missing lib/$f"
  fi
done
for f in bill.hoon mime.hoon json.hoon; do
  if [ -f "$PIER/base/mar/$f" ]; then
    cp "$PIER/base/mar/$f" "$PIER/omart/mar/"
  else
    missing="$missing mar/$f"
  fi
done
if [ -f "$PIER/base/sur/verb.hoon" ]; then
  cp "$PIER/base/sur/verb.hoon" "$PIER/omart/sur/"
else
  missing="$missing sur/verb.hoon"
fi

if [ -n "$missing" ]; then
  echo "Copied omart files, but missing %base libs:$missing"
  echo "In the dojo run  |mount %base  then run this script again."
  exit 1
fi

echo "Copied into $PIER/omart"
echo "In the dojo:"
echo "  |commit %omart"
echo "  |install our %omart"
