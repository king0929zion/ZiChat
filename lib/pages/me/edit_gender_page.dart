import 'package:flutter/material.dart';
import 'package:zichat/constants/app_colors.dart';
import 'package:zichat/widgets/weui/weui.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('设置性别'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedGender),
            child: const Text(
              '完成',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8),
        children: [
          WeuiCellGroup(
            children: [
              _buildItem('男'),
              _buildItem('女'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(String gender) {
    final isSelected = gender == _selectedGender;
    return WeuiCell(
      title: gender,
      showArrow: false,
      trailing: isSelected
          ? const Icon(Icons.check, size: 20, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() => _selectedGender = gender);
      },
    );
  }
}
