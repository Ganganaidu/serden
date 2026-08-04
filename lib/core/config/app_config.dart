/// Central toggle for mock/sample data across the app.
///
/// When true, list screens show the hardcoded sample records (mockEstimates,
/// mockInvoices, mockClients, mockLeads, etc.) instead of a real user's
/// actual (currently empty, since those APIs aren't wired up yet) data —
/// useful for UI development without a live backend. Keep this false for
/// real usage: a real logged-in user must never see fake business records.
class AppConfig {
  AppConfig._();

  static const bool useMockData = false;
}
