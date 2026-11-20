package com.example.ecoroute

import android.Manifest
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.CancellationSignal
import androidx.core.content.ContextCompat
import androidx.core.location.LocationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.util.concurrent.ScheduledThreadPoolExecutor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(
            messenger,
            "ecoroute/location",
            StandardMethodCodec.INSTANCE,
            messenger.makeBackgroundTaskQueue()
        ).setMethodCallHandler { call, result ->
            if (call.method == "getCurrentCoordinates") {
                getCurrentCoordinates(result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getCurrentCoordinates(result: MethodChannel.Result) {
        val context = applicationContext
        val hasFineLocation = context.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
        if (!hasFineLocation &&
            context.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            result.error("permission-denied", null, null)
            return
        }

        val manager = context.getSystemService(LocationManager::class.java)
        val preferredProviders = listOfNotNull(
            LocationManager.GPS_PROVIDER.takeIf { hasFineLocation },
            LocationManager.FUSED_PROVIDER,
            LocationManager.NETWORK_PROVIDER
        )
        val enabledProviders = manager?.getProviders(true).orEmpty()
        val provider = preferredProviders.firstOrNull { it in enabledProviders }
        if (manager == null || provider == null) {
            result.success(null)
            return
        }

        // Una lectura puntual evita registrar el listener NMEA de Geolocator.
        val cancellation = CancellationSignal()
        val finished = AtomicBoolean()
        val timeout = timeouts.schedule({
            if (finished.compareAndSet(false, true)) {
                result.success(null)
                cancellation.cancel()
            }
        }, 10, TimeUnit.SECONDS)

        try {
            LocationManagerCompat.getCurrentLocation(
                manager,
                provider,
                cancellation,
                ContextCompat.getMainExecutor(context)
            ) { location ->
                if (finished.compareAndSet(false, true)) {
                    timeout.cancel(false)
                    result.success(location?.let { listOf(it.latitude, it.longitude) })
                }
            }
        } catch (error: RuntimeException) {
            if (finished.compareAndSet(false, true)) {
                timeout.cancel(false)
                result.error("location-unavailable", error.message, null)
            }
        }
    }

    private companion object {
        val timeouts = ScheduledThreadPoolExecutor(1).apply {
            removeOnCancelPolicy = true
            setKeepAliveTime(30, TimeUnit.SECONDS)
            allowCoreThreadTimeOut(true)
        }
    }
}
