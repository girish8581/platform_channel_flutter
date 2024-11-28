package com.example.platform_channel_example_flutter
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.os.Build
import android.Manifest
import android.content.pm.PackageManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import com.softland.silipmlib.SILiPM
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.app/channel"
    private lateinit var iPM: SILiPM
    private var socket: BluetoothSocket? = null

    companion object {
        private const val DEVICE_ADDRESS = "C0:49:EF:A9:33:DA" // Replace with your printer's Bluetooth address
        private const val UUID_STRING = "00001101-0000-1000-8000-00805F9B34FB" // Replace with your printer's UUID if needed
    }

    private fun getPairedDevices(): List<Map<String, String>> {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter == null) {
            throw IOException("Bluetooth not supported on this device.")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                // Request permission and return an empty list for now.
                requestPermissions(arrayOf(Manifest.permission.BLUETOOTH_CONNECT), 1)
                return emptyList() // Ensure the function always returns a value.
            }
        }

        val pairedDevices = bluetoothAdapter.bondedDevices
        val deviceList = mutableListOf<Map<String, String>>()

        for (device in pairedDevices) {

            if(device.name.startsWith("silbt")){
                val deviceInfo = mapOf("name" to device.name, "address" to device.address)
                deviceList.add(deviceInfo)
            }

        }
        return deviceList
    }

    private fun connectToPrinter(deviceAddress: String) {
        val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter == null) {
            throw IOException("Bluetooth not supported on this device.")
        }

        if (!bluetoothAdapter.isEnabled) {
            throw IOException("Bluetooth is not enabled.")
        }

        try {
            val device = bluetoothAdapter.getRemoteDevice(deviceAddress)
            socket = device.createRfcommSocketToServiceRecord(UUID.fromString(UUID_STRING))

            Log.d("Printer", "Attempting to connect to printer at $deviceAddress...")
            socket?.connect()
            Log.d("Printer", "Connected to printer successfully.")

            iPM = SILiPM(socket!!)
        } catch (e: IOException) {
            socket?.close()
            throw e
        }
    }


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isBluetoothEnabled" -> {
                    val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
                    if (bluetoothAdapter != null) {
                        result.success(bluetoothAdapter.isEnabled)
                    } else {
                        result.error("NO_BLUETOOTH", "Bluetooth is not supported on this device", null)
                    }
                }

                "getPairedDevices" -> {
                    try {
                        val pairedDevices = getPairedDevices()
                        result.success(pairedDevices)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to fetch paired devices: ${e.message}", null)
                    }
                }
                "connectToSelectedPrinter" -> {
                    val deviceAddress = call.argument<String>("deviceAddress") ?: ""
                    try {
                        connectToPrinter(deviceAddress)
                        result.success("Connected to printer at $deviceAddress")
                    } catch (e: Exception) {
                        result.error("CONNECTION_ERROR", "Failed to connect to printer: ${e.message}", null)
                    }
                }
                "connectPrinter" -> {
                    try {
                        initializePrinter()
                        result.success("Connected to printer.")
                    } catch (e: Exception) {
                        result.error("CONNECTION_ERROR", "Failed to connect to printer: ${e.message}", null)
                    }
                }
                "printText" -> {
                        val text = call.argument<String>("text") ?: ""
                        val font = call.argument<Int>("font") ?: 0 // Replace with valid font ID
                        val alignment = call.argument<Int>("alignment") ?: 1 // Replace with valid alignment ID

                    try {
                        iPM.PrintLine(text, font, alignment)
                        result.success("Printed text successfully.")
                    } catch (e: Exception) {
                        result.error("PRINT_ERROR", "Failed to print text: ${e.message}", null)
                    }
                }
                "setLineFeed" -> {
                        val lineFeedCount = call.argument<Int>("lineFeedCount") ?: 1
                        iPM.setLineFeed(lineFeedCount)
                        result.success("setLineFeed executed successfully")
                }
                "disconnectPrinter" -> {
                    try {
                        disconnectPrinter()
                        result.success("Disconnected from printer.")
                    } catch (e: Exception) {
                        result.error("DISCONNECTION_ERROR", "Failed to disconnect: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun initializePrinter() {
        val bluetoothAdapter: BluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        if (bluetoothAdapter == null) {
            throw IOException("Bluetooth not supported on this device.")
        }

        if (!bluetoothAdapter.isEnabled) {
            throw IOException("Bluetooth is not enabled.")
        }

        try {
            val device: BluetoothDevice = bluetoothAdapter.getRemoteDevice(DEVICE_ADDRESS)
            socket = device.createRfcommSocketToServiceRecord(UUID.fromString(UUID_STRING))

            Log.d("Printer", "Attempting to connect to printer...")
            socket?.connect()
            Log.d("Printer", "Connected to printer successfully.")

            iPM = SILiPM(socket!!)
        } catch (e: IOException) {
            socket?.close()
            throw e
        }
    }

    private fun disconnectPrinter() {
        try {
            socket?.close()
            Log.d("Printer", "Disconnected from printer.")
        } catch (e: IOException) {
            Log.e("Printer", "Error disconnecting: ${e.message}")
            throw e
        }
    }
}


