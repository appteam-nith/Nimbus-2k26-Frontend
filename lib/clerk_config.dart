/// Clerk publishable key — safe to commit, this is a CLIENT-SIDE public key.
///
/// Clerk intentionally makes this key "publishable" — it is visible in any
/// built APK/AAB and is harmless if seen. Never put CLERK_SECRET_KEY here;
/// the secret key lives only on the backend server in .env.
///
/// Get this from: Clerk Dashboard → API Keys → Publishable key (pk_...)
const String kClerkPublishableKey = String.fromEnvironment(
  'CLERK_PUBLISHABLE_KEY',
  // ↓ Paste your pk_test_... or pk_live_... key here for all builds.
  // It is safe to commit this value — it's a public key by design.
  defaultValue: 'pk_test_cG9ldGljLWRvcnktMTcuY2xlcmsuYWNjb3VudHMuZGV2JA',
);

/// True when a real key is present. Lets the app gracefully degrade
/// to the legacy JWT flow if the key is accidentally left as placeholder.
bool get clerkEnabled =>
    kClerkPublishableKey.startsWith('pk_') &&
    !kClerkPublishableKey.contains('PASTE_YOUR_KEY');
