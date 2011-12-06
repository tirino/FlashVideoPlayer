package net.ericpetersen.media.videoPlayer.controls {
	import net.ericpetersen.media.videoPlayer.VideoConnection;

	import com.greensock.TweenMax;
	import com.greensock.easing.Sine;

	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;

	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	/**
	 * @author ericpetersen
	 */
	public class VideoPlayerControls extends Sprite {
		/**
		* Dispatched when Pause button is clicked
		*
		* @eventType PAUSE_CLICK
		*/
		public static const PAUSE_CLICK:String = "PAUSE_CLICK";
		
		/**
		* Dispatched when Play button is clicked
		*
		* @eventType PLAY_CLICK
		*/
		public static const PLAY_CLICK:String = "PLAY_CLICK";

		/**
		* Dispatched when Stop button is clicked
		*
		* @eventType STOP_CLICK
		*/
		public static const STOP_CLICK:String = "STOP_CLICK";
		
		/**
		* Dispatched when full-screen button is clicked
		*
		* @eventType FULL_SCREEN_CLICK
		*/
		public static const FULL_SCREEN_CLICK:String = "FULL_SCREEN_CLICK";
		
		/**
		* Dispatched when video time is scrubbed
		*
		* @eventType VIDEO_TIME_SCRUBBED
		*/
		public static const VIDEO_TIME_SCRUBBED:String = "VIDEO_TIME_SCRUBBED";

		/**
		* Dispatched when subtitles on button is clicked
		*
		* @eventType SUBTITLES_DISABLED
		*/
		public static const SUBTITLES_DISABLED:String = "SUBTITLES_DISABLED";

		/**
		* Dispatched when subtitles off button is clicked
		*
		* @eventType SUBTITLES_ENABLED
		*/
		public static const SUBTITLES_ENABLED:String = "SUBTITLES_ENABLED";

		/**
		* Dispatched when volumne has changed
		*
		* @eventType VOLUME_CHANGES
		*/
		public static const VOLUME_CHANGED:String = "VOLUME_CHANGED";

		protected var _asset:MovieClip;
		protected var _currentTimeLbl:TextField;
		protected var _totalTimeLbl:TextField;
		
		protected var _usePlayPauseToggle:Boolean;
		protected var _hasSubtitles:Boolean;
		protected var _isScrubbing:Boolean = false;
		protected var _scrubPercent:Number = 0;
		protected var _origWidth:Number;
		
		/**
		 * Constructor
		 * @param asset The MovieClip asset from the asset swc
		 * @param origWidth The original width of the video player to size the controls. Scrubber will stretch to fit and buttons will be repositioned.
		 * @param usePlayPauseToggle Whether the play and pause should look like one toggle button or be placed next to each other.
		 */
		public function VideoPlayerControls(asset:MovieClip, origWidth:Number, usePlayPauseToggle:Boolean = true, hasSubtitles:Boolean = true) {
			_asset = asset;
			_origWidth = origWidth;
			_usePlayPauseToggle = usePlayPauseToggle;
			_hasSubtitles = hasSubtitles;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			addChild(_asset);
			initTimerLabels();
		}

		private function initTimerLabels():void {
			var _format:TextFormat = new TextFormat();
			_format.font = "Arial";
			_format.color = 0xFFFFFF;
			_format.size = 11;
			_format.align = TextFormatAlign.CENTER;

			_currentTimeLbl = new TextField();
			_currentTimeLbl.defaultTextFormat = _format;
			_currentTimeLbl.selectable = false;
			_currentTimeLbl.selectable = false;
			_currentTimeLbl.text = "0:00:00";
			_currentTimeLbl.width = 45;
			_currentTimeLbl.height = 20;
			_currentTimeLbl.background = true;
			_currentTimeLbl.backgroundColor = 0x333333;

			_totalTimeLbl = new TextField();
			_totalTimeLbl.defaultTextFormat = _format;
			_totalTimeLbl.selectable = false;
			_totalTimeLbl.selectable = false;
			_totalTimeLbl.text = "0:00:00";
			_totalTimeLbl.width = 45;
			_totalTimeLbl.height = 20;
			_totalTimeLbl.background = true;
			_totalTimeLbl.backgroundColor = 0x333333;

			addChild(_currentTimeLbl);
			addChild(_totalTimeLbl);
		}

		public function setHasSubtitles(hasSubtitles:Boolean):void {
			_hasSubtitles = hasSubtitles;
		}

		public function getVolumeValue():Number {
			return (_asset.volumeSlider.slider.value * 10);
		}

		public function setVolumeValue(val:Number):void {
			_asset.volumeSlider.slider.value = val / 10;
		}

		public function setCurrentTime(_time:Number):void {
			_currentTimeLbl.text = convertSecondsToText(_time);
		}

		public function setDuration(_time:Number):void {
			_totalTimeLbl.text = convertSecondsToText(_time);
		}

		private function convertSecondsToText(_seconds:Number):String {
			var hrs:int = (_seconds / (60 * 60));
			var minutes:int = (_seconds / 60) - (hrs * 60);
			var sec:int = (_seconds - (minutes * 60) - (hrs * 60 * 60));
			return hrs + ":" + numberPad(minutes) + ":" + numberPad(sec);
		}

		private function numberPad(nbr:int):String {
			return (nbr < 10) ? ("0" + nbr) : (nbr + "");
		}

		/**
		 * @return The percent that has been scrubbed (0 is far left, 1 is far right)
		 */
		public function getScrubPercent():Number {
			return _scrubPercent;
		}
		
		/**
		 * @return true for if the scrubber is being scrubbed by user.
		 */
		public function isScrubbing():Boolean {
			return _isScrubbing;
		}
		
		/**
		 * Update the load bar by the percent loaded.
		 * @param pctLoaded 
		 */
		public function updateVideoLoadBar(pctLoaded:Number):void {
			if (pctLoaded > 0) {
				_asset.scrubber.videoLoadBar.scaleX = pctLoaded;
			} else {
				_asset.scrubber.videoLoadBar.scaleX = 0;
			}
			if (pctLoaded > 1) {
				_asset.scrubber.videoLoadBar.scaleX = 1;
			}
		}
		
		/**
		 * Update the progress bar measuring the time of the video
		 * @param pctProgress
		 */
		public function updateVideoProgressBar(pctProgress:Number):void {
			if (pctProgress < 0) {
				_asset.scrubber.videoProgressBar.scaleX = 0;
			} else if (pctProgress > 1) {
				_asset.scrubber.videoProgressBar.scaleX = 1;
			} else {
				_asset.scrubber.videoProgressBar.scaleX = pctProgress;
			}
		}
		
		/**
		 * Update the play and pause buttons
		 * @param state
		 */
		public function updatePlayPause(state:int):void {
			if (_usePlayPauseToggle) {
				switch (state) {
					case VideoConnection.UNSTARTED :
						_asset.playPause.playBtn.visible = true;
						_asset.playPause.pauseBtn.visible = false;
						break;
					case VideoConnection.PLAYING :
						_asset.playPause.playBtn.visible = false;
						_asset.playPause.pauseBtn.visible = true;
						break;
					case VideoConnection.PAUSED :
						_asset.playPause.playBtn.visible = true;
						_asset.playPause.pauseBtn.visible = false;
						break;
					case VideoConnection.ENDED :
						_asset.playPause.playBtn.visible = true;
						_asset.playPause.pauseBtn.visible = false;
						break;
					default :
						break;
				}
			}
		}
		
		/**
		 * Resize the controls
		 * @param isFullScreen If true, it will resize for full-screen.
		 */
		public function resize(isFullScreen:Boolean = false):void {
			_asset.playPause.x = 0;
			if (_usePlayPauseToggle) {
				_asset.playPause.playBtn.x = 0;
				_asset.playPause.pauseBtn.x = 0;
			} else {
				_asset.playPause.playBtn.x = 0;
				_asset.playPause.pauseBtn.x = _asset.playPause.playBtn.x + _asset.playPause.playBtn.width;
			}

			// position stop button
			_asset.theStop.x = _asset.playPause.x + _asset.playPause.width;
			// position current timer label
			_currentTimeLbl.x = _asset.theStop.x + _asset.theStop.width;
			// position progress slider
			_asset.scrubber.x = _currentTimeLbl.x + _currentTimeLbl.width;

			var leftItemsSize:int = (_currentTimeLbl.width + _asset.playPause.width + _asset.theStop.width);
			var rightItemsSize:int = (_totalTimeLbl.width + _asset.volumeSlider.width + _asset.subtitlesOnOff.subtitlesOnBtn.width + _asset.fullScreenBtn.width);
			if (isFullScreen) {
				_asset.scrubber.width = stage.stageWidth - leftItemsSize - rightItemsSize;
			} else {
				_asset.scrubber.width = _origWidth - leftItemsSize - rightItemsSize;
			}
			// position total timer label
			_totalTimeLbl.x = _asset.scrubber.x + _asset.scrubber.width;
			
			// position volume slider
			_asset.volumeSlider.x = _totalTimeLbl.x + _totalTimeLbl.width;

			// position subtitles
			_asset.subtitlesOnOff.x = _asset.volumeSlider.x + _asset.volumeSlider.width;
			// position this buttons one above the other
			_asset.subtitlesOnOff.subtitlesOnBtn.x = 0;
			_asset.subtitlesOnOff.subtitlesOffBtn.x = 0;

			// position fullscreen
			_asset.fullScreenBtn.x = _asset.subtitlesOnOff.x + _asset.subtitlesOnOff.width;
		}
		
		/**
		 * Remove listeners and clean up
		 */
		public function destroy():void {
			_asset.scrubber.videoProgressHit.removeEventListener(MouseEvent.MOUSE_DOWN, onProgressBarMouseDown);

			_asset.playPause.playBtn.removeEventListener(MouseEvent.CLICK, onPlayBtnClick);
			_asset.playPause.playBtn.removeEventListener(MouseEvent.ROLL_OVER, onGenericRollOver);
			_asset.playPause.playBtn.removeEventListener(MouseEvent.ROLL_OUT, onGenericRollOut);

			_asset.playPause.pauseBtn.removeEventListener(MouseEvent.CLICK, onPauseBtnClick);
			_asset.playPause.pauseBtn.removeEventListener(MouseEvent.ROLL_OVER, onGenericRollOver);
			_asset.playPause.pauseBtn.removeEventListener(MouseEvent.ROLL_OUT, onGenericRollOut);

			_asset.theStop.removeEventListener(MouseEvent.CLICK, onStopBtnClick);
			_asset.theStop.removeEventListener(MouseEvent.ROLL_OVER, onGenericRollOver);
			_asset.theStop.removeEventListener(MouseEvent.ROLL_OUT, onGenericRollOut);

			_asset.subtitlesOnOff.subtitlesOnBtn.removeEventListener(MouseEvent.CLICK, onFullScreenBtnClick);
			_asset.subtitlesOnOff.subtitlesOnBtn.removeEventListener(MouseEvent.ROLL_OVER, onGenericRollOver);
			_asset.subtitlesOnOff.subtitlesOnBtn.removeEventListener(MouseEvent.ROLL_OUT, onGenericRollOut);

			_asset.subtitlesOnOff.subtitlesOffBtn.removeEventListener(MouseEvent.CLICK, onFullScreenBtnClick);
			_asset.subtitlesOnOff.subtitlesOffBtn.removeEventListener(MouseEvent.ROLL_OVER, onGenericRollOver);
			_asset.subtitlesOnOff.subtitlesOffBtn.removeEventListener(MouseEvent.ROLL_OUT, onGenericRollOut);

			_asset.volumeSlider.slider.removeEventListener(Event.CHANGE, onVolumeChange);

			_asset.fullScreenBtn.removeEventListener(MouseEvent.CLICK, onFullScreenBtnClick);
			_asset.fullScreenBtn.removeEventListener(MouseEvent.ROLL_OVER, onGenericRollOver);
			_asset.fullScreenBtn.removeEventListener(MouseEvent.ROLL_OUT, onGenericRollOut);

			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
		}

		protected function build():void {
			_asset.scrubber.videoLoadBar.scaleX = 0;
			_asset.scrubber.videoLoadBar.mouseEnabled = false;

			_asset.scrubber.videoProgressBar.scaleX = 0;
			_asset.scrubber.videoProgressBar.mouseEnabled = false;
			_asset.scrubber.videoProgressHit.buttonMode = true;
			_asset.scrubber.videoProgressHit.addEventListener(MouseEvent.MOUSE_DOWN, onProgressBarMouseDown, false, 0, true);

			_asset.playPause.playBtn.buttonMode = true;
			_asset.playPause.playBtn.mouseChildren = false;
			_asset.playPause.playBtn.addEventListener(MouseEvent.CLICK, onPlayBtnClick, false, 0, true);
			_asset.playPause.playBtn.addEventListener(MouseEvent.ROLL_OVER, onGenericRollOver, false, 0, true);
			_asset.playPause.playBtn.addEventListener(MouseEvent.ROLL_OUT, onGenericRollOut, false, 0, true);

			_asset.playPause.pauseBtn.buttonMode = true;
			_asset.playPause.pauseBtn.mouseChildren = false;
			_asset.playPause.pauseBtn.addEventListener(MouseEvent.CLICK, onPauseBtnClick, false, 0, true);
			_asset.playPause.pauseBtn.addEventListener(MouseEvent.ROLL_OVER, onGenericRollOver, false, 0, true);
			_asset.playPause.pauseBtn.addEventListener(MouseEvent.ROLL_OUT, onGenericRollOut, false, 0, true);

			_asset.theStop.buttonMode = true;
			_asset.theStop.mouseChildren = false;
			_asset.theStop.addEventListener(MouseEvent.CLICK, onStopBtnClick);
			_asset.theStop.addEventListener(MouseEvent.ROLL_OVER, onGenericRollOver);
			_asset.theStop.addEventListener(MouseEvent.ROLL_OUT, onGenericRollOut);

			if (_hasSubtitles) {
				_asset.subtitlesOnOff.subtitlesOnBtn.buttonMode = true;
				_asset.subtitlesOnOff.subtitlesOnBtn.mouseChildren = false;
				_asset.subtitlesOnOff.subtitlesOnBtn.visible = true;
				_asset.subtitlesOnOff.subtitlesOnBtn.addEventListener(MouseEvent.CLICK, onSubtitlesBtnClick, false, 0, true);
				_asset.subtitlesOnOff.subtitlesOnBtn.addEventListener(MouseEvent.ROLL_OVER, onGenericRollOver, false, 0, true);
				_asset.subtitlesOnOff.subtitlesOnBtn.addEventListener(MouseEvent.ROLL_OUT, onGenericRollOut, false, 0, true);

				_asset.subtitlesOnOff.subtitlesOffBtn.buttonMode = true;
				_asset.subtitlesOnOff.subtitlesOffBtn.mouseChildren = false;
				_asset.subtitlesOnOff.subtitlesOffBtn.visible = false;
				_asset.subtitlesOnOff.subtitlesOffBtn.addEventListener(MouseEvent.CLICK, onSubtitlesOffBtnClick, false, 0, true);
				_asset.subtitlesOnOff.subtitlesOffBtn.addEventListener(MouseEvent.ROLL_OVER, onGenericRollOver, false, 0, true);
				_asset.subtitlesOnOff.subtitlesOffBtn.addEventListener(MouseEvent.ROLL_OUT, onGenericRollOut, false, 0, true);
			} else {
				_asset.subtitlesOnOff.subtitlesOnBtn.visible = false;
				_asset.subtitlesOnOff.subtitlesOffBtn.visible = true;
			}

			_asset.volumeSlider.slider.addEventListener(Event.CHANGE, onVolumeChange);

			_asset.fullScreenBtn.buttonMode = true;
			_asset.fullScreenBtn.mouseChildren = false;
			_asset.fullScreenBtn.addEventListener(MouseEvent.CLICK, onFullScreenBtnClick, false, 0, true);
			_asset.fullScreenBtn.addEventListener(MouseEvent.ROLL_OVER, onGenericRollOver, false, 0, true);
			_asset.fullScreenBtn.addEventListener(MouseEvent.ROLL_OUT, onGenericRollOut, false, 0, true);

			stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp, false, 0, true);
			resize();
		}

		protected function onAddedToStage(event:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			build();
		}

		protected function enterFrameHandler(event:Event):void {
			if (_isScrubbing) {
				if (_asset.scrubber.videoProgressHit.hitTestPoint(stage.mouseX, stage.mouseY)) {
					_scrubPercent = _asset.scrubber.videoProgressHit.mouseX/_asset.scrubber.videoProgressHit.width;
					updateVideoProgressBar(_scrubPercent);
					dispatchEvent(new Event(VIDEO_TIME_SCRUBBED));
				}
			}
		}
		
		protected function onProgressBarMouseDown(event:MouseEvent):void {
			_isScrubbing = true;
			addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
		}
		
		protected function onStageMouseUp(event:MouseEvent):void {
			if (_isScrubbing) {
				removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
				dispatchEvent(new Event(VIDEO_TIME_SCRUBBED));
				_isScrubbing = false;
			}
		}
		
		protected function onPlayBtnClick(event:MouseEvent):void {
			dispatchEvent(new Event(PLAY_CLICK));
		}

		protected function onPauseBtnClick(event:MouseEvent):void {
			dispatchEvent(new Event(PAUSE_CLICK));
		}

		protected function onFullScreenBtnClick(event:MouseEvent):void {
			trace("full screen clicked");
			dispatchEvent(new Event(FULL_SCREEN_CLICK));
		}

		protected function onGenericRollOver(event:MouseEvent):void {
			var clip:MovieClip = MovieClip(event.currentTarget);
			TweenMax.to(clip, 0.25, {colorMatrixFilter:{amount:1, brightness:1.3}, ease:Sine.easeOut});
		}
		
		protected function onGenericRollOut(event:MouseEvent):void {
			var clip:MovieClip = MovieClip(event.currentTarget);
			TweenMax.to(clip, 0.25, {colorMatrixFilter:{amount:1, brightness:1}, ease:Sine.easeOut});
		}

		protected function onStopBtnClick(event:MouseEvent):void {
			trace("Stop clicked!");
			dispatchEvent(new Event(STOP_CLICK));
		}

		protected function onVolumeChange(event:Event):void {
			trace("volume changed");
			dispatchEvent(new Event(VOLUME_CHANGED));
		}

		protected function onSubtitlesBtnClick(event:MouseEvent):void {
			_asset.subtitlesOnOff.subtitlesOnBtn.visible = false;
			_asset.subtitlesOnOff.subtitlesOffBtn.visible = true;
			trace("Hide subs!")
			dispatchEvent(new Event(SUBTITLES_DISABLED));
		}
		
		protected function onSubtitlesOffBtnClick(event:MouseEvent):void {
			_asset.subtitlesOnOff.subtitlesOffBtn.visible = false;
			_asset.subtitlesOnOff.subtitlesOnBtn.visible = true;
			trace("Show subs!")
			dispatchEvent(new Event(SUBTITLES_ENABLED));
		}
	}
}
