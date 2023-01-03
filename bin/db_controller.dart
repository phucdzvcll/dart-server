import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:mysql1/mysql1.dart';

class DBController {
  late MySqlConnection _connection;

  Future<MySqlConnection> init() async {
    Map<String, String> envVars = Platform.environment;

    var sqlHost = envVars['MYSQL_HOSTS'] ?? 'localhost';
    var sqlPort = int.parse(envVars['MYSQL_PORT'] ?? '3306');
    var dbPassword = envVars['MYSQL_PASS'] ?? '1';
    var dbName = envVars['MYSQL_DB_NAME'] ?? 'mydb';
    var dbUser = envVars['MYSQL_USER'] ?? 'root';
    final settings = ConnectionSettings(
      port: sqlPort,
      password: dbPassword,
      db: dbName,
      user: dbUser,
      host: sqlHost,
    );
    _connection = await MySqlConnection.connect(settings);

    await _connection.query(
        'CREATE TABLE if not exists ShortenUrl (RawUrl varchar(255) NOT NULL, ShortUrl varchar(255) NOT NULL Primary key);');

    return _connection;
  }

  Future<String?> insertShortUrl(String rawUrl) async {
    var shortUrl = hashUrl(rawUrl);

    var scrip = "INSERT INTO  ShortenUrl (RawUrl, ShortUrl) VALUES  (? , ?);";
    await _connection.query(scrip, [rawUrl, shortUrl]);
    return shortUrl;
  }

  Future<String?> getRawUrl(String shortUrl) async {
    var scrip = "Select RawUrl from ShortenUrl where ShortUrl = ? ;";
    final results = await _connection.query(scrip, [shortUrl]);
    if (results.isNotEmpty) {
      return results.first[0];
    } else {
      return null;
    }
  }

  String hashUrl(String url) {
    var bytes = utf8.encode(url);
    Digest digest = md5.convert(bytes);

    return digest.toString();
  }
}
