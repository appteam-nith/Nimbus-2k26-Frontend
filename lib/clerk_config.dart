/// Clerk publishable key — must match CLERK_PUBLISHABLE_KEY in backend .env
///
/// For local dev, copy the pk_test_... value from the backend .env file.
/// For CI/CD, pass via --dart-define=CLERK_PUBLISHABLE_KEY=pk_...
const String kClerkPublishableKey = String.fromEnvironment(
  'CLERK_PUBLISHABLE_KEY',
  // Fallback: paste your pk_test_... key here for local development
  defaultValue: 'pk_test_REPLACE_WITH_YOUR_CLERK_PUBLISHABLE_KEY',
);
