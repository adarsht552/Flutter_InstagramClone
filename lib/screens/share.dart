// share_logic.dart

import 'package:flutter_share/flutter_share.dart';

void shareContent(String imageUrl, String caption) async {
  try {
    await FlutterShare.shareFile(
      title: 'Share Post',
      text: caption.isNotEmpty ? '$caption\n$imageUrl' : imageUrl,
      filePath: imageUrl,
    );
  } catch (e) {
    // Handle sharing errors
    print('Error sharing: $e');
  }
}
