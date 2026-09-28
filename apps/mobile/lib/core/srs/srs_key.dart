/// Local SRS rows are keyed by card: an official card's id, or `u:<id>` for the student's own
/// cards (spec §13.7 keeps them in separate columns on the server).
abstract final class SrsKey {
  static const _user = 'u:';

  static String userCard(String id) => '$_user$id';
  static bool isUserCard(String key) => key.startsWith(_user);

  /// The server id behind a key.
  static String idOf(String key) => isUserCard(key) ? key.substring(_user.length) : key;
}
