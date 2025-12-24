import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zichat/constants/app_colors.dart';

/// 语言设置页面
class SettingsLanguagePage extends StatefulWidget {
  const SettingsLanguagePage({super.key});

  @override
  State<SettingsLanguagePage> createState() => _SettingsLanguagePageState();
}

class _SettingsLanguagePageState extends State<SettingsLanguagePage> {
  static const String _languageKey = 'app_language';
  String _currentLanguage = 'zh-CN';

  final Map<String, String> _languages = {
    'zh-CN': '简体中文',
    'en': 'English',
    'ja': '日本語',
    'ko': '한국어',
  };

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
        _currentLanguage = lang;
      });
    }
  }

  Future<void> _selectLanguage(String langCode) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, langCode);
    if (mounted) {
      setState(() {
        _currentLanguage = langCode;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已切换到 ${_languages[langCode]}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: SvgPicture.asset(
            'assets/icon/common/go-back.svg',
            width: 12,
            height: 20,
          ),
        ),
        title: const Text(
          '语言',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D2129),
          ),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ..._languages.entries.map((entry) {
            final isSelected = _currentLanguage == entry.key;
            return _buildLanguageTile(
              label: entry.value,
              selected: isSelected,
              onTap: () => _selectLanguage(entry.key),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLanguageTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            title: Text(
              label,
              style: TextStyle(
                fontSize: 17,
                color: selected ? AppColors.primary : const Color(0xFF1D2129),
              ),
            ),
            trailing: selected
                ? const Icon(
                    Icons.check,
                    color: Color(0xFF07C160),
                  )
                : null,
            onTap: onTap,
          ),
          const Divider(height: 0, indent: 16, color: Color(0xFFE5E6EB)),
        ],
      ),
    );
  }
}
