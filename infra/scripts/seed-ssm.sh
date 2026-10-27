#!/usr/bin/env bash
# Seed AWS SSM Parameter Store for Hudaayah from a local, untracked params file.
#
# Usage:
#   cp infra/scripts/params.env.example infra/scripts/params.env   # then fill in values
#   ./infra/scripts/seed-ssm.sh                 # create/update params (prompts to overwrite)
#   ./infra/scripts/seed-ssm.sh --dry-run       # show what would happen, change nothing
#
# Env overrides:
#   AWS_REGION   (default: us-east-1)       must match var.aws_region
#   SSM_PREFIX   (default: /hudaayah/production)
#   PARAMS_FILE  (default: infra/scripts/params.env)
#   KMS_KEY_ID   (optional)                 custom KMS key for SecureString; default alias/aws/ssm
#
# The params file format is:  TYPE  NAME  VALUE   (see params.env.example)
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
SSM_PREFIX="${SSM_PREFIX:-/hudaayah/production}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARAMS_FILE="${PARAMS_FILE:-$SCRIPT_DIR/params.env}"
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

# --- Preflight ------------------------------------------------------------------
command -v aws >/dev/null 2>&1 || { echo "ERROR: aws CLI not found." >&2; exit 1; }

if [ ! -f "$PARAMS_FILE" ]; then
  echo "ERROR: params file not found: $PARAMS_FILE" >&2
  echo "       Copy the example and fill it in:" >&2
  echo "         cp $SCRIPT_DIR/params.env.example $PARAMS_FILE" >&2
  exit 1
fi

if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "ERROR: AWS credentials not working. Run 'aws sts get-caller-identity' to debug." >&2
  exit 1
fi

ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
echo "Account:  $ACCOUNT"
echo "Region:   $AWS_REGION"
echo "Prefix:   $SSM_PREFIX"
echo "File:     $PARAMS_FILE"
[ "$DRY_RUN" -eq 1 ] && echo "Mode:     DRY RUN (no changes)"
echo

put_count=0
skip_count=0

# --- Walk the params file -------------------------------------------------------
# Fields: TYPE NAME VALUE(rest of line). Value may contain spaces; not quoted.
while IFS= read -r line || [ -n "$line" ]; do
  # Strip leading whitespace; skip blanks and comments.
  trimmed="${line#"${line%%[![:space:]]*}"}"
  [ -z "$trimmed" ] && continue
  case "$trimmed" in \#*) continue ;; esac

  type="$(printf '%s' "$trimmed" | awk '{print $1}')"
  name="$(printf '%s' "$trimmed" | awk '{print $2}')"
  # Everything after the 2nd field is the value (preserve inner spaces).
  value="$(printf '%s' "$trimmed" | sed -E 's/^[[:space:]]*[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]*//')"

  if [ -z "$type" ] || [ -z "$name" ]; then
    echo "SKIP (malformed line): $line" >&2
    skip_count=$((skip_count + 1))
    continue
  fi

  if [ "$type" != "String" ] && [ "$type" != "SecureString" ]; then
    echo "SKIP ($name): unknown type '$type' (use String or SecureString)" >&2
    skip_count=$((skip_count + 1))
    continue
  fi

  # Auto-generate a Django secret key if left blank.
  if [ "$name" = "DJANGO_SECRET_KEY" ] && [ -z "$value" ]; then
    value="$(openssl rand -base64 48)"
    echo "  (generated DJANGO_SECRET_KEY)"
  fi

  if [ -z "$value" ]; then
    echo "SKIP ($name): empty value" >&2
    skip_count=$((skip_count + 1))
    continue
  fi

  full_name="$SSM_PREFIX/$name"

  # Redact SecureString values in output.
  if [ "$type" = "SecureString" ]; then
    shown="********"
  else
    shown="$value"
  fi

  if [ "$DRY_RUN" -eq 1 ]; then
    echo "PUT  $full_name  ($type) = $shown"
    put_count=$((put_count + 1))
    continue
  fi

  # Build args; --overwrite so re-runs update. KMS key only for SecureString.
  set -- --region "$AWS_REGION" --name "$full_name" --type "$type" \
         --value "$value" --overwrite
  if [ "$type" = "SecureString" ] && [ -n "${KMS_KEY_ID:-}" ]; then
    set -- "$@" --key-id "$KMS_KEY_ID"
  fi

  aws ssm put-parameter "$@" >/dev/null
  echo "PUT  $full_name  ($type) = $shown"
  put_count=$((put_count + 1))
done < "$PARAMS_FILE"

echo
echo "Done. $put_count parameter(s) processed, $skip_count skipped."
[ "$DRY_RUN" -eq 0 ] && cat <<EOF

Verify (names only):
  aws ssm get-parameters-by-path --region $AWS_REGION --path $SSM_PREFIX --recursive --query 'Parameters[].Name' --output text

Next: trigger a deploy (push to main or run the workflow) so the instance rebuilds
app.env from these parameters.
EOF
