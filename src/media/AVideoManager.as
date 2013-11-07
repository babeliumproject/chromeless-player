package media
{
	import events.StreamingEvent;
	
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;

	public class AVideoManager extends AMediaManager
	{
		private var _streamUrl:String;
		
		public function AVideoManager(url:String, id:String)
		{
			super(url, id);
		}
		
		public function connect(... args):void{
			
			if(_nc)
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
		
		public function play(/*params:Object*/):void
		{
			try
			{
				//logger.info("[{0}] Play {1}", [_name, Helpers.printObject(params)]);
				//_ns.play(params);
				logger.info("[{0}] Play {1}", [_id, _streamUrl]);
				_ns.play(_streamUrl);
			}
			catch (e:Error)
			{
				logger.error("[{0}] Play Error [{1}] {2}", [_id, e.name, e.message]);
			}
		}
		
		public function stop():void{
			_ns.play(false);
		}
		
		public function seek(seconds:Number):void{
			if(!isNaN(seconds) && seconds >= 0 && seconds < duration){
				var reqFraction:Number = seconds/duration;
				//The user seeked to a time that is not yet cached. Try to load the media file from that point onwards (Pseudo-Streaming/Apache Mod h.264)
				if(loadedFraction < reqFraction){
					//play(?start=seconds)
				} else {
					_ns.seek(seconds);
				}
			}
		}
		
		public function publish():void{
			//HTTP media has no publish function
		}
		
		override protected function onNetStatus(event:NetStatusEvent):void{
			super.onNetStatus(event);
			
		}
	}
}