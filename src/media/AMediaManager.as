package media
{
	import events.NetStreamClientEvent;
	
	import flash.events.AsyncErrorEvent;
	import flash.events.DRMErrorEvent;
	import flash.events.DRMStatusEvent;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NetDataEvent;
	import flash.events.NetStatusEvent;
	import flash.events.StatusEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.ByteArray;
	
	import org.as3commons.logging.api.ILogger;
	import org.as3commons.logging.api.getLogger;
	
	import utils.Helpers;

	public class AMediaManager extends EventDispatcher implements INetConnectionCallbacks, INetStreamCallbacks
	{
		protected static const logger:ILogger=getLogger((AMediaManager);
		
		//Stream state info
		public static const STREAM_UNREADY:int=-1;
		public static const STREAM_READY:int=0;
		public static const STREAM_STARTED:int=1;
		public static const STREAM_STOPPED:int=2;
		public static const STREAM_FINISHED:int=3;
		public static const STREAM_PAUSED:int=4;
		public static const STREAM_UNPAUSED:int=5;
		public static const STREAM_BUFFERING:int=6;
		public static const STREAM_SEEKING_START:int=7;
		public static const STREAM_SEEKING_END:int=8;
		
		protected var _streamStatus:int;
		
		protected var _ns:NetStream;
		protected var _nc:NetConnection;
		protected var _connected:Boolean;
	
		//Instance id
		protected var _id:String;
			
		//Metadata about the media resource that's being loaded
		protected var _metaData:Object;	
		protected var _duration:Number;
		protected var _hasVideo:Boolean;
		protected var _hasAudio:Boolean;
		protected var _audioCodecID:Number;
		protected var _videoCodecID:Number;
		protected var _videoWidth:uint  = 320;
		protected var _videoHeight:uint = 240;
		protected var _frameRate:Number;
		protected var _audioSampleRate:Number;
		protected var _audioSampleSize:Number;
		protected var _fileSize:Number;
		protected var _videoDataRate:Number;
		protected var _audioDataRate:Number;
		protected var _stereo:Boolean;
		protected var _canSeekToEnd:Boolean;
		
		
		
		public function AMediaManager(url:String, id:String)
		{
			super();
		}
		
		public function setup():void{
			
		}
		
		public function get hasVideo():Boolean
		{
			return _hasVideo;
		}
		
		public function get hasAudio():Boolean
		{
			return _hasAudio;
		}
		
		public function get videoWidth():uint
		{
			return _videoWidth;
		}
		
		public function get videoHeight():uint
		{
			return _videoHeight;
		}
		
		public function get duration():Number
		{
			return _duration;
		}
		
		public function get streamState():int
		{
			return _streamStatus;
		}
		
		public function get metaData():Object
		{
			return _metaData;
		}
		
		public function get loadedFraction():Number
		{
			return _ns.bytesLoaded / _ns.bytesTotal;
		}
		
		public function get currentTime():Number
		{
			return _ns.time;
		}
		
		/**
		 * NetStream Event listeners
		 */
		protected function onAsyncError(event:AsyncErrorEvent):void
		{
			logger.error("[{0}] AsyncError {1} {2}", [_id, event.error.name, event.error.message]);
		}
		
		protected function onDrmError(event:DRMErrorEvent):void
		{
			logger.error("[{0}] DRM Error", [_id]);
		}
		
		protected function onDrmStatus(event:DRMStatusEvent):void
		{
			logger.error("[{0}] DRM Status", [_id]);
		}
		
		protected function onIoError(event:IOErrorEvent):void
		{
			logger.error("[{0}] AsyncError {1} {2}", [_id, event.target.toString(), event.text]);
		}
		
		protected function onMediaTypeData(event:NetDataEvent):void
		{
			//logger.info("[{0}] MediaTypeData callback", [_name]);
			//logger.debug("[{0}] MediaTypeData {1}", [_name, Helpers.printObject(event.toString())]);
		}
		
		protected function onNetStatus(event:NetStatusEvent):void{
			var info:Object=event.info;
			var messageClientId:int=info.clientid ? info.clientid : -1;
			var messageCode:String=info.code;
			var messageDescription:String=info.description ? info.description : '';
			var messageDetails:String=info.details ? info.details : '';
			var messageLevel:String=info.level;
			logger.debug("[{0}] NetStatus [{1}] {2} {3}", [_id, messageLevel, messageCode, messageDescription]);
		}
		
		protected function onStatus(event:StatusEvent):void
		{
			logger.info("[{0}] Status callback", [_id]);
			logger.debug("[{0}] Status {1}", [_id, Helpers.printObject(event)]);
		}
		
		/**
		 * INetConnectionCallbacks
		 */
		protected function onBWCheck(info:Object=null):void{
			
		}
		
		protected function onBWDone(info:Object=null):void{
			
		}
		
		
		/**
		 * INetStreamCallbacks
		 */
		protected function onCuePoint(cuePoint:Object):void{
			logger.info("[{0}] CuePoint callback", [_id]);
			logger.debug("[{0}] CuePoint {1}", [_id, Helpers.printObject(cuePoint)]);
		}
		
		protected function onImageData(imageData:Object):void{
			var rawData:ByteArray=imageData.data as ByteArray;
			logger.info("[{0}] ImageData callback", [_id]);
		}
		
		protected function onMetaData(metaData:Object):void{
			logger.debug("[{0}] MetaData {1}", [_id, Helpers.printObject(metaData)]);
			
			_metaData=metaData;
			_duration=metaData.duration ? metaData.duration : _duration;
			
			_videoWidth=metaData.width ? metaData.width : _videoWidth;
			_videoHeight=metaData.height ? metaData.height : _videoHeight;
			
			_hasVideo=(metaData.videocodecid && metaData.videocodecid != -1) ? true : _hasVideo;
			_hasAudio=(metaData.audiocodecid && metaData.audiocodecid != -1) ? true : _hasAudio;
			
			_audioCodecID=metaData.audiocodecid ? metaData.audiocodecid : _audioCodecID;
			_videoCodecID=metaData.videocodecid ? metaData.videocodecid : _videoCodecID;
			_frameRate=metaData.framerate ? metaData.framerate : _frameRate;
			_audioSampleRate=metaData.audiosamplerate ? metaData.audiosamplerate : _audioSampleRate;
			_audioSampleSize=metaData.aduiosamplesize ? metaData.audiosamplesize : _audioSampleSize;
			_fileSize=metaData.filesize ? metaData.filesize : _fileSize;
			_videoDataRate=metaData.videodatarate ? metaData.videodatarate : _videoDataRate;
			_audioDataRate=metaData.audiodatarate ? metaData.audiodatarate : _audioDataRate;
			_stereo=metaData.stereo ? metaData.stereo : _stereo;
			
			_canSeekToEnd=metaData.canSeekToEnd ? metaData.canSeekToEnd : _canSeekToEnd;
			
			dispatchEvent(new NetStreamClientEvent(NetStreamClientEvent.METADATA_RETRIEVED, _id));
		}
		
		protected function onPlayStatus(playStatus:Object):void{
			logger.debug("[{0}] PlayStatus [{1}] {2}", [_id, playStatus.level, playStatus.code]);
			//if(playStatus.code == "NetStream.Play.Complete"){
			//	_streamStatus=STREAM_FINISHED;
			//	dispatchEvent(new NetStreamClientEvent(NetStreamClientEvent.STATE_CHANGED, _name, _streamStatus));
			//}
			//logger.debug("[{0}] PlayStatus {1}", [_name, Helpers.printObject(playStatus)]);
		}
		
		protected function onSeekPoint(seekPoint:Object):void{
			//logger.info("[{0}] SeekPoint callback", [_name]);
			//logger.debug("[{0}] SeekPoint {1}", [_name, Helpers.printObject(seekPoint)]);
		}
		
		protected function onTextData(textData:Object):void{
			//logger.info("[{0}] TextData callback", [_name]);
			//logger.debug("[{0}] TextData {1}", [_name, Helpers.printObject(textData)]);
		}
		
		protected function onXMPData(xmpData:Object):void{
			//data, a string The string is generated from a top-level UUID box. 
			//(The 128-bit UUID of the top level box is BE7ACFCB-97A9-42E8-9C71-999491E3AFAC.) This top-level UUID box contains exactly one XML document represented as a null-terminated UTF-8 string.
			//logger.info("[{0}] XMPData callback", [_name]);
			//logger.debug("[{0}] XMPData {1}", [_name, Helpers.printObject(xmpData)]);
		}
	}
}