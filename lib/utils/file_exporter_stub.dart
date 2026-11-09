import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class FileExporter {
  static Future<void> saveBinaryFile({
    required BuildContext context,
    required String filename,
    required List<int> bytes,
    required String successMessage,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = io.File('${directory.path}/$filename');
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage.tr(namedArgs: {'path': file.path}))),
      );
    } catch (e) {
      final errorMsg = 'thesis.formExportError'.tr(args: [e.toString()]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }

  static Future<void> saveTextFile({
    required BuildContext context,
    required String filename,
    required String content,
    required String successMessage,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = io.File('${directory.path}/$filename');
      await file.writeAsString(content);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage.tr(namedArgs: {'path': file.path}))),
      );
    } catch (e) {
      final errorMsg = 'thesis.formExportError'.tr(args: [e.toString()]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }
}
