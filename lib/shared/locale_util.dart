/// 语言工具：判断当前界面语言，用于选择双语内容。
library;

import 'package:flutter/widgets.dart';

/// 当前解析后的界面语言是否为中文。
bool isZhUi(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'zh';

/// 依界面语言在「英文 / 中文」之间选择。
String pickLang(BuildContext context, String en, String zh) =>
    isZhUi(context) ? zh : en;
