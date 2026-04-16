// TRACKED TEMPLATE — safe to commit. Contains no real secrets.
//
// After cloning the repo:
//   1) Run:  ./tool/setup_supabase_env.sh
//      (or manually: cp lib/env/supabase_env_example.dart lib/env/supabase_env.dart)
//   2) Open lib/env/supabase_env.dart (gitignored) and paste your real URL + anon key
//      from Supabase Dashboard → Settings → API.
//
// supabase_env.dart must never be committed; it is listed in .gitignore.

const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
const String anthropicApiKey = 'YOUR_ANTHROPIC_API_KEY_HERE';
