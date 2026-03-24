# Story 1.1: Project Scaffolding & Supabase Setup

Status: ready-for-dev

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a developer,
I want the Flutter mobile app, Next.js web app, and Supabase backend initialized with the correct project structure and dependencies,
So that I have a working foundation to build features upon.

## Acceptance Criteria

1. **Given** no existing project repositories, **When** the developer initializes the projects, **Then** a Flutter project is created with the folder structure defined in the Architecture (`features/`, `core/`, `app/` directories)
2. **And** a Next.js 15 project is created with App Router, Tailwind CSS, and the folder structure from the Architecture
3. **And** a Supabase project is configured with PostgreSQL database
4. **And** the Flutter project includes all core dependencies from the Architecture (`supabase_flutter`, `flutter_riverpod`, `go_router`, `freezed`, `dio`, etc.)
5. **And** the Next.js project includes Supabase client, Zod, and Tailwind CSS dependencies
6. **And** Material 3 theming is configured in the Flutter app with light/dark color schemes
7. **And** `go_router` is set up with placeholder routes for the 4 main tabs (My Card, Scan, AI Notetaker, Contacts)
8. **And** Riverpod is initialized as the state management solution
9. **And** Sentry error tracking is integrated in both Flutter and Next.js projects
10. **And** the Supabase client singleton is configured in both Flutter and Next.js

## Tasks / Subtasks

- [ ] Task 1: Create Flutter project structure (AC: #1, #4)
  - [ ] 1.1 Initialize Flutter project (`biobiz_mobile`)
  - [ ] 1.2 Create folder structure: `lib/app/`, `lib/core/constants/`, `lib/core/models/`, `lib/core/services/`, `lib/core/providers/`, `lib/core/utils/`
  - [ ] 1.3 Create feature folders: `lib/features/onboarding/`, `lib/features/card_editor/`, `lib/features/card_view/`, `lib/features/sharing/`, `lib/features/scanner/`, `lib/features/ai_notetaker/`, `lib/features/contacts/`, `lib/features/premium/`, `lib/features/settings/`
  - [ ] 1.4 Create `screens/` and `widgets/` subdirectories in each feature folder
  - [ ] 1.5 Add all dependencies to `pubspec.yaml` (see Dev Notes for exact versions)
  - [ ] 1.6 Add all dev dependencies (`build_runner`, `freezed`, `json_serializable`, `riverpod_generator`, `flutter_lints`, `mockito`)
  - [ ] 1.7 Configure `analysis_options.yaml` with lint rules
  - [ ] 1.8 Create `build.yaml` for build_runner config
  - [ ] 1.9 Run `flutter pub get` to verify all dependencies resolve

- [ ] Task 2: Configure Material 3 theming (AC: #6)
  - [ ] 2.1 Create `lib/app/theme.dart` with `AppTheme` class containing `light()` and `dark()` static methods
  - [ ] 2.2 Use `ColorScheme.fromSeed()` with brand primary color for both light and dark schemes
  - [ ] 2.3 Create `lib/core/constants/color_presets.dart` with 7+ card color presets (black, red, orange, yellow, gold, green, blue)
  - [ ] 2.4 Create `lib/core/constants/app_constants.dart` with free/premium limits

- [ ] Task 3: Set up go_router with placeholder routes (AC: #7)
  - [ ] 3.1 Create `lib/app/router.dart` with `GoRouter` configuration
  - [ ] 3.2 Define routes for 4 main tabs: `/my-card`, `/scan`, `/ai-notetaker`, `/contacts`
  - [ ] 3.3 Create placeholder screens for each tab with proper naming
  - [ ] 3.4 Set up bottom `NavigationBar` shell route with 4 tabs
  - [ ] 3.5 Add onboarding route group (`/onboarding/*`)
  - [ ] 3.6 Add settings route (`/settings`)

- [ ] Task 4: Initialize Riverpod (AC: #8)
  - [ ] 4.1 Wrap app in `ProviderScope` in `main.dart`
  - [ ] 4.2 Create `lib/app/app.dart` with `MaterialApp.router` setup including theme, darkTheme, themeMode, and router

- [ ] Task 5: Configure Supabase client singleton (AC: #3, #10)
  - [ ] 5.1 Create `lib/core/services/supabase_service.dart` with Supabase client initialization
  - [ ] 5.2 Initialize Supabase in `main.dart` before `runApp()`
  - [ ] 5.3 Create `.env.example` with placeholder Supabase URL and anon key (DO NOT commit actual keys)
  - [ ] 5.4 Configure environment variable loading for Supabase credentials

- [ ] Task 6: Integrate Sentry error tracking in Flutter (AC: #9)
  - [ ] 6.1 Add `sentry_flutter` initialization in `main.dart`
  - [ ] 6.2 Configure Sentry DSN via environment variable
  - [ ] 6.3 Wrap app in `SentryNavigatorObserver` for automatic route tracking

- [ ] Task 7: Create Next.js project (AC: #2, #5)
  - [ ] 7.1 Initialize Next.js 15 project with App Router (`biobiz_web`)
  - [ ] 7.2 Install and configure Tailwind CSS
  - [ ] 7.3 Create folder structure: `app/card/[slug]/`, `app/api/cards/`, `app/api/contacts/`, `app/api/shares/`, `app/api/recordings/`, `app/api/subscription/`, `app/api/utils/`, `components/`, `lib/`
  - [ ] 7.4 Install dependencies: `@supabase/supabase-js`, `zod`, `qrcode`
  - [ ] 7.5 Create `lib/supabase.ts` with Supabase server client singleton
  - [ ] 7.6 Create placeholder `app/card/[slug]/page.tsx` with basic SSR card viewer
  - [ ] 7.7 Configure `next.config.js` and `tailwind.config.ts`

- [ ] Task 8: Integrate Sentry in Next.js (AC: #9)
  - [ ] 8.1 Install `@sentry/nextjs`
  - [ ] 8.2 Configure Sentry for Next.js (sentry.client.config.ts, sentry.server.config.ts, sentry.edge.config.ts)
  - [ ] 8.3 Add Sentry DSN to environment variables

- [ ] Task 9: Set up Supabase project structure (AC: #3)
  - [ ] 9.1 Create `biobiz_supabase/` directory with `migrations/`, `functions/`, `seed.sql`
  - [ ] 9.2 Create `config.toml` for Supabase project configuration
  - [ ] 9.3 Create initial migration file with the `profiles` table, `set_updated_at()` trigger function, and `profiles` trigger (tables needed for Story 1.2+)
  - [ ] 9.4 Enable RLS on `profiles` table with owner policies
  - [ ] 9.5 Add `.env.example` with Supabase project URL, anon key, and service role key placeholders

- [ ] Task 10: Verify integration (AC: all)
  - [ ] 10.1 Verify Flutter project builds successfully (`flutter build apk --debug` or `flutter run`)
  - [ ] 10.2 Verify Next.js project builds (`npm run build`)
  - [ ] 10.3 Verify placeholder routes render correctly in Flutter app
  - [ ] 10.4 Verify Supabase client initializes without errors in both projects

## Dev Notes

### Architecture Compliance

- **Multi-repo architecture**: Three separate project directories: `biobiz_mobile/` (Flutter), `biobiz_web/` (Next.js), `biobiz_supabase/` (migrations + edge functions)
- **Flutter state management**: MUST use `flutter_riverpod` with code generation (`riverpod_annotation` + `riverpod_generator`). Do NOT use Provider, BLoC, or other state management solutions
- **Navigation**: MUST use `go_router` with declarative routing. Do NOT use Navigator 2.0 directly
- **Data models**: MUST use `freezed` + `json_serializable` for all data classes. Do NOT create plain Dart classes for models
- **HTTP client**: `dio` is ONLY for Next.js API calls (AI processing, logo detection, email sending, webhooks). All Supabase operations (auth, database CRUD, storage, realtime) go through `supabase_flutter` SDK directly
- **Dark mode**: App shell follows system theme via `ThemeMode.system`. Card renderer is independent and uses card's own colors (see Architecture Section 19)

### Flutter Dependencies (Exact Versions from Architecture)

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  go_router: ^14.0.0
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  dio: ^5.4.0
  flutter_secure_storage: ^9.2.0
  hive_flutter: ^1.1.0
  qr_flutter: ^4.1.0
  cached_network_image: ^3.3.0
  share_plus: ^9.0.0
  url_launcher: ^6.3.0
  permission_handler: ^11.3.0
  connectivity_plus: ^6.0.0
  sentry_flutter: ^8.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  flutter_lints: ^4.0.0
  mockito: ^5.4.0
```

> **Note**: Camera, scanner, NFC, location, audio, image picker, Firebase, home_widget, and RevenueCat packages are NOT needed for Story 1.1. Only include the core scaffolding packages listed above. Additional packages will be added in their respective stories.

### Next.js Dependencies

```json
{
  "dependencies": {
    "@supabase/supabase-js": "latest",
    "@supabase/ssr": "latest",
    "zod": "latest",
    "qrcode": "latest"
  },
  "devDependencies": {
    "@sentry/nextjs": "latest"
  }
}
```

### Theme Configuration Reference

```dart
// lib/app/theme.dart
class AppTheme {
  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: Brightness.light,
    ),
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: Brightness.dark,
    ),
  );
}

// lib/app/app.dart
MaterialApp.router(
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: ThemeMode.system,
  routerConfig: appRouter,
)
```

### Initial Database Migration (profiles table only for this story)

```sql
-- Only create the profiles table and supporting infrastructure
-- Full schema will be added in subsequent stories as needed

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT NOT NULL,
  last_name TEXT,
  email TEXT,
  phone TEXT,
  avatar_url TEXT,
  onboarding_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
```

### Project Structure (from Architecture Section 2.6)

**Flutter Mobile App (`biobiz_mobile/`):**
```
lib/
├── main.dart
├── app/
│   ├── app.dart          # MaterialApp + theme + router
│   ├── router.dart       # go_router configuration
│   └── theme.dart        # Material 3 theme + color schemes
├── core/
│   ├── constants/
│   │   ├── color_presets.dart
│   │   └── app_constants.dart
│   ├── models/           # (empty - populated in later stories)
│   ├── services/
│   │   └── supabase_service.dart
│   ├── providers/        # (empty - populated in later stories)
│   └── utils/            # (empty - populated in later stories)
└── features/
    ├── onboarding/screens/ & widgets/
    ├── card_editor/screens/ & widgets/
    ├── card_view/screens/ & widgets/
    ├── sharing/screens/ & widgets/
    ├── scanner/screens/ & widgets/
    ├── ai_notetaker/screens/ & widgets/
    ├── contacts/screens/ & widgets/
    ├── premium/screens/ & widgets/
    └── settings/screens/
```

**Next.js Web App (`biobiz_web/`):**
```
app/
├── card/[slug]/page.tsx   # Public card viewer (SSR)
├── api/
│   ├── cards/
│   ├── contacts/
│   ├── shares/
│   ├── recordings/
│   ├── subscription/
│   └── utils/
└── dashboard/             # Future admin dashboard
components/
lib/
└── supabase.ts            # Supabase server client
```

**Supabase (`biobiz_supabase/`):**
```
migrations/
├── 001_initial_schema.sql  # profiles table + RLS + triggers
functions/                   # Edge functions (future)
seed.sql
config.toml
```

### Security Considerations

- NEVER commit real Supabase credentials, Sentry DSNs, or API keys to the repository
- Use `.env` files with `.gitignore` exclusion
- Provide `.env.example` files with placeholder values
- Supabase anon key is safe for client-side use (RLS protects data)
- Service role key must ONLY be used server-side (Next.js API routes)

### UX Notes

- Bottom navigation uses 4 tabs: My Card, Scan, AI Notes, Contacts
- Active tab: filled icon + label. Inactive tabs: outline icon only
- Material 3 `NavigationBar` component (not `BottomNavigationBar`)
- Navigation bar adapts to light/dark theme automatically

### Testing Standards

- Flutter: Use `flutter_test` for widget and unit tests
- Next.js: Standard Jest/Vitest setup
- For this story: Ensure project builds and placeholder screens render. No feature tests needed yet

### Project Structure Notes

- All three projects (`biobiz_mobile`, `biobiz_web`, `biobiz_supabase`) live as sibling directories under the project root
- Each has its own `.gitignore` and `.env.example`
- Shared Supabase backend means both Flutter and Next.js use the same project URL and keys

### References

- [Source: _bmad-output/technical-architecture-biobiz/1-architecture-overview.md] - System architecture diagram
- [Source: _bmad-output/technical-architecture-biobiz/2-tech-stack.md#2.6] - Project structure and folder organization
- [Source: _bmad-output/technical-architecture-biobiz/11-key-flutter-packages-pubspecyaml.md] - Flutter dependency versions
- [Source: _bmad-output/technical-architecture-biobiz/3-database-schema.md#3.2] - Database tables and RLS policies
- [Source: _bmad-output/technical-architecture-biobiz/19-dark-mode-architecture.md] - Theme configuration and dark mode strategy
- [Source: _bmad-output/planning-artifacts/ux-design-specification.md] - Navigation patterns, button hierarchy, component strategy
- [Source: _bmad-output/prd-biobiz-blinq-clone/4-non-functional-requirements.md] - Security and performance requirements
- [Source: _bmad-output/planning-artifacts/epics.md#Story 1.1] - Story requirements and acceptance criteria

## Dev Agent Record

### Agent Model Used

<!-- To be filled by dev agent -->

### Debug Log References

### Completion Notes List

### File List
