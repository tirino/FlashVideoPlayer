package org.freevana {
    import net.ericpetersen.media.videoPlayer.VideoPlayerWithControls;
    import net.ericpetersen.media.videoPlayer.controls.VideoPlayerControls;

    import flash.display.LoaderInfo;
    import mx.core.FlexGlobals;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.events.*;
    import flash.text.TextField;
    import com.subtitles.*;
    
    import flash.filesystem.File;

    /**
     * @author tirino
     */
    public class Subtitler extends TextField {
		/**
		* Dispatched when subtitles are fully loaded
		*
		* @eventType SUBTITLES_LOADED
		*/
		public static const SUBTITLES_LOADED:String = "SUBTITLES_LOADED";

		/**
		* Dispatched when subtitles cannot be loaded
		*
		* @eventType SUBTITLES_ERROR
		*/
		public static const SUBTITLES_ERROR:String = "SUBTITLES_ERROR";

        private var _videoWidth:Number;
        private var _videoHeight:Number;
        
        private var _videoPlayerControls:VideoPlayerControls;
        private var _videoPlayerWithControls:VideoPlayerWithControls;
        private var _subtitleURL:String;

        private var _subsEnabled:Boolean = true;
        private var _subtitles:Array;
        private var _lastSubIdx:int;

        /**
         * SubtitlesHandler
         */
        public function Subtitler(videoPlayerWithControls:VideoPlayerWithControls, subtitleURL:String, videoWidth:Number, videoHeight:Number):void {
            _videoPlayerWithControls = videoPlayerWithControls;
            _videoPlayerControls = _videoPlayerWithControls.getControls();
            _subtitleURL = subtitleURL;
            _videoWidth = videoWidth;
            _videoHeight = videoHeight;
            loadSubtitles();
        }

        private function loadSubtitles():void {
            var subsLoader:URLLoader = new URLLoader();
            subsLoader.addEventListener(Event.COMPLETE, onSubtitlesLoaded);
            
            subsLoader.addEventListener(Event.CANCEL, onSubtitlesError);
            subsLoader.addEventListener(Event.SELECT, onSubtitlesError);
            subsLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onSubtitlesError);
            subsLoader.addEventListener(IOErrorEvent.IO_ERROR, onSubtitlesError);
            subsLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSubtitlesError);
            subsLoader.load(new URLRequest(_subtitleURL));

            function onSubtitlesLoaded(ev:Event):void {
                trace('loaded subs!');
                _subtitles = SubtitleParser.parseSRT(ev.target.data);
                build();
                dispatchEvent(new Event(SUBTITLES_LOADED));
            }

            function onSubtitlesError(ev:Event):void {
                trace('error with subs!');
                dispatchEvent(new Event(SUBTITLES_ERROR));
            }
        }

        private function build():void {
            _videoPlayerControls.addEventListener(VideoPlayerControls.SUBTITLES_DISABLED, onSubtitlesDisabled);
            _videoPlayerControls.addEventListener(VideoPlayerControls.SUBTITLES_ENABLED, onSubtitlesEnabled);
            _videoPlayerWithControls.addEventListener(Event.ENTER_FRAME, subsEnterFrameHandler, false, 0, true);

        }
        public function destroy():void {
            _videoPlayerControls.removeEventListener(VideoPlayerControls.SUBTITLES_DISABLED, onSubtitlesDisabled);
            _videoPlayerControls.removeEventListener(VideoPlayerControls.SUBTITLES_ENABLED, onSubtitlesEnabled);
            _videoPlayerWithControls.removeEventListener(Event.ENTER_FRAME, subsEnterFrameHandler);
        }

        private function onSubtitlesEnabled(event:Event):void {
            _subsEnabled = true;
        }

        private function onSubtitlesDisabled(event:Event):void {
            _subsEnabled = false;
        }

        private function subsEnterFrameHandler(ev:Event):void {
            if (_subtitles != null) {
                if (_subsEnabled) {
                    var currentTime:Number = ev.target.getCurrentTime();
                    var subShow:Boolean = false;
                    var subIdx:int = 1;
                    while (subIdx < _subtitles.length) {
                        if ((_subtitles[subIdx].start <= currentTime) && (_subtitles[subIdx].end > currentTime)) {
                            subShow = true;
                            this.htmlText = _subtitles[subIdx].text;
                            _lastSubIdx = subIdx;
                            break;
                        };
                        subIdx++;
                    };
                    if (!subShow) {
                        this.htmlText = "";
                    };

                } else {
                    this.htmlText = "";
                }
            }
        }
    }
}
