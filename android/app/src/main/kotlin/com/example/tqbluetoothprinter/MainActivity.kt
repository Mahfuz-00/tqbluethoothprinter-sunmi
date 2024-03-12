package com.example.tqbluetoothprinter

import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import android.text.Layout
import android.util.Log
import com.zcs.sdk.DriverManager
import com.zcs.sdk.Printer
import com.zcs.sdk.SdkResult
import com.zcs.sdk.Sys
import com.zcs.sdk.print.PrnStrFormat
import com.zcs.sdk.print.PrnTextFont
import com.zcs.sdk.print.PrnTextStyle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant


class MainActivity : FlutterActivity() {
    private var CHANNEL = "ZCSPOSSDK"
    private var mDriverManager: DriverManager = DriverManager.getInstance();
    private var mSys: Sys = mDriverManager.getBaseSysDevice();
    private var mPrinter: Printer = mDriverManager.getPrinter();
    private var isSdkInitialized = false
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        //super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)



        var methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ZCSPOSSDK")
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeSdk" -> {
                    // Handle initialization method call
                    var success = initializeSdk()
                    result.success(success)
                }
                "printReceipt" -> {
                    // Handle print receipt method call
                    var token = call.argument<String>("token")
                    var time = call.argument<String>("time")
                    var nameEn = call.argument<String>("nameEn")
                    var nameBn = call.argument<String>("nameBn")
                    var companyName = call.argument<String>("companyName")
                    var success = printReceipt(token, time, nameEn, nameBn, companyName)
                    result.success(success)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun initializeSdk(): Boolean {
        try {
            var status: Int = mSys!!.sdkInit()
            if (status != SdkResult.SDK_OK) {
                mSys!!.sysPowerOn()
                Thread.sleep(1000)
                status = mSys!!.sdkInit()
                if (status != SdkResult.SDK_OK) {
                    Log.e("SDK Initialization", "Failed to initialize SDK")
                    return false
                }
            }
            isSdkInitialized = true
            return true
        } catch (e: Exception) {
            Log.e("SDK Initialization", "Failed to initialize SDK", e)
            return false
        }
    }

    private fun printReceipt(token: String?, time: String?, nameEn: String?, nameBn: String?, companyName: String?): Boolean {
        try {
            var printStatus: Int = mPrinter!!.getPrinterStatus()
            if (printStatus == SdkResult.SDK_PRN_STATUS_PAPEROUT) {
                return false
            } else {
                val format = PrnStrFormat()
                format.setTextSize(50);
                format.setAli(Layout.Alignment.ALIGN_CENTER);
                format.setStyle(PrnTextStyle.BOLD);
                format.setFont(PrnTextFont.CUSTOM);
                mPrinter!!.setPrintAppendString("$companyName", format);
                format.setTextSize(100);
                format.setAli(Layout.Alignment.ALIGN_CENTER);
                format.setStyle(PrnTextStyle.BOLD);
                format.setFont(PrnTextFont.CUSTOM);
                mPrinter!!.setPrintAppendString(token, format);
                format.setTextSize(30);
                format.setAli(Layout.Alignment.ALIGN_CENTER);
                format.setStyle(PrnTextStyle.BOLD);
                format.setFont(PrnTextFont.CUSTOM);
                mPrinter!!.setPrintAppendString(time, format);
                format.setTextSize(30);
                format.setAli(Layout.Alignment.ALIGN_CENTER);
                format.setStyle(PrnTextStyle.BOLD);
                format.setFont(PrnTextFont.CUSTOM);
                mPrinter!!.setPrintAppendString("$nameEn  $nameBn", format);
                format.setTextSize(25);
                format.setAli(Layout.Alignment.ALIGN_CENTER);
                format.setStyle(PrnTextStyle.BOLD);
                format.setFont(PrnTextFont.CUSTOM);
                mPrinter!!.setPrintAppendString("Developed by Touch and Solve",format);
                mPrinter.setPrintAppendString(" ", format);
                mPrinter.setPrintAppendString(" ", format);
                mPrinter!!.setPrintAppendString("Thank You",format);
                mPrinter.setPrintAppendString(" ", format);
                mPrinter.setPrintAppendString(" ", format);
                cutPaper()
                mPrinter.setPrintAppendString(" ", format);
                mPrinter.setPrintAppendString(" ", format);
                // Add more receipt content if needed...

                printStatus = mPrinter!!.setPrintStart();
                if (printStatus == SdkResult.SDK_OK) {
                    GlobalScope.launch {
                        delay(4000) // This suspends the coroutine for 4 seconds
                        cutPaper()
                    }
                    return true
                } else {
                    // Printing failed
                    return false
                }
                return true
            }
        } catch (e: Exception) {
            Log.e("Receipt Printing", "Failed to print receipt", e)
            return false
        }
    }

    //@Suppress("UNREACHABLE_CODE")
    private fun cutPaper() {
        try {
            val printStatus = mPrinter!!.getPrinterStatus()
            if (printStatus == SdkResult.SDK_OK) {
                mPrinter!!.openPrnCutter(1.toByte())
            }
        } catch (e: Exception) {
            Log.e("Cut Paper", "Failed to cut paper", e)
        }
    }
}
