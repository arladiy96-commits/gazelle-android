package com.gazelle.gazelle_android

import kotlin.math.*

/** Pure, deterministic GNSS filter. Distance is in metres; time is monotonic. */
internal data class GpsFix(
    val lat: Double, val lng: Double, val accuracy: Double,
    val speed: Double?, val speedAccuracy: Double?, val elapsed: Long, val wall: Long
)
internal data class GpsAccepted(val fix: GpsFix, val metres: Double, val newSegment: Boolean)

internal class GpsDistanceFilter {
    private var anchor: GpsFix? = null
    private var previous: GpsFix? = null
    private var candidate: GpsFix? = null
    private var lastSeen = -1L
    private var interrupted = true
    private var speedMetres = 0.0
    private var speedComplete = true

    fun interrupt() {
        anchor = null
        previous = null
        candidate = null
        lastSeen = -1L
        interrupted = true
        speedMetres = 0.0
        speedComplete = true
    }

    fun offer(p: GpsFix, nowElapsed: Long): GpsAccepted? {
        if (!p.lat.isFinite() || !p.lng.isFinite() || p.lat !in -90.0..90.0 ||
            p.lng !in -180.0..180.0 || !p.accuracy.isFinite() ||
            p.accuracy <= 0 || p.accuracy > 30 || p.elapsed <= lastSeen ||
            nowElapsed - p.elapsed !in -1000L..10000L) return null
        lastSeen = p.elapsed
        val old = previous
        if (old == null || p.elapsed - old.elapsed > 30000L) {
            anchor = p
            previous = p
            candidate = null
            speedMetres = 0.0
            speedComplete = true
            val result = GpsAccepted(p, 0.0, interrupted || old != null)
            interrupted = false
            return result
        }
        val dt = (p.elapsed - old.elapsed) / 1000.0
        if (dt < 0.4) return null
        val step = distance(old, p)
        // Reject impossible jumps before replacing either anchor.
        if (step > 55.0 * dt + min(15.0, p.accuracy + old.accuracy)) return null
        val goodSpeed = reliableSpeed(p)
        if (goodSpeed != null && goodSpeed > 55.0) return null
        if (goodSpeed != null && step > (goodSpeed + 12.0) * dt + p.accuracy + old.accuracy) return null
        val oldSpeed = reliableSpeed(old)
        if (goodSpeed != null && oldSpeed != null && dt <= 5.0) {
            speedMetres += (goodSpeed + oldSpeed) * 0.5 * dt
        } else speedComplete = false
        previous = p
        // Doppler speed is much less sensitive to stationary coordinate drift.
        if (goodSpeed != null && goodSpeed < 0.35) {
            anchor = p
            candidate = null
            speedMetres = 0.0
            speedComplete = true
            return null
        }
        val a = anchor ?: p.also { anchor = it }
        val distance = distance(a, p)
        val threshold = if (goodSpeed != null && goodSpeed >= 0.6) 2.0
            else max(6.0, hypot(a.accuracy, p.accuracy) * 0.8)
        if (distance < threshold) return null // Keep the anchor: slow steps accumulate.
        if (goodSpeed == null || goodSpeed < 0.6) {
            val c = candidate
            candidate = p
            if (c == null || distance(a, c) < threshold ||
                directionDot(a, c, p) <= 0 || distance(c, p) > 55.0 * dt + p.accuracy) return null
        }
        // Reliable GNSS Doppler speed avoids summing coordinate zigzags on a
        // straight road. Integrate only fresh adjacent fixes (<=5 s); fall back
        // to coordinates if speed is unavailable. Conflicting measurements break
        // the segment instead of converting coordinate noise into extra mileage.
        val conflict = speedComplete && speedMetres > distance * 2 + 20
        val metres = if (conflict) 0.0 else if (speedComplete && speedMetres > 0)
            speedMetres else distance
        anchor = p
        candidate = null
        speedMetres = 0.0
        speedComplete = true
        return GpsAccepted(p, metres, conflict)
    }

    companion object {
        private fun reliableSpeed(p: GpsFix): Double? = p.speed?.takeIf {
            it.isFinite() && it >= 0 && p.speedAccuracy?.let { a -> a.isFinite() && a in 0.0..1.0 } == true
        }
        fun distance(a: GpsFix, b: GpsFix): Double {
            val dLat = Math.toRadians(b.lat - a.lat)
            val dLng = Math.toRadians(b.lng - a.lng)
            val h = sin(dLat / 2).pow(2) + cos(Math.toRadians(a.lat)) *
                cos(Math.toRadians(b.lat)) * sin(dLng / 2).pow(2)
            return 6371008.8 * 2 * atan2(sqrt(h.coerceIn(0.0, 1.0)), sqrt((1-h).coerceIn(0.0, 1.0)))
        }
        private fun directionDot(a: GpsFix, b: GpsFix, c: GpsFix): Double =
            (b.lat-a.lat)*(c.lat-a.lat) + (b.lng-a.lng)*(c.lng-a.lng)*cos(Math.toRadians(a.lat)).pow(2)
    }
}
