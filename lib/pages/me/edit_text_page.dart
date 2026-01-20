import 'package:flutter/material.dart';

import 'package:zichat/constants/app_colors.dart';

class EditTextPage extends StatefulWidget {
  const EditTextPage({
    super.key,
    required this.title,
    required this.initialValue,
    this.maxLength = 30,
    this.description = '',
  });

  final String title;
  final String initialValue;
  final int maxLength;
  final String description;

  @override
  State<EditTextPage> createState() => _EditTextPageState();
}

class _EditTextPageState extends State<EditTextPage> {
  late TextEditingController _controller;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.addListener(() {
      setState(() {
        _hasChanged = _controller.text != widget.initialValue;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed:
                _hasChanged ? () => Navigator.pop(context, _controller.text) : null,
            child: Text(
              '保存',
              style: TextStyle(
                color: _hasChanged ? AppColors.primary : AppColors.textDisabled,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                maxLength: widget.maxLength,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: '',
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.cancel,
                            color: AppColors.textHint,
                            size: 18,
                          ),
                          onPressed: () => _controller.clear(),
                        )
                      : null,
                ),
              ),
            ),
             if (widget.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.description,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
