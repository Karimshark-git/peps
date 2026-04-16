#!/usr/bin/env bash
# Creates lib/env/supabase_env.dart from the tracked example (safe to commit this script).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="$ROOT/lib/env/supabase_env.dart"
EXAMPLE="$ROOT/lib/env/supabase_env_example.dart"

if [[ -f "$TARGET" ]]; then
  echo "Already exists: lib/env/supabase_env.dart"
  echo "Edit that file and paste your Supabase URL and anon key."
  exit 0
fi

cp "$EXAMPLE" "$TARGET"
echo "Created lib/env/supabase_env.dart (gitignored — never commit it)."
echo "Open the file and replace the two placeholder strings with your Supabase credentials."
