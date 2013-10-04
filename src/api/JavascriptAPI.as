package api
{

	
	import events.PollingEvent;
	import events.PrivacyEvent;
	import events.RecordingEvent;
	import events.VideoPlayerEvent;
	import events.VideoRecorderEvent;
	
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.utils.Dictionary;
	
	import media.RTMPMediaManager;
	
	import model.SharedData;
	
	import mx.utils.ObjectUtil;
	
	import player.VideoRecorder;
	
	public class JavascriptAPI
	{
		private static var instance:JavascriptAPI;
		private var VP:VideoRecorder;
		
		private var jsListeners:Dictionary = new Dictionary();
		
		/**
		 * Constructor
		 */
		public function JavascriptAPI(){}
		
		/**
		 * Initialize
		 * Adds CallBacks
		 */
		public function setup(VP:VideoRecorder):void
		{
			this.VP = VP;
			

			addCB("playVideo",VP.playVideo);
			addCB("pauseVideo",VP.pauseVideo);
			addCB("seekTo",VP.seekTo);
			
			addCB("recordStream", recordVideo);
			addCB("abortRecording", abortRecording);
				
			addCB("getVolume", getVolume);
			addCB("setVolume", setVolume);
			addCB("muteVideo", muteVideo);
			addCB("unMuteVideo", unMuteVideo);
			
			
			addCB("getDuration", duration);
			addCB("getCurrentTime", streamTime);
			addCB("getLoadedFragment", VP.getLoadedFragment);
			addCB("getBytesTotal", VP.getBytesTotal);
			addCB("getBytesLoaded", VP.getBytesLoaded);
		
			addCB("getState", getState);

			addCB("getMicActivityLevel", micActivityLevel);
			
			
			addCB("getRightStreamDuration", rightStreamDuration);
			addCB("getRightStreamCurrentTime", rightStreamTime);
			addCB("getRightStreamBytesTotal", VP.rightStreamBytesTotal);
			addCB("getRightStreamBytesLoaded", VP.rightStreamBytesLoaded);
			
			addCB("loadStreamByUrl", loadVideoByUrl);
			addCB("loadStreamById", loadVideoById);
			
			//Events
			addCB("addEventListener",addEventListener);
			addCB("removeEventListener",removeEventListener);
			
		}
		
		/**
		 * Instance of Extern
		 */
		public static function getInstance():JavascriptAPI
		{
			if ( !instance )
				instance = new JavascriptAPI()
			
			return instance;
		}
		
		/**
		 * Add callbacks for external controls
		 */
		private function addCB(func:String, callback:Function):void
		{
			try{
				ExternalInterface.addCallback(func,callback);
			}catch(e:Error){
				trace("Error ["+e.name+"] "+e.message);
			}
		}
		
		/**
		 * Videoplayer Ready
		 */
		public function onBabeliumPlayerReady():void
		{
			ExternalInterface.call("onBabeliumPlayerReady", ExternalInterface.objectID);
		}
		
		/**
		 * Tell JS that the connection is being successfully established
		 */
		public function onConnectionReady():void{
			ExternalInterface.call("onConnectionReady", ExternalInterface.objectID);
		}
		
		
		/**
		 * Resize dimensions
		 */
		public function resizeWidth(width:Number):void
		{
			ExternalInterface.call( 
				"function( id, w ) { document.getElementById(id).style.width = w + 'px'; }", 
				ExternalInterface.objectID, 
				width 
			);
		}
		
		public function resizeHeight(height:Number):void
		{
			ExternalInterface.call( 
				"function( id, h ) { document.getElementById(id).style.height = h + 'px'; }", 
				ExternalInterface.objectID, 
				height 
			);
		}
		
		/**
		 * Event handlers
		 */
		public function onEnterFrame(e:PollingEvent):void{
			ExternalInterface.call(jsListeners['onEnterFrame'], e.time);
		}
		
		public function onRecordingAborted(e:RecordingEvent):void{
			ExternalInterface.call(jsListeners['onRecordingAborted']);
		}
		
		public function onRecordingFinished(e:RecordingEvent):void{
			ExternalInterface.call(jsListeners['onRecordingFinished'], e.fileName);
		}
		
		public function onVideoStartedPlaying(e:VideoPlayerEvent):void{
			ExternalInterface.call(jsListeners['onVideoStartedPlaying']);
		}
		
		public function onMetadataRetrieved(e:Event):void{
			ExternalInterface.call(jsListeners['onMetadataRetrieved']);
		}
		
		public function onStreamStateChange(e:VideoPlayerEvent):void{
			ExternalInterface.call(jsListeners['onStreamStateChange'], e.state);
		}
		
		public function onDeviceStateChange(e:PrivacyEvent):void{
			ExternalInterface.call(jsListeners['onDeviceStateChange'], e.state);
		}
		
		public function onRecorderStateChange(e:VideoRecorderEvent):void{
			ExternalInterface.call(jsListeners['onRecorderStateChange'], e.state);
		}
		
		
		private function autoPlay(flag:Boolean):void
		{
			VP.autoPlay = flag;
		}
		
		private function autoScale(flag:Boolean):void
		{
			VP.scaleToFit = flag;
		}
		
		private function duration():Number
		{
			return VP.duration;
		}
		
		private function seek(flag:Boolean):void
		{
			VP.seekable = flag;
		}
		
		private function getState():int{
			return VP.getState();
		}
		
		private function setState(st:int):void
		{
			VP.setState(st);
		}
		
		private function getVolume():Number{
			return VP.getVolume();
		}
		
		private function setVolume(value:Number):void{
			VP.setVolume(value);
		}
		
		private function muteVideo():void{
			VP.mute=true;
		}
		
		private function unMuteVideo():void{
			VP.mute=false;
		}
		
		private function streamTime():Number
		{
			return VP.streamTime;
		}
		
		private function rightStreamTime():Number{
			return VP.rightStreamTime;
		}
		
		private function rightStreamDuration():Number{
			
			return VP.rightStreamDuration;
		}
		
		private function micActivityLevel():Number{
			if (SharedData.getInstance().privacyManager.microphone)
				return SharedData.getInstance().privacyManager.microphone.activityLevel;
			else
				return -1;
		}
		
		private function exerciseSource(video:String):void
		{
			//VP.videoSource = SharedData.getInstance().streamingManager.exerciseStreamsFolder + "/" + video;
			VP.loadVideoById(video);
		}
		
		private function responseSource(video:String):void{
			//VP.videoSource = SharedData.getInstance().streamingManager.responseStreamsFolder + "/" + video;
			VP.loadVideoById(video);
		}
		
		private function recordVideo(useWebcam:Boolean, exerciseId:String = null, recdata:Object = null):String{
			return VP.recordVideo(useWebcam, exerciseId, recdata);
		}
		
		private function loadVideoByUrl(url:String):void{
			VP.loadVideoByUrl(url);
		}
		
		private function loadVideoById(id:String):void{
			VP.loadVideoById(id);
		}
		
		private function abortRecording():void{
			VP.abortRecording();
		}
		
		//private function addEventListener(event:String, listener:String):void{ //added generic argument type and count to avoid a Windows Flash player bug
		private function addEventListener(... args):void{
			if(args.length < 2 )
				return;
			var listener:String = (args[1] is String) ? args[1] : null;
			var event:String = (args[0] is String) ? args[0] : null;
			if(!listener || !event)
				return;
			
			switch(event){
				case 'onEnterFrame':
					jsListeners['onEnterFrame'] = listener;
					VP.addEventListener(PollingEvent.ENTER_FRAME, onEnterFrame);
					break;
				case 'onRecordingAborted':
					jsListeners['onRecordingAborted'] = listener;
					VP.addEventListener(RecordingEvent.ABORTED, onRecordingAborted);
					break;
				case 'onRecordingFinished':
					jsListeners['onRecordingFinished'] = listener;
					VP.addEventListener(RecordingEvent.END, onRecordingFinished);
					break;
				case 'onVideoStartedPlaying':
					jsListeners['onVideoStartedPlaying'] = listener;
					VP.addEventListener(VideoPlayerEvent.VIDEO_STARTED_PLAYING, onVideoStartedPlaying);
					break;
				case 'onMetadataRetrieved':
					jsListeners['onMetadataRetrieved'] = listener;
					VP.addEventListener(VideoPlayerEvent.METADATA_RETRIEVED, onMetadataRetrieved);
				case 'onVideoPlayerReady':
					//jsListeners['onVideoPlayerReady'] = listener;
					//VP.addEventListener(VideoPlayerEvent.CONNECTED, onVideoPlayerReady);
					break;
				case 'onStreamStateChange':
					jsListeners['onStreamStateChange'] = listener;
					VP.addEventListener(VideoPlayerEvent.STREAM_STATE_CHANGED, onStreamStateChange);
				case 'onDeviceStateChange':
					jsListeners['onDeviceStateChange'] = listener;
					VP.addEventListener(PrivacyEvent.DEVICE_STATE_CHANGE, onDeviceStateChange);
				case 'onRecorderStateChange':
					jsListeners['onRecorderStateChange'] = listener;
					VP.addEventListener(VideoRecorderEvent.RECORDER_STATE_CHANGED, onRecorderStateChange);
					
				default:
					break;
			}
		}
		
		private function removeEventListener(...args):void{
			if(args.length < 2 )
				return;
			var listener:String = (args[1] is String) ? args[1] : null;
			var event:String = (args[0] is String) ? args[0] : null;
			if(!listener || !event)
				return;
			
			switch(event){
				case 'onEnterFrame':
					if(jsListeners['onEnterFrame'])
						delete jsListeners['onEnterFrame'];
					VP.removeEventListener(PollingEvent.ENTER_FRAME, onEnterFrame);
					break;
				case 'onRecordingAborted':
					if(jsListeners['onRecordingAborted'])
						delete jsListeners['onRecordingAborted'];
					VP.removeEventListener(RecordingEvent.ABORTED, onRecordingAborted);
					break;
				case 'onRecordingFinished':
					if(jsListeners['onRecordingFinished'])
						delete jsListeners['onRecordingFinished'];
					VP.removeEventListener(RecordingEvent.END, onRecordingFinished);
					break;
				case 'onVideoStartedPlaying':
					if(jsListeners['onVideoStartedPlaying'])
						delete jsListeners['onVideoStartedPlaying'];
					VP.removeEventListener(VideoPlayerEvent.VIDEO_STARTED_PLAYING, onVideoStartedPlaying);
					break;	
				case 'onMetadataRetrieved':
					if(jsListeners['onMetadataRetrieved'])
						delete jsListeners['onMetadataRetrieved'];
					VP.removeEventListener(VideoPlayerEvent.METADATA_RETRIEVED, onMetadataRetrieved);
				case 'onStateChange':
					if(jsListeners['onStreamStateChange'])
						delete jsListeners['onStreamStateChange'];
					VP.removeEventListener(VideoPlayerEvent.STREAM_STATE_CHANGED, onStreamStateChange);
				case 'onRecordedStateChange':
					if(jsListeners['onRecorderStateChange'])
						delete jsListeners['onRecorderStateChange'];
					VP.removeEventListener(VideoRecorderEvent.RECORDER_STATE_CHANGED, onRecorderStateChange);
				default:
					break;
			}
		}
		
	}
}