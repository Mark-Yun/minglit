/// The canonical "demo world" — IDs, timestamps, and cross-fixture FK
/// invariants. Every fixture references constants here so the entity graph
/// stays consistent (e.g., `Event.partner_id == demoWorld.selfPartnerId`).
///
/// **Skeleton frozen by Mark** — agents reference these constants. Agent
/// **P1-5** may extend (add more IDs as needed) but must NOT change existing
/// values once others have referenced them.
library;

/// Canonical IDs and timestamps for the demo world.
class DemoWorld {
  const DemoWorld._();

  // ── Identity ──────────────────────────────────────────────────────
  /// Supabase auth user ID for the demo user (auto-logged-in on boot).
  static const String userId = '00000000-0000-4000-8000-000000000001';

  /// Email for the demo user.
  static const String userEmail = 'demo@minglit.app';

  /// Phone (Korean format, fictional).
  static const String userPhone = '+82-10-0000-0001';

  // ── Partners ──────────────────────────────────────────────────────
  /// The partner store that demoUser owns (partner_app demo context).
  static const String selfPartnerId = '00000000-0000-4000-8000-100000000001';

  /// Additional partner IDs (for user_app browse). Public-facing partner
  /// detail pages reference these.
  static const String partner2Id = '00000000-0000-4000-8000-100000000002';
  static const String partner3Id = '00000000-0000-4000-8000-100000000003';
  static const String partner4Id = '00000000-0000-4000-8000-100000000004';
  static const String partner5Id = '00000000-0000-4000-8000-100000000005';

  // ── Parties (each Partner has 1-2 parties) ───────────────────────
  static const String selfParty1Id = '00000000-0000-4000-8000-200000000001';
  static const String selfParty2Id = '00000000-0000-4000-8000-200000000002';
  static const String partner2PartyId = '00000000-0000-4000-8000-200000000003';
  static const String partner3PartyId = '00000000-0000-4000-8000-200000000004';
  static const String partner4PartyId = '00000000-0000-4000-8000-200000000005';
  static const String partner5PartyId = '00000000-0000-4000-8000-200000000006';

  // ── Events (each Party has 1-3 events) ────────────────────────────
  static const String selfEvent1Id = '00000000-0000-4000-8000-300000000001';
  static const String selfEvent2Id = '00000000-0000-4000-8000-300000000002';
  static const String selfEvent3Id = '00000000-0000-4000-8000-300000000003';
  static const String partner2EventId = '00000000-0000-4000-8000-300000000004';
  static const String partner3EventId = '00000000-0000-4000-8000-300000000005';
  static const String partner4EventId = '00000000-0000-4000-8000-300000000006';
  static const String partner5EventId = '00000000-0000-4000-8000-300000000007';

  // ── Tickets (demoUser owns 3 — upcoming, past, used) ─────────────
  static const String ticket1Id = '00000000-0000-4000-8000-400000000001';
  static const String ticket2Id = '00000000-0000-4000-8000-400000000002';
  static const String ticket3Id = '00000000-0000-4000-8000-400000000003';

  // ── Time anchor ───────────────────────────────────────────────────
  /// Canonical "now" for deterministic captures. All relative timestamps
  /// (event start times, notification ages, etc.) derive from this.
  ///
  /// Note: this is a fixed wall-clock instant, NOT DateTime.now(). Demo
  /// captures must be reproducible.
  static final DateTime now = DateTime.utc(2026, 5, 18, 19, 0, 0);

  /// Helper: shift `now` by a duration. Convenient for fixture authoring.
  ///
  /// Example: `DemoWorld.offset(const Duration(days: -7))` → 1 week ago.
  static DateTime offset(Duration d) => now.add(d);
}

/// Singleton instance for ergonomic access: `demoWorld.userId` style.
const demoWorld = DemoWorld._();
