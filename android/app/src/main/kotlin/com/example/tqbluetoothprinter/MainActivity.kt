package com.example.tqbluetoothprinter

import android.content.Context
import android.os.Bundle
import android.os.RemoteException
import android.util.Log
import com.sunmi.peripheral.printer.InnerPrinterCallback
import com.sunmi.peripheral.printer.InnerPrinterException
import com.sunmi.peripheral.printer.InnerPrinterManager
import com.sunmi.peripheral.printer.WoyouConsts
import com.sunmi.peripheral.printer.SunmiPrinterService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {

    private val TAG = "PrinterMainActivity"
    private var sunmiPrinterService: SunmiPrinterService? = null
    private val CHANNEL = "SumniTalkingPOS"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeSdk" -> {
                    val success = initializeSdk()
                    result.success(success)
                }

                "printReceipt" -> {
                    val token = call.argument<String>("token")
                    val time = call.argument<String>("time")
                    val nameEn = call.argument<String>("nameEn")
                    val nameBn = call.argument<String>("nameBn")
                    val companyName = call.argument<String>("companyName")
                    val config = call.argument<String>("config")
                    val DocEn = call.argument<String>("docName")
                    val DocBn = call.argument<String>("docNameBn")
                    val DocDesignation = call.argument<String>("docDesignation")
                    val DocRoom = call.argument<String>("docRoom")
                    val success = printReceipt(
                        token,
                        time,
                        nameEn,
                        nameBn,
                        companyName,
                        config,
                        DocEn,
                        DocBn,
                        DocDesignation,
                        DocRoom
                    )
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
            val context: Context = this
            val result =
                InnerPrinterManager.getInstance().bindService(context, innerPrinterCallback)
            return result
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize SDK", e)
            return false
        }
    }

    private val innerPrinterCallback: InnerPrinterCallback = object : InnerPrinterCallback() {
        override fun onConnected(service: SunmiPrinterService) {
            sunmiPrinterService = service
            checkSunmiPrinterService(service)
        }

        override fun onDisconnected() {
            sunmiPrinterService = null
            Log.e(TAG, "Sunmi printer service is disconnected")
        }
    }

    private fun checkSunmiPrinterService(service: SunmiPrinterService) {
        var ret = false
        try {
            ret = InnerPrinterManager.getInstance().hasPrinter(service)
        } catch (e: InnerPrinterException) {
            e.printStackTrace()
        }
        sunmiPrinterService = if (ret) service else null
    }

    private fun printReceipt(
        token: String?,
        time: String?,
        nameEn: String?,
        nameBn: String?,
        companyName: String?,
        config: String?,
        DocEn: String?,
        DocBn: String?,
        DocDesignation: String?,
        DocRoom: String?
    ): Boolean {
        try {
            if (sunmiPrinterService != null) {
                sunmiPrinterService!!.setAlignment(1, null)

                if (config == "false") {
                    sunmiPrinterService!!.setFontSize(40f, null)
                    sunmiPrinterService!!.printText("$companyName\n", null)
                } else if (config == "true") {
                    sunmiPrinterService!!.setFontSize(30f, null)
                    sunmiPrinterService!!.printText("$DocEn ($DocBn)\n", null)

                    sunmiPrinterService!!.setFontSize(30f, null)
                    sunmiPrinterService!!.printText("$DocDesignation\n", null)

                    sunmiPrinterService!!.setFontSize(30f, null)
                    sunmiPrinterService!!.printText("Room No (রুম নং): $DocRoom\n", null)
                }

                sunmiPrinterService!!.setFontSize(100f, null)
                sunmiPrinterService!!.printText("$token\n", null)

                sunmiPrinterService!!.setFontSize(30f, null)
                sunmiPrinterService!!.printText("$time\n", null)

                sunmiPrinterService!!.setFontSize(30f, null)
                sunmiPrinterService!!.printText("$nameEn\n", null)

                sunmiPrinterService!!.setFontSize(30f, null)
                sunmiPrinterService!!.printText("$nameBn\n", null)

                sunmiPrinterService!!.setFontSize(25f, null)
                sunmiPrinterService!!.printText("Powered by touch-queue.com\n", null)

                sunmiPrinterService!!.printText("\n", null)

                sunmiPrinterService!!.setFontSize(25f, null)
                sunmiPrinterService!!.printText("Thank You\n", null)
                sunmiPrinterService!!.lineWrap(3, null)
                cutPaper()

                return true
            } else {
                Log.e(TAG, "Printer service is not connected")
                return false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to print receipt", e)
            return false
        }
    }

    private fun cutPaper() {
        if (sunmiPrinterService == null) {
            return
        }
        try {
            sunmiPrinterService?.cutPaper(null)
        } catch (e: RemoteException) {
            Log.e(TAG, "RemoteException occurred", e)
        }
    }
}
