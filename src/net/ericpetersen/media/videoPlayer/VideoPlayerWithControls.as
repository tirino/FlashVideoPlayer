package net.ericpetersen.media.videoPlayer {
    import com.greensock.TweenMax;

	import net.ericpetersen.media.videoPlayer.controls.VideoPlayerControls;

    import flash.display.Loader; 
    import flash.system.LoaderContext;

    import flash.display.Shape;
    import flash.display.MovieClip;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.FullScreenEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import flash.net.SharedObject;

	/**
	 * <p>VideoPlayerWithControls is a video player with skinnable controls.
	 * The controls are a .swc asset exported from the .fla in the lib folder to the swc folder.
	 * Controls include a play/pause button (which can be a toggle or both together),
	 * a scrubber, and a full-screen button.</p>
	 * <p>Both progressive (downloaded file such as .flv) or streaming (such as rtmp:// links)
	 * are supported.</p>
	 * 
	 * @author ericpetersen
	 */
	public class VideoPlayerWithControls extends VideoPlayer {
		/**
		* Dispatched when fullScreen changes.
		*
		* @eventType FULL_SCREEN_CHANGED
		*/
		public static const FULL_SCREEN_CHANGED:String = "FULL_SCREEN_CHANGED";

		/**
		* Dispatched when stop button is pressed.
		*
		* @eventType STOPPED_MOVIE
		*/
		public static const STOPPED_MOVIE:String = "STOPPED_MOVIE";

        private var _storedVolume:SharedObject;

		protected var _controls:VideoPlayerControls;
		//protected var _isPaused:Boolean = false;
		protected var _clickableArea:MovieClip = new MovieClip();
		protected var _isFullScreen:Boolean = false;
		protected var _origVideoPt:Point;
		protected var _origControlsPt:Point;
		protected var _origPlayerWidth:Number;
		protected var _origPlayerHeight:Number;

		[Embed("loading9.swf", mimeType="application/octet-stream")]
		private var _loadingAnimationAsset:Class;
		private var _loadingAnimation:Loader = new Loader();
		private var _loadingAnimationWidth:int = 72;
		private var _loadingAnimationHeight:int = 72;

		/**
		 * @return Whether or not it is full-screen
		 */
		public function get isFullScreen():Boolean {
			return _isFullScreen;
		}
		
		/**
		 * Constructor
		 * @param controls The VideoPlayerControls that uses the swc asset
		 * @param width The width of the player
		 * @param height The height of the player
		 */
		public function VideoPlayerWithControls(controls:VideoPlayerControls, width:int = 320, height:int = 240) {
			super(width, height);
			_controls = controls;
			_storedVolume = SharedObject.getLocal("org.freevana.volume");
			_origPlayerWidth = width;
			_origPlayerHeight = height;

			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(VideoConnection.METADATA_READY, onMetadataReadyForControls);
		}

        public function getControls():VideoPlayerControls {
            return _controls;
        }

        public function getClickableArea():MovieClip {
            return _clickableArea;
        }

        public function setHasSubtitles(hasSubtitles:Boolean):void {
            _controls.setHasSubtitles(hasSubtitles);
        }

        private function onMetadataReadyForControls(ev:Event):void {
            _controls.setDuration(getDuration());
        }

		/**
		 * Sets the player to full screen
		 * @param val true or false
		 */
		public function setFullScreen(val:Boolean):void {
			trace("setFullScreen " + val);
			_isFullScreen = val;
			if (val == true) {
				_origVideoPt.x = this.x;
				_origVideoPt.y = this.y;

				stage.displayState = StageDisplayState.FULL_SCREEN;
			} else {
				stage.displayState = StageDisplayState.NORMAL;
			}
		}

		/**
		 * Remove listeners and clean up
		 */
		override public function destroy():void {
			super.destroy();
			stage.removeEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			removeEventListener(VideoConnection.METADATA_READY, onMetadataReadyForControls);
			_controls.destroy();
			if (_clickableArea != null) {
    			_clickableArea.removeEventListener(MouseEvent.CLICK, onScreenClick);
			}
		}

		override protected function onAddedToStage(event:Event):void {
			super.onAddedToStage(event);
			stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
			buildControls();
			
			var shape:Shape = new Shape();
			shape.graphics.beginFill(0x000000, 0.0);
			shape.graphics.drawRect(0, 0, this.width, this.height - _controls.height);
			shape.graphics.endFill();
			_clickableArea.addChild(shape);
			_clickableArea.buttonMode = true;
			_clickableArea.mouseChildren = false; // needed so that subs still show the hand cursor
			_clickableArea.addEventListener(MouseEvent.CLICK, onScreenClick);

			// Add loading animation
			var context:LoaderContext = new LoaderContext();
			context.allowCodeImport = true;
			_loadingAnimation.loadBytes(new _loadingAnimationAsset(), context);
			_loadingAnimation.x = (this.width - (_loadingAnimationWidth * 2)) / 2;
			_loadingAnimation.y = (this.height - (_loadingAnimationHeight * 2)) / 2;
			_clickableArea.addChild(_loadingAnimation);

			//trace("ClickableArea:" + "x:"+_clickableArea.x+", y:"+_clickableArea.y+", w:"+_clickableArea.width+", h:"+_clickableArea.height);
			//trace("ClickableArea: w:"+this.width+", h:"+this.height);
			addChild(_clickableArea);
		}

		override protected function onVideoStartedPlaying(event:Event):void {
			trace('video started playing');
			TweenMax.to(_loadingAnimation, 1.5, {alpha:0.0, overwrite:1});
		}

		protected function buildControls():void {
			_controls.y = _playerHeight - _controls.height;
			_origVideoPt = new Point(0, 0);
			_origControlsPt = new Point(0, _playerHeight);

			// Video Control events
			_controls.addEventListener(VideoPlayerControls.PLAY_CLICK, onPlayClick);
			_controls.addEventListener(VideoPlayerControls.PAUSE_CLICK, onPauseClick);
			_controls.addEventListener(VideoPlayerControls.STOP_CLICK, onStopClick);
			_controls.addEventListener(VideoPlayerControls.VOLUME_CHANGED, onVolumeChanged);
			_controls.addEventListener(VideoPlayerControls.FULL_SCREEN_CLICK, onFullScreenClick);
			_controls.addEventListener(VideoPlayerControls.VIDEO_TIME_SCRUBBED, onVideoTimeScrubbed);
			addChild(_controls);
			addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
		}

		protected function enterFrameHandler(event:Event):void {
			var pctLoaded:Number = getVideoBytesLoaded()/getVideoBytesTotal();
			_controls.updateVideoLoadBar(pctLoaded);
			if (!_controls.isScrubbing()) {
				var pctProgress:Number = getCurrentTime()/getDuration();
				_controls.updateVideoProgressBar(pctProgress);
				_controls.setCurrentTime(getCurrentTime());
			}
		}

		protected function onVideoTimeScrubbed(event:Event):void {
			var secondsToSeekTo:Number = _controls.getScrubPercent() * getDuration();
			if (secondsToSeekTo > 0 && secondsToSeekTo < getDuration()) {
				seekTo(secondsToSeekTo, true);
			}
		}

        protected function onScreenClick(event:MouseEvent):void {
            // We don't want to do anything here if the user clicked on the controls
            if (event.stageY < _controls.y) {
                if (getPlayerState() == VideoConnection.PLAYING) {
                    pauseVideo();
                } else if (getPlayerState() == VideoConnection.PAUSED) {
                    playVideo();
                }
                trace("[VideoPlayerWithControls] onScreenClick: Nothing to do!");
            }
        }

		protected function onPlayClick(event:Event):void {
			playVideo();
		}
		
		protected function onPauseClick(event:Event):void {
			pauseVideo();
		}

		protected function onStopClick(event:Event):void {
		    if (_isFullScreen) {
    		    setFullScreen(!_isFullScreen);
		    }
			stopVideo();
			dispatchEvent(new Event(STOPPED_MOVIE));
		}

        protected function onVolumeChanged(ev:*):void {
            // Save volume preferences for the user
            _storedVolume.data.volume = ev.target.getVolumeValue();
            setVolume(ev.target.getVolumeValue());
        }

		protected function onFullScreenClick(event:Event):void {
			setFullScreen(!_isFullScreen);
		}
		
		protected function onFullScreen(event:FullScreenEvent):void {
			trace("onFullScreen");
			if (event.fullScreen) {
				// set up fullscreen
				_isFullScreen = true;
				stage.addEventListener(Event.RESIZE, resizeFullScreenDisplay);
				resizeFullScreenDisplay();
			} else {
				// go back from fullscreen
				_isFullScreen = false;
				stage.removeEventListener(Event.RESIZE, resizeFullScreenDisplay);
				resumeFromFullScreenDisplay();
			}
			dispatchEvent(new Event(FULL_SCREEN_CHANGED));
		}
		
		protected function resizeFullScreenDisplay(event:Event = null):void {
			trace("resizeFullScreenDisplay, stage: " + stage);
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			this.x = 0;
			this.y = 0;
			setSize(stage.stageWidth, stage.stageHeight);

			_clickableArea.scaleX = (stage.stageWidth / _origPlayerWidth);
			_clickableArea.scaleY = ((stage.stageHeight - (_controls.height + 2)) / (_origPlayerHeight - _controls.height));

			_controls.x = 0;
			_controls.y = stage.stageHeight - _controls.height;
			_controls.resize(true);
		}
		
		protected function resumeFromFullScreenDisplay():void {
			this.x = _origVideoPt.x;
			this.y = _origVideoPt.y;
			setSize(_origPlayerWidth, _origPlayerHeight);
			
			_clickableArea.scaleX = _clickableArea.scaleY = 1;

			_controls.x = 0;
			_controls.y = _origPlayerHeight - _controls.height;
			_controls.resize(false);
		}
		
		override protected function onPlayerStateChange(event:Event):void {
			trace("onPlayerStateChange");
			var state:int = getPlayerState();
			switch (state) {
				case VideoConnection.UNSTARTED :
					trace("state: " + VideoConnection.UNSTARTED);
					_controls.updatePlayPause(VideoConnection.UNSTARTED);
					break;
				case VideoConnection.PLAYING :
					trace("state: " + VideoConnection.PLAYING);
					// Update volume according to user settings
					if (_storedVolume.size > 0) {
						setVolume(_storedVolume.data.volume);
						_controls.setVolumeValue(_storedVolume.data.volume);
					}
					_controls.updatePlayPause(VideoConnection.PLAYING);
					break;
				case VideoConnection.PAUSED :
					trace("state: " + VideoConnection.PAUSED);
					_controls.updatePlayPause(VideoConnection.PAUSED);
					break;
				case VideoConnection.ENDED :
					trace("state: " + VideoConnection.ENDED);
					seekTo(0);
					pauseVideo();
					stage.displayState = StageDisplayState.NORMAL;
					break;
				default :
					break;
			}
		}
	}
}
