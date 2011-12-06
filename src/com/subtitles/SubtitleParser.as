package com.subtitles {

    public class SubtitleParser {

        public static function parseSRT(_arg1:String):Array{
            var _local3:Array;
            var _local4:SubTitleData;
            var _local6:String;
            var _local7:String;
            var _local8:Array;
            var _local2:Array = new Array();
            var _local5:Array = _arg1.split(/^[0-9]+$/gm);
            for each (_local6 in _local5) {
                _local4 = new SubTitleData();
                _local6 = _local6.replace(/\r/g, "\n");
                _local3 = _local6.split("\n");
                for each (_local7 in _local3) {
                    if (trim(_local7) != ""){
                        if (_local7.match("-->")){
                            _local8 = _local7.split(/[ ]+-->[ ]+/gm);
                            if (_local8.length != 2){
                                trace("Translation error, something wrong with the start or end time");
                            } else {
                                _local4.start = stringToSeconds(_local8[0]);
                                _local4.end = stringToSeconds(_local8[1]);
                                _local4.duration = (_local4.end - _local4.start);
                                if (_local4.duration < 0){
                                    trace("Translation error, something wrong with the start or end time");
                                };
                            };
                        } else {
                            if (_local4.text.length != 0){
                                _local7 = ("\n" + trim(_local7));
                            };
                            _local4.text = (_local4.text + _local7);
                        };
                    };
                };
                _local2.push(_local4);
            };
            return (_local2);
        }
        public static function trim(_arg1:String):String{
            if (_arg1 == null){
                return ("");
            };
            return (_arg1.replace(/^\s+|\s+$/g, ""));
        }
        public static function stringToSeconds(_arg1:String):Number{
            var _local2:Array = _arg1.split(":");
            var _local3:Number = 0;
            if (_arg1.substr(-1) == "s"){
                _local3 = Number(_arg1.substr(0, (_arg1.length - 1)));
            } else {
                if (_arg1.substr(-1) == "m"){
                    _local3 = (Number(_arg1.substr(0, (_arg1.length - 1))) * 60);
                } else {
                    if (_arg1.substr(-1) == "h"){
                        _local3 = (Number(_arg1.substr(0, (_arg1.length - 1))) * 3600);
                    } else {
                        if (_local2.length > 1){
                            if (((_local2[2]) && (!((String(_local2[2]).indexOf(",") == -1))))){
                                _local2[2] = String(_local2[2]).replace(/\,/, ".");
                            };
                            _local3 = Number(_local2[(_local2.length - 1)]);
                            _local3 = (_local3 + (Number(_local2[(_local2.length - 2)]) * 60));
                            if (_local2.length == 3){
                                _local3 = (_local3 + (Number(_local2[(_local2.length - 3)]) * 3600));
                            };
                        } else {
                            _local3 = Number(_arg1);
                        };
                    };
                };
            };
            return (_local3);
        }

    }
}//package com.subtitles 
