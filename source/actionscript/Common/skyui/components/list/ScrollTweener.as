// Velocity-based momentum scroller. Each call to impulse() adds (or, on direction reversal,
// resets) velocity. tick() returns the per-frame position delta and decays the velocity by
// an exponential friction factor. Settles when velocity falls below a threshold.
//
// NOTE: This is a *new class*, which the JPEXS/FFDec CLI cannot inject into an existing SWF
// on its own. The class must first be authored into source/swf/skyui/inventorylists.xml via
// the FFDec GUI, once that's done, the standard build pipeline will keep its body in sync
// from this file.
//
// AS2 detail: static fields must be referenced by their fully qualified class path from
// inside instance methods. Unqualified names resolve to undefined, which silently turns all
// arithmetic involving them into NaN.
class skyui.components.list.ScrollTweener
{
    private var _velocity: Number = 0;          // rows per ms, signed
    private var _lastTickTime: Number = 0;
    private var _lastImpulseTime: Number = 0;   // for cadence-based acceleration
    private var _active: Boolean = false;

    // Friction balances "snappy single tick" against "rapid ticks accumulate momentum".
    // 0.85 gives ~13% velocity after 200ms -- slow enough that rapid ticks (sub-100ms apart)
    // stack noticeably, but a single isolated tick settles in ~300ms instead of dragging.
    private static var FRICTION_PER_FRAME: Number = 0.50;
    private static var FRAME_REFERENCE_MS: Number = 16;
    private static var VELOCITY_STOP_THRESHOLD: Number = 0.0005;

    // Cadence-based acceleration tunables. ACCEL_WINDOW_MS is the time gap above which
    // a tick is treated as "fresh" (1x impulse). ACCEL_MAX_MULT is the multiplier applied
    // when ticks are landing instantaneously back-to-back. The curve between is quadratic.
    private static var ACCEL_WINDOW_MS: Number = 300;
    private static var ACCEL_MAX_MULT: Number = 18;

    public function ScrollTweener()
    {
    }

    public function get velocity()
    {
        return this._velocity;
    }

    public function get isActive()
    {
        return this._active;
    }

    // Adds an impulse in a_direction (+1/-1). pageSize is the natural rows-per-tick magnitude.
    // durationMs scales the impulse so longer durations produce a longer glide per tick.
    //
    // Cadence-based acceleration: rapid successive ticks each get a *non-linear* multiplier
    // applied. An isolated tick (>= ACCEL_WINDOW_MS gap) is 1x. Faster ticks ramp up along a
    // quadratic curve toward ACCEL_MAX_MULT. Combined with velocity accumulation, this makes
    // the second tick noticeably bigger than the first, the third bigger again, and so on.
    // Currently set to quadratic (ramp * ramp). For more aggressive ramp, change to cubic.
    // Other knobs to tune: 
    //		ScrollTweener: private static vars in this script above
    // 		ScrollingList: smoothScrollDuration - lower = faster.
    //		ScrollingList: this._scrollTweener.impulse - change this.scrollDelta to a #
    //			- this will change one tick (currently 1) to # of rows each tick
    public function impulse(a_direction: Number, a_pageSize: Number, a_durationMs: Number)
    {
        var friction: Number = skyui.components.list.ScrollTweener.FRICTION_PER_FRAME;
        var frameMs: Number = skyui.components.list.ScrollTweener.FRAME_REFERENCE_MS;
        var window: Number = skyui.components.list.ScrollTweener.ACCEL_WINDOW_MS;
        var maxMult: Number = skyui.components.list.ScrollTweener.ACCEL_MAX_MULT;

        // Cadence multiplier
        var now: Number = getTimer();
        var sinceLast: Number = now - this._lastImpulseTime;
        this._lastImpulseTime = now;
        var cadenceMult: Number = 1;
        if (sinceLast > 0 && sinceLast < window) {
            var ramp: Number = (window - sinceLast) / window;   // 0 (slow) -> 1 (instant)
            cadenceMult = 1 + (maxMult - 1) * ramp * ramp;      // quadratic 1 -> maxMult
        }

        var durationScale: Number = a_durationMs > 0 ? a_durationMs / 250 : 1;
        var imp: Number = a_pageSize * (1 - friction) / frameMs * durationScale * cadenceMult;

        if (this._velocity * a_direction < 0)
            this._velocity = a_direction * imp;     // reversing -> halt + new direction
        else
            this._velocity += a_direction * imp;    // same direction or starting -> accumulate

        if (!this._active) {
            this._active = true;
            this._lastTickTime = getTimer();
        }
    }

    // Returns the position delta (rows) for this frame and decays velocity. Caller is
    // responsible for clamping to bounds and reading isSettled() to terminate.
    public function tick()
    {
        if (!this._active)
            return 0;

        var friction: Number = skyui.components.list.ScrollTweener.FRICTION_PER_FRAME;
        var frameMs: Number = skyui.components.list.ScrollTweener.FRAME_REFERENCE_MS;

        var now: Number = getTimer();
        var dt: Number = now - this._lastTickTime;
        this._lastTickTime = now;
        if (dt < 0 || dt > 200)
            dt = frameMs;        // sanity clamp (paused tab, very slow frame, etc.)

        var delta: Number = this._velocity * dt;
        this._velocity *= Math.pow(friction, dt / frameMs);

        return delta;
    }

    public function isSettled()
    {
        return Math.abs(this._velocity) < skyui.components.list.ScrollTweener.VELOCITY_STOP_THRESHOLD;
    }

    public function settle()
    {
        this._velocity = 0;
        this._active = false;
    }

    public function cancel()
    {
        this._velocity = 0;
        this._active = false;
    }
}
