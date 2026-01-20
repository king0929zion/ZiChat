import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zichat/constants/app_assets.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/constants/app_styles.dart';
import 'package:zichat/widgets/weui/weui.dart';

class SettingsLanguagePage extends StatefulWidget {
  const SettingsLanguagePage({super.key});

  @override
  State<SettingsLanguagePage> createState() => _SettingsLanguagePageState();
}

class _SettingsLanguagePageState extends State<SettingsLanguagePage> {
  static const String _languageKey = 'app_language';
  String _selectedLanguage = 'zh-CN'; // Default

  // Language code map, compatible with current implementation
  final List<Map<String, String>> _languages = [
    {'code': 'system', 'label': '跟随系统'},
    {'code': 'zh-CN', 'label': '简体中文'},
    {'code': 'zh-TW', 'label': '繁體中文（台灣）'},
    {'code': 'zh-HK', 'label': '繁體中文（香港）'},
    {'code': 'en', 'label': 'English'},
    {'code': 'id', 'label': 'Bahasa Indonesia'},
    {'code': 'ms', 'label': 'Bahasa Melayu'},
    {'code': 'es', 'label': 'Español'},
    {'code': 'ko', 'label': '한국어'},
    {'code': 'it', 'label': 'Italiano'},
    {'code': 'ja', 'label': '日本語'},
    {'code': 'pt', 'label': 'Português'},
    {'code': 'ru', 'label': 'Русский'},
    {'code': 'th', 'label': 'ภาษาไทย'},
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_languageKey) ?? 'zh-CN';
    if (mounted) {
      setState(() {
        _selectedLanguage = lang;
      });
    }
  }

  Future<void> _saveLanguage() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, _selectedLanguage);
    
    if (mounted) {
       Navigator.of(context).pop(_selectedLanguage);
       // In a real app, you might trigger an app restart or provider update here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: SvgPicture.asset(
            AppAssets.iconGoBack,
            width: 12,
            height: 20,
            colorFilter: const ColorFilter.mode(
              AppColors.textPrimary,
              BlendMode.srcIn,
            ),
          ),
        ),
        title: const Text('多语言'),
        centerTitle: true,
        actions: [
          TextButton(onPressed: _saveLanguage, child: const Text('保存')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        children: [
          WeuiCellGroup(
            children: [
              for (final lang in _languages)
                WeuiCell(
                  title: lang['label']!,
                  showArrow: false,
                  trailing: lang['code'] == _selectedLanguage
                      ? const Icon(Icons.check, size: 20, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedLanguage = lang['code']!;
                    });
                  },
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              '更改语言后可能需要重启应用才能完全生效。',
              style: AppStyles.caption.copyWith(color: AppColors.textHint),
            ),
          ),
        ],
      ),
    );
  }
}
