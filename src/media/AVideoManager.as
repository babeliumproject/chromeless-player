package media
{
	import events.NetStreamClientEvent;
	import events.StreamingEvent;
	
	import flash.events.AsyncErrorEvent;
	import flash.events.DRMErrorEvent;
	import flash.events.DRMStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.NetDataEvent;
	import flash.events.NetStatusEvent;
	import flash.events.StatusEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	import utils.Helpers;

	public class AVideoManager extends AMediaManager
	{
		
		private var _startTime:Number;
		private var _endTime:Number;
		
		
		public function AVideoManager(id:String)
		{
			super(id);
		}
		
		override public function setup(... args):void{
			_startTime=0;
			_endTime=0;
			if(args.length){
				_streamUrl = (args[0] is String) ? args[0] : '';
				
				//Check if the url contains start/end fragments
				var fragments:Array = new Array();//Helpers.parseUrl(_streamUrl);
				
				var startFragment:RegExp=new RegExp(".+?\?.+start=([0-9\.]+)");
				var endFragment:RegExp=new RegExp(".+?\?.+end=([0-9\.]+)");
				
				var sresult:Array = startFragment.exec(fragments[2]);
				if(sresult)
					_startTime=Math.round(sresult[1]);
				var eresult:Array = endFragment.exec(fragments[2]);
				if(eresult)
					_endTime=Math.round(eresult[1]);
			}
			this.addEventListener(StreamingEvent.CONNECTED_CHANGE, onConnectionStatusChange);
			connect();
		}
		
		private function connect():void{
			
			_nc = new NetConnection();
			_nc.client=this;
			_nc.connect(null);
			_connected=true;
			dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
		}

		public function close():void
		{
			if (_nc)
			{
				_nc.close();
			}
		}
		
		override public function seek(seconds:Number):void{
			if(!isNaN(seconds) && seconds >= 0 && seconds < duration){
				var realseconds:Number = seconds - _startTime;
				var reqFraction:Number = realseconds/_duration;
				//The user seeked to a time that is not cached. Try to load the media file from that point onwards (Pseudo-Streaming/Apache Mod h.264)
				if(loadedFraction < reqFraction || realseconds < 0){
					//Remove any fragments first
					_streamUrl += '?start=' + Math.abs(realseconds);
					play();
				} else {
					_ns.seek(seconds);
				}
			}
		}
		
		override public function get duration():Number
		{
			return _connected ? (_startTime + _duration) : 0;
		}
		
		override public function get currentTime():Number
		{
			return _connected ? (_startTime + _ns.time) : 0;
		}
		
		override public function get startBytes():Number{
			return _ns && _duration ? _startTime * (_ns.bytesTotal / _duration) : 0;
		}
		
		override public function get bytesTotal():Number{
			//Make a calculus to get an estimate of the total bytes when the video starts playing from a point that is not the beginning
			return _ns ? startBytes + _ns.bytesTotal : 0;
		}
		
		override protected function onNetStatus(event:NetStatusEvent):void{
			super.onNetStatus(event);
			
			switch (_netStatusCode)
			{
				case "NetStream.Buffer.Empty":
					if (_streamStatus == STREAM_STOPPED)
					{
						_streamStatus=STREAM_FINISHED;
					}
					else
						_streamStatus=STREAM_BUFFERING;
					break;
				case "NetStream.Buffer.Full":			
					if (_streamStatus == STREAM_READY)
					{
						_streamStatus=STREAM_STARTED;
						dispatchEvent(new NetStreamClientEvent(NetStreamClientEvent.PLAYBACK_STARTED, _id));
					}
					if (_streamStatus == STREAM_BUFFERING)
						_streamStatus=STREAM_STARTED;
					if (_streamStatus == STREAM_UNPAUSED)
						_streamStatus=STREAM_STARTED;
					if (_streamStatus == STREAM_SEEKING_START)
						_streamStatus = STREAM_STARTED;
					
					break;
				case "NetStream.Buffer.Flush":
					break;
				case "NetStream.Play.Start":
					_streamStatus=STREAM_READY;
					break;
				case "NetStream.Play.Stop":
					_streamStatus=STREAM_STOPPED;
					break;
				case "NetStream.Play.Reset":
					break;
				case "NetStream.Play.Failed":
					break;
				case "NetStream.Play.FileStructureInvalid":
					break;
				case "NetStream.Play.InsufficientBW":
					break;
				case "NetStream.Play.NoSupportedTrackFound":
					break;
				case "NetStream.Play.StreamNotFound":
					dispatchEvent(new NetStreamClientEvent(NetStreamClientEvent.NETSTREAM_ERROR, _id, -1, "ERROR_STREAM_NOT_FOUND"));
					break;
				case "NetStream.Play.Transition":
					break;
				case "NetStream.Pause.Notify":
					_streamStatus=STREAM_PAUSED;
					break;
				case "NetStream.Unpause.Notify":
					if(_streamStatus==STREAM_PAUSED)
						_streamStatus=STREAM_STARTED;
					break;
				case "NetStream.Seek.Notify":
					_streamStatus=STREAM_SEEKING_START;
					break;
				case "NetStream.SeekStart.Notify":
					_streamStatus=STREAM_SEEKING_START;
					break;
				default:
					break;
			}
			dispatchEvent(new NetStreamClientEvent(NetStreamClientEvent.STATE_CHANGED, _id, _streamStatus));
		}
	}
}