/// Settings fot the whole application.
///
/// This may gonna implement to database.
class AppSettings {
  /// The current client
  static ClientType currentClient = ClientType.Yande;

  /// The height of post in the post list
  static const double fixedPostHeight = 256.0;

  /// The first day that yande has datas
  static DateTime yandeFirstday = DateTime(2006, 9);

  /// The first day that konanchan has datas
  static DateTime konachanFirstday = DateTime(2008, 2);

  /// Photo save location
  static String savePath = "D:/";

  /// Post limit for post and search
  static double postLimit = 50;

  static String token =
      "password_hash=9b86532bf85edf67fbc5c96561c178edaefc6d37&login=yande_loli";

  /// Return the current client `url`
  static String get currentBaseUrl {
    switch (currentClient) {
      case ClientType.Yande:
        return "https://yande.re";
        break;
      case ClientType.Konachan:
        return "https://konachan.com";
        break;
      default:
        return null;
        break;
    }
  }
}

/// Indicate a booru client type
enum ClientType { Yande, Konachan }
