import 'package:flutter/material.dart';
import 'package:zichat/constants/app_colors.dart';

class EditGenderPage extends StatefulWidget {
  const EditGenderPage({super.key, required this.initialGender});

  final String initialGender;

  @override
  State<EditGenderPage> createState() => _EditGenderPageState();
}

class _EditGenderPageState extends State<EditGenderPage> {
  late String _selectedGender;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.initialGender;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('设置性别', style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _selectedGender);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07C160),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text('完成', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 12),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildItem('男'),
            const Divider(height: 0.5, indent: 16, color: Color(0xFFE5E5E5)),
            _buildItem('女'),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(String gender) {
    final isSelected = gender == _selectedGender;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(gender, style: const TextStyle(fontSize: 16, color: Colors.black)),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check, color: Color(0xFF07C160), size: 18),
          ],
        ),
      ),
    );
  }
}
