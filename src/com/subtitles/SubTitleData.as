package com.subtitles {

    public class SubTitleData {

        public var text:String;
        public var start:Number;
        public var duration:Number;
        public var end:Number;

        public function SubTitleData(_arg1:String="", _arg2:Number=0, _arg3:Number=0, _arg4:Number=0){
            this.text = _arg1;
            this.start = _arg2;
            this.duration = _arg3;
            this.end = _arg4;
        }
        public function toString():void{
            trace("nl.inlet42.data.subtitles.SubTitleData");
        }

    }
}//package com.subtitles 
