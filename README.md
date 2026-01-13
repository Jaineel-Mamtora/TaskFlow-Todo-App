# TaskFlow - A Todo App

Stay in sync. Stay productive.

## Setup

1. Install Flutter SDK and platform tooling (Xcode for iOS, Android Studio for Android).
2. From the project root, fetch dependencies:

```sh
flutter pub get
```

3. Run the app on a device or simulator:

```sh
flutter run
```

## Assumptions and Design Decisions

- The app uses a local-first repository that treats the SQLite cache as the source of truth.
- Remote refresh merges only when local rows are not pending or deleted to avoid overwriting offline edits.
- Item ordering is kept stable during edits by preserving the original `updated_at` on updates.

## BLoC Pattern Overview

The UI subscribes to a single `TodosOverviewBloc` that:

- Listens to repository streams for local todo updates.
- Keeps filter/search state in-memory while deriving `visibleTodos`.
- Emits transient action states for add/update/toggle failures without replacing the list.

## Offline Support Strategy

- Todos are stored in SQLite with `pending_sync` and `deleted` flags.
- Mutations are optimistic: local DB is updated and an outbox operation is queued.
- When connectivity returns, outbox operations are coalesced and synced in order.
- UI stays responsive by listening to local DB changes and showing sync status updates.

## Challenges and Resolutions

- Initial offline launch could hang on a loading state; resolved by completing the initial refresh when offline.
- Avoiding list reordering on updates required preserving timestamps instead of bumping them.
- Sync UX required gating snackbars to only announce on offline-to-online transitions.

### Choosing a Local Database (sqflite vs Hive vs Isar vs Drift)

One of the most important decisions was selecting the local persistence solution.

#### Options considered

- **Hive**

  - Pros: Simple API, fast reads, minimal setup
  - Cons: Maintenance concerns, limited querying, weaker long-term confidence

- **Isar**

  - Pros: Modern, fast, reactive queries, strong offline support
  - Cons: Larger setup, code generation, heavier for MVP

- **Drift (SQLite wrapper)**

  - Pros: Strong typing, migrations, relational integrity
  - Cons: Significant boilerplate, slower iteration for MVP

- **sqflite (chosen)**
  - Pros:
    - Backed by SQLite (very stable and widely trusted)
    - Explicit control over schema, transactions, and sync logic
    - Ideal for implementing an outbox + optimistic updates
    - No code generation or heavy abstractions
  - Cons:
    - More manual SQL
    - No reactive queries out of the box

#### Final decision: **sqflite**

I chose **sqflite** because:

- Long-term stability and maintenance confidence mattered more than convenience
- Offline sync requires **explicit transactional control**
- The app’s data model (todos + outbox) fits naturally into relational tables
- It avoids dependency lock-in and keeps the data layer transparent

The lack of reactive queries was mitigated by BLoC managing state updates explicitly.

## Launcher Icons

To regenerate app launcher icons, run:

```sh
dart run flutter_launcher_icons
```
