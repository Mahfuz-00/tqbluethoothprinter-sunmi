
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SunmiPosSdk {
  static const MethodChannel _channel = MethodChannel('SumniTalkingPOS');

  static Future<void> initSdk(BuildContext context) async {
    try {
      await _channel.invokeMethod('initializeSdk');
    } on PlatformException catch (e) {
      print("Failed to initialize SDK: '${e.message}'.");
    }
  }

  Future<bool> printReceipt(BuildContext context, String token, String time, String Category, List addtionalData) async {
    try {
      // Invoke the method channel to send the receipt data to the printer
      await _channel..invokeMethod('printReceipt', {
        'token': token,
        'time': time,
        'Category': Category,
        'addtionalData': addtionalData,
      });
      return true;
    } catch (e) {
      print("Failed to print receipt: $e");
      return false;
    }
  }

}