import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zichat/constants/app_colors.dart';

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
    const Color bg = Color(0xFFEFEFF4);
    const Color primarySelectionColor = Color(0xFF07C160);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: SvgPicture.asset(
            'assets/icon/common/go-back.svg',
            width: 12,
            height: 20,
            colorFilter: const ColorFilter.mode(
              Color(0xFF1D2129),
              BlendMode.srcIn,
            ),
          ),
        ),
        title: const Text(
          '多语言',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D2129),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: TextButton(
              onPressed: _saveLanguage,
              style: TextButton.styleFrom(
                foregroundColor: primarySelectionColor,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('保存'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
           children: [
             for (int i = 0; i < _languages.length; i++)
               _LanguageItem(
                 label: _languages[i]['label']!,
                 isSelected: _languages[i]['code'] == _selectedLanguage,
                 onTap: () {
                   setState(() {
                     _selectedLanguage = _languages[i]['code']!;
                   });
                 },
               ),
           ],
        ),
      ),
    );
  }
}

class _LanguageItem extends StatelessWidget {
  const _LanguageItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFE5E6EB),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1D2129),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                color: Color(0xFF07C160),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
