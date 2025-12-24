import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String avatar;
  final String name;
  final String wechatId;
  final String gender;
  final String region;
  final String signature;

  const UserProfile({
    this.avatar = 'assets/me.png',
    this.name = 'Bella',
    this.wechatId = 'zion_guoguoguo',
    this.gender = '女',
    this.region = '中国',
    this.signature = '',
  });

  UserProfile copyWith({
    String? avatar,
    String? name,
    String? wechatId,
    String? gender,
    String? region,
    String? signature,
  }) {
    return UserProfile(
      avatar: avatar ?? this.avatar,
      name: name ?? this.name,
      wechatId: wechatId ?? this.wechatId,
      gender: gender ?? this.gender,
      region: region ?? this.region,
      signature: signature ?? this.signature,
    );
  }
}

class UserProfileStorage {
  static const String _keyAvatar = 'user_avatar';
  static const String _keyName = 'user_name';
  static const String _keyWechatId = 'user_wechat_id';
  static const String _keyGender = 'user_gender';
  static const String _keyRegion = 'user_region';
  static const String _keySignature = 'user_signature';

  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static UserProfile getProfile() {
    if (_prefs == null) return const UserProfile();
    return UserProfile(
      avatar: _prefs!.getString(_keyAvatar) ?? 'assets/me.png',
      name: _prefs!.getString(_keyName) ?? 'Bella',
      wechatId: _prefs!.getString(_keyWechatId) ?? 'zion_guoguoguo',
      gender: _prefs!.getString(_keyGender) ?? '女',
      region: _prefs!.getString(_keyRegion) ?? '中国',
      signature: _prefs!.getString(_keySignature) ?? '未填写',
    );
  }

  static Future<void> saveProfile(UserProfile profile) async {
    if (_prefs == null) await initialize();
    await _prefs!.setString(_keyAvatar, profile.avatar);
    await _prefs!.setString(_keyName, profile.name);
    await _prefs!.setString(_keyWechatId, profile.wechatId);
    await _prefs!.setString(_keyGender, profile.gender);
    await _prefs!.setString(_keyRegion, profile.region);
    await _prefs!.setString(_keySignature, profile.signature);
  }
  
  static Future<void> updateAvatar(String path) async {
    if (_prefs == null) await initialize();
    await _prefs!.setString(_keyAvatar, path);
  }

  static Future<void> updateName(String name) async {
    if (_prefs == null) await initialize();
    await _prefs!.setString(_keyName, name);
  }

    static Future<void> updateGender(String gender) async {
    if (_prefs == null) await initialize();
    await _prefs!.setString(_keyGender, gender);
  }

    static Future<void> updateSignature(String signature) async {
    if (_prefs == null) await initialize();
    await _prefs!.setString(_keySignature, signature);
  }
}
