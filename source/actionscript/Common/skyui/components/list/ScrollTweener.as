class skyui.components.list.ScrollTweener
{
	private var _startPosition: Number = 0;
	private var _targetPosition: Number = 0;
	private var _currentPosition: Number = 0;
	private var _startTime: Number = 0;
	private var _duration: Number = 150;
	private var _active: Boolean = false;


	public function ScrollTweener()
	{
	}

	public function get currentPosition(): Number
	{
		return this._currentPosition;
	}

	public function get isActive(): Boolean
	{
		return this._active;
	}

	// a_from is the current *visual* position so a mid-flight retarget continues from where the eye is.
	public function tweenTo(a_from: Number, a_to: Number, a_durationMs: Number)
	{
		this._startPosition = a_from;
		this._targetPosition = a_to;
		this._currentPosition = a_from;
		this._duration = a_durationMs > 0 ? a_durationMs : 1;
		this._startTime = getTimer();
		this._active = true;
	}

	public function cancel()
	{
		this._active = false;
	}

	public function tick(): Boolean
	{
		if (!this._active)
			return false;

		var t: Number = (getTimer() - this._startTime) / this._duration;
		if (t >= 1) {
			this._currentPosition = this._targetPosition;
			this._active = false;
			return false;
		}

		var eased: Number = 1 - Math.pow(1 - t, 3);
		this._currentPosition = this._startPosition + (this._targetPosition - this._startPosition) * eased;
		return true;
	}
}
