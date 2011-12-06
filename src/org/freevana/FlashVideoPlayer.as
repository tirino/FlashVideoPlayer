package org.freevana {
    import net.ericpetersen.media.videoPlayer.VideoPlayer;
    import net.ericpetersen.media.videoPlayer.VideoPlayerWithControls;
    import net.ericpetersen.media.videoPlayer.controls.VideoPlayerControls;

    import com.greensock.TweenMax;

    import flash.display.MovieClip;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;

    import flash.display.LoaderInfo;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.FullScreenEvent;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.text.AntiAliasType;
    import flash.filters.GlowFilter;
    import flash.filters.BitmapFilterQuality;
    import com.subtitles.*;

    import flash.utils.Timer;
    import flash.filesystem.File;

    /**
     * @author tirino, based of work by ericpetersen
     */
    public class FlashVideoPlayer extends MovieClip {
		/**
		* Dispatched when the movie stops
		*
		* @eventType STOPPED_MOVIE
		*/
		public static const STOPPED_MOVIE:String = "STOPPED_MOVIE";

		/**
		* Dispatched when the video is not found
		*
		* @eventType VIDEO_NOT_AVAILABLE
		*/
		public static const VIDEO_NOT_AVAILABLE:String = "VIDEO_NOT_AVAILABLE";

        private static const INITIAL_FADE_OUT_DELAY:int = 3;

        private static const SUBTITLES_SIZE_SMALL:int = 14;
        private static const SUBTITLES_SIZE_NORMAL:int = 18;
        private static const SUBTITLES_SIZE_BIG:int = 23;

        private static const SUBTITLES_HEIGHT_SMALL:int = 45;
        private static const SUBTITLES_HEIGHT_NORMAL:int = 50;
        private static const SUBTITLES_HEIGHT_BIG:int = 60;

        private static const SUBTITLES_Y_OFFSET_SMALL:int = 75;
        private static const SUBTITLES_Y_OFFSET_NORMAL:int = 80;
        private static const SUBTITLES_Y_OFFSET_BIG:int = 85;

        private var _videoPlayerControls:VideoPlayerControls;
        private var _videoPlayerWithControls:VideoPlayerWithControls;

        // Some defaults just in case
        private var _videoWidth:Number = 600;
        private var _videoHeight:Number = 320;

        private var _timer:Timer = null;

        private var _subsText:Subtitler;
        private var _isFullScreen:Boolean = false;

        private var _subsSize:int = SUBTITLES_SIZE_NORMAL;
        private var _subsHeight:int = SUBTITLES_HEIGHT_NORMAL;
        private var _subsXPadding:int = 20;
        private var _subsYOffset:int = 95;

        private var _IS_TESTING:Boolean = false;

        /**
         * VideoPlayerWithControls example 
         */
        public function FlashVideoPlayer():void {
            if (_IS_TESTING) {
                this.init();
            }
        }

        public function init():void {
            this.opaqueBackground = 0x000000;

            var vars:Object = getFlashVars();
            var subsURL:String = (typeof vars['subtitle'] != 'undefined') ? vars['subtitle'] : "video/test.srt";
            var videoURL:String = (typeof vars['video'] != 'undefined') ? vars['video'] : "video/test.mp4";

            if (videoURL) {
                trace('>>> STAGE BEGINS AS: ' + stage.stageWidth + 'x' + stage.stageHeight);
                // Setup size if stage is ready, otherwise it'll use the defaults
                if (!_IS_TESTING && stage.stageWidth > 0 && stage.stageHeight > 0) {
                    _videoWidth = stage.stageWidth;
                    _videoHeight = stage.stageHeight;
                }
                stage.scaleMode = StageScaleMode.NO_SCALE;
                stage.align = StageAlign.TOP_LEFT;
                trace('>>> STAGE IS NOW: ' + stage.stageWidth + 'x' + stage.stageHeight);

                var controlsAsset:MovieClip = new VideoPlayerControlsAsset();
                _videoPlayerControls = new VideoPlayerControls(controlsAsset, _videoWidth, true);
                _videoPlayerWithControls = new VideoPlayerWithControls(_videoPlayerControls, _videoWidth, _videoHeight);

                // Add effects to controls
                initControls();
                addChild(_videoPlayerWithControls);

                if (subsURL) {
                    setSubtitlesSize();
                    _subsText = new Subtitler(_videoPlayerWithControls, subsURL, _videoWidth, _videoHeight);
                    _subsText.addEventListener(Subtitler.SUBTITLES_LOADED, function(ev:*):void {
                        setupSubtitles();
                        _videoPlayerWithControls.getClickableArea().addChild(_subsText);
                        _videoPlayerWithControls.loadVideo(videoURL, true);
                    });
                    _subsText.addEventListener(Subtitler.SUBTITLES_ERROR, function(ev:*):void {
                        trace("[FlashVideoPlayer] Could not load subtitles!");
                        _videoPlayerWithControls.loadVideo(videoURL, true);
                    });
                } else {
                    trace("[FlashVideoPlayer] no subtitles stuff needed");
                    _videoPlayerWithControls.loadVideo(videoURL);
                }
            } else {
                trace("[FlashVideoPlayer] no video to play!");
            }
        }

        private function getFlashVars():Object {
            return LoaderInfo(this.loaderInfo).parameters;
        }

        private function setSubtitlesSize():void {
            var vars:Object = getFlashVars();
            var _size:String = (typeof vars['subtitleSize'] != 'undefined') ? vars['subtitleSize'] : 'normal';
            if (_size == 'big') {
                _subsSize = SUBTITLES_SIZE_BIG;
                _subsHeight = SUBTITLES_HEIGHT_BIG;
                _subsYOffset = SUBTITLES_Y_OFFSET_BIG;
            } else if (_size == 'small') {
                _subsSize = SUBTITLES_SIZE_SMALL;
                _subsHeight = SUBTITLES_HEIGHT_SMALL;
                _subsYOffset = SUBTITLES_Y_OFFSET_SMALL;
            } else {
                _subsSize = SUBTITLES_SIZE_NORMAL;
                _subsHeight = SUBTITLES_HEIGHT_NORMAL;
                _subsYOffset = SUBTITLES_Y_OFFSET_NORMAL;
            }
        }

        private function initControls():void {
            _videoPlayerControls.addEventListener(MouseEvent.ROLL_OVER, onControlsRollOver);
            _videoPlayerControls.addEventListener(MouseEvent.ROLL_OUT, onControlsRollOut);

            _videoPlayerWithControls.addEventListener(Event.ENTER_FRAME, initialControlsTween);
            _videoPlayerWithControls.addEventListener(VideoPlayerWithControls.STOPPED_MOVIE, onStoppedMovie);
            _videoPlayerWithControls.addEventListener(VideoPlayer.VIDEO_NOT_AVAILABLE, onVideoNotFound);
        }

        private function onStoppedMovie(event:Event):void {
            destroy();
            dispatchEvent(new Event(STOPPED_MOVIE));
        }

        private function onVideoNotFound(event:Event):void {
            destroy();
            dispatchEvent(new Event(VIDEO_NOT_AVAILABLE));
        }

        public function destroy():void {
            stage.removeEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
            _videoPlayerWithControls.destroy();
            _videoPlayerControls.removeEventListener(MouseEvent.ROLL_OVER, onControlsRollOver);
            _videoPlayerControls.removeEventListener(MouseEvent.ROLL_OUT, onControlsRollOut);
            _videoPlayerWithControls.removeEventListener(VideoPlayer.VIDEO_NOT_AVAILABLE, onVideoNotFound);
            _videoPlayerWithControls.removeEventListener(VideoPlayerWithControls.STOPPED_MOVIE, onStoppedMovie);
        }


        private function initialControlsTween(event:Event):void {
            TweenMax.delayedCall(INITIAL_FADE_OUT_DELAY, function():void {
                TweenMax.to(_videoPlayerControls, 1.0, {alpha:0.0, overwrite:1});
            });
            _videoPlayerWithControls.removeEventListener(Event.ENTER_FRAME, initialControlsTween);
        }

        protected function onControlsRollOver(event:MouseEvent):void {
            TweenMax.to(_videoPlayerControls, 0.25, {alpha:1.0, overwrite:1});
        }

        protected function onControlsRollOut(event:MouseEvent):void {
            TweenMax.to(_videoPlayerControls, 0.75, {alpha:0.0, overwrite:1});
        }

        private function setupSubtitles():void {
            var _format:TextFormat = new TextFormat();
            _format.font = "Arial";
            _format.color = 0xFFFFFF;
            _format.size = _subsSize;
            _format.bold = true;
            _format.align = TextFormatAlign.CENTER;

            var outline:GlowFilter = new GlowFilter();
            outline.blurX = outline.blurY = 3;
            outline.color = 0x000000;
            outline.quality = BitmapFilterQuality.MEDIUM;
            outline.strength = 100;

            var filterArray:Array = new Array();
            filterArray.push(outline);
            _subsText.filters = filterArray;

            _subsText.defaultTextFormat = _format;
            _subsText.setTextFormat(_format);

            _subsText.antiAliasType = AntiAliasType.NORMAL;
            //_subsText.autoSize = TextFieldAutoSize.CENTER;
            _subsText.width= _videoWidth - _subsXPadding;
            _subsText.height = _subsHeight;
            _subsText.x = _subsXPadding / 2;
            _subsText.y = _videoHeight - _subsYOffset;
            _subsText.selectable = false;
            _subsText.border = false;
            //_subsText.border = true;
            //_subsText.borderColor = 0xFF000;

            stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullScreen);
        }

        private function onFullScreen(ev:FullScreenEvent):void {
            if (ev.fullScreen) { // Entering full screen
                _isFullScreen = true;
                //doResizing();
            } else { // Leaving full screen
                _isFullScreen = false;
                //doResizing();
            }
            trace('>>> STAGE IS NOW: ' + stage.stageWidth + 'x' + stage.stageHeight);
            TweenMax.to(_videoPlayerControls, 0.75, {alpha:0.0, overwrite:1});
        }

        private function doResizing(ev:Event = null):void {
            var _scaleX:Number = 1.0;
            var _scaleY:Number = 1.0;
            if (_isFullScreen) {
                //var ratio:int = (stage.fullScreenWidth / _videoWidth);
                var ratio:Number = (stage.fullScreenWidth / _videoWidth);
                _subsText.scaleX = (_subsText.scaleY = ratio);
                _subsText.x = (_subsXPadding * ratio) / 2;
                _subsText.y = (stage.fullScreenHeight - ((_subsYOffset * 0.95) * ratio));
            } else {
                _subsText.scaleX = _scaleX;
                _subsText.scaleY = _scaleY;
                _subsText.x = _subsXPadding / 2;
                _subsText.y = _videoHeight - _subsYOffset;
            }
        }
    }
}
