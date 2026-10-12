# paraspa

Flutter client for the paraspa Spring Boot backend — a community
skill-exchange app: list skills you teach and want to learn, match with
complementary people, request a swap, schedule sessions, chat, and rate each
other.

- Dart package / bundle ID: `paraspa` / `com.paraspa.paraspa`
- Targets: Android, iOS, macOS, Windows, Linux, web

## Screens

| Area | Screen | Route |
|---|---|---|
| Onboarding | Welcome (animated orbit + headline) | `/welcome` |
| | Log in / Sign up (one screen, two tabs) | `/login`, `/register` |
| Discover | Matches: top mutual match, "For you" / "Best matches" | `/matches` |
| | Match profile: swap card, ratings, availability, latest review | `/matches/:userId` |
| | Request a swap (sheet + success state) | `/matches/:userId/request` |
| Search | Search with category chips and filters | `/search` |
| Swaps | Exchanges: next-session banner, Incoming / Sent / All | `/requests` |
| | Exchange detail: sessions list + schedule form | `/requests/:id` |
| | Session detail: join link, reschedule card, history | `/sessions/:id` |
| | Propose new time | `/sessions/:id/reschedule` |
| | Rate your partner | `/sessions/:id/rate` |
| Chats | Inbox | `/messages` |
| | Chat (REST history + WebSocket) | `/messages/:userId` |
| Me | Profile: stats, skills, availability, account | `/profile` |
| | Edit profile, change password, add skill, availability | `/profile/...` |
| | Reputation (reviews received) | `/users/:userId/ratings` |

## Architecture

- **Networking**: `dio`, with an interceptor (`lib/core/network/dio_client.dart`)
  that attaches the JWT to every request and forces logout on a 401.
- **State management**: Riverpod (`flutter_riverpod`). Repositories are plain
  Dio wrappers (`lib/repositories`); screens read `FutureProvider`s
  (`lib/providers`) and invalidate them after mutations to refetch.
- **Models**: `freezed` + `json_serializable` (`lib/models`). Enums
  (`lib/core/utils/enums.dart`) are hardcoded to match the backend's wire
  strings (e.g. `SkillCategory.tech.wire == 'TECH'`).
- **Auth**: JWT stored in `flutter_secure_storage`
  (`lib/core/storage/secure_storage_service.dart`). There is no refresh-token
  endpoint, so token expiry (default 24h) is handled purely by the 401 hook
  routing back to the welcome/login screens.
- **Routing**: `go_router` with a `StatefulShellRoute` for the five floating
  bottom-nav tabs (Discover, Search, Swaps, Chats, Me) and a redirect based on
  `authProvider`'s state (`lib/core/router/app_router.dart`). Unauthenticated
  users land on `/welcome`; detail screens (match, request, exchange, session,
  chat, rate) are pushed on the root navigator so they show a back button
  instead of the nav.

## Design system

Built from the mobile UI spec on a 390 × 844 frame (values are logical points).

- **Tokens** — `lib/core/theme`: `AppColors` (ink / paper / lime accent and the
  pastel avatar fills), `AppText` (typographic roles), `AppTheme` (Material
  theme plus `AppSpacing` / `AppRadius`). Single light theme.
- **Fonts** — Bricolage Grotesque (display) and DM Sans (UI), bundled in
  `assets/fonts` so typography works offline.
- **Widgets** — `lib/core/widgets`: `BrandMark` (the "Overlap" logo),
  `SwapAvatar`, `PrimaryButton` / `SecondaryButton` / `IconSquareButton`,
  `SegmentedTabs`, `StatusPill` / `SkillTag` / `FilterChipPill`, `AppCard`,
  `LabeledField`, `DayPicker`, `StickyActionBar`, `SubPage`, `PopIn`, and
  `StarText` (DM Sans has no ★ glyph, so stars are drawn as icons).
- **Motion** — Welcome orbits, pulse and headline swap, success "pop", and tab
  transitions. Orbits and pulses stop when the OS asks to reduce motion.
- **Icons** — Material rounded/outlined icons; the swap glyph is custom.

## API gaps the UI works around

- No distance, online presence or avatars in the API, so those parts of the
  design are omitted (cards show city and rating instead).
- `GET /users/search` has no category filter; the category chips search each
  skill in the category and merge the results client-side.
- Ratings only accept stars + text, so the quick tags on the rate screen are
  sent as a prefix on the review text.

## Note on `/matches` response shape

The API spec handed to this client didn't document the exact JSON shape of
`GET /matches` / `/matches/mutual` / `/matches/{userId}`. `MatchResult`
(`lib/models/match_result.dart`) parses defensively, trying several likely
field-name variants and degrading to empty lists rather than throwing.

Confirmed against a running backend instance, the actual keys are:

```json
{
  "user": { "id": 6, "name": "...", "email": "...", "bio": null, "city": null,
            "averageRating": null, "totalRatings": null },
  "theyCanTeachMe": [ { "id": 24, "name": "...", "category": "...", "description": null } ],
  "iCanTeachThem":  [ { "id": 25, "name": "...", "category": "...", "description": null } ],
  "isMutual": true
}
```

`theyCanTeachMe` and `iCanTeachThem` are tried first in `MatchResult.fromJson`,
with the earlier guessed variants (`skillsTheyCanTeachYou`, `theyTeach`,
`canTeachYou`, etc.) kept as fallbacks in case the backend shape changes
again. If parsing ever silently degrades to empty lists (e.g. dropdowns on
the send-request screen showing "No listed skills to choose from" for a
match that clearly has overlapping skills), re-check this shape against the
live backend and update the `_firstOf` key lists in `match_result.dart`
rather than guessing further.

Similarly `RatingSummary.fromJson` (`lib/models/rating.dart`) tries a few
common key names (`averageRating`/`averageStars`/`average`, etc.) for
`GET /users/{userId}/rating-summary`.

## Running

The backend's CORS only allows `localhost:3000`/`8080`, which only matters
for a Flutter *web* build — mobile/desktop builds aren't subject to CORS.
`flutter_secure_storage` can also throw on web after a page reload, so use
mobile or desktop for day-to-day development.

```bash
flutter pub get

# Regenerate model code after changing anything under lib/models
dart run build_runner build --delete-conflicting-outputs

flutter run
```

`ApiConstants.baseUrl` (`lib/core/network/api_constants.dart`) picks a sane
default per platform with no flags needed: `http://10.0.2.2:8080/api` on the
Android emulator (the only target where plain `localhost` doesn't reach the
host machine), `http://localhost:8080/api` everywhere else (iOS simulator,
macOS/Windows/Linux desktop, web). For a physical device on the same
network as the backend, override it explicitly:

```bash
flutter run --dart-define=API_BASE_URL=http://<your-lan-ip>:8080/api
```
