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
      backgroundColor: const Color(0xFFEDEDED),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDEDED),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title, style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: TextButton(
                onPressed: _hasChanged
                    ? () => Navigator.pop(context, _controller.text)
                    : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '保存',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _hasChanged ? AppColors.primary : AppColors.textHint,
                  ),
                ),
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
              color: Colors.transparent, // Background of input area usually white? No, WeChat name edit is transparent with just a line but layout is specific. 
              // Actually image 2 shows: White background? No, looks like light gray #F2F2F2. The input line is green focused? 
              // Wait, image 3 ("更改名字") shows a white clean background or light gray.
              // Let's stick to standard input style:
              // TextField directly on the background with a line.
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                maxLength: widget.maxLength,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: '',
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF07C160)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF07C160), width: 2),
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel, color: Color(0xFFC7C7CC), size: 18),
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
                  style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
