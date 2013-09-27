package media
{
	import events.NetStreamClientEvent;
	import events.StreamingEvent;
	import events.VideoRecorderEvent;
	
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
	import flash.net.NetStreamInfo;
	import flash.utils.ByteArray;
	
	import mx.utils.ObjectUtil;
	
	import org.as3commons.logging.api.ILogger;
	import org.as3commons.logging.api.getLogger;
	
	import utils.Helpers;


	public class NetStreamClient extends EventDispatcher implements INetStreamClientCallbacks
	{
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

		private var _ns:NetStream;
		private var _nc:NetConnection;
		private var _name:String;
		private var _connected:Boolean;
		private var _streamStatus:uint;

		//Media resource metadata
		private var _videoWidth:uint;
		private var _videoHeight:uint;
		private var _duration:Number;
		private var _hasVideo:Boolean;
		private var _hasAudio:Boolean;

		private var _audioCodecID:Number;
		private var _videoCodecID:Number;
		private var _frameRate:Number;
		private var _audioSampleRate:Number;
		private var _audioSampleSize:Number;
		private var _fileSize:Number;
		private var _videoDataRate:Number;
		private var _audioDataRate:Number;
		private var _stereo:Boolean;
		private var _canSeekToEnd:Boolean;

		private var _metaData:Object;
		
		private var _parsedUrl:Object;
		
		private var _baseUrl:String;
		private var _streamUrl:String;

		private static const logger:ILogger=getLogger(NetStreamClient);


		private var _mediaManager:MediaManager;

		public function NetStreamClient(url:String, name:String)
		{
			super();

			_streamStatus=STREAM_UNREADY;
			_duration=0; //Until we receiving metadata set the duration to 0
			_name=name;

			if (isStreamingUrl(url))
			{
				//Have to split the baseurl from the stream fragment
				_parsedUrl = Helpers.parseRTMPUrl(url)
				if(_parsedUrl){
					_baseUrl = _parsedUrl[1];
					_streamUrl = _parsedUrl[2];
				}
			} else {
				_streamUrl = url;
			}
			//initiateMediaManager(_baseUrl);
		}
		
		public function setup():void{
			initiateMediaManager(_baseUrl);
		}

		private function initiateNetStream(connection:NetConnection):void
		{
			try
			{
				_ns=new NetStream(connection);
				_ns.client=this;
				logger.debug("[{0}] Initiating NetStream...", [_name]);
				_ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onAsyncError);
				_ns.addEventListener(DRMErrorEvent.DRM_ERROR, onDrmError);
				_ns.addEventListener(DRMStatusEvent.DRM_STATUS, onDrmStatus);
				_ns.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
				_ns.addEventListener(NetDataEvent.MEDIA_TYPE_DATA, onMediaTypeData);
				_ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
				_ns.addEventListener(StatusEvent.STATUS, onStatus);
				
				_nc=connection;
				_connected=true;
				dispatchEvent(new NetStreamClientEvent(NetStreamClientEvent.NETSTREAM_READY, _name));
			}
			catch (e:Error)
			{
				//netconnection is not connected
				_connected=false;
				logger.error("[{0}] Instantiation Error [{1}] {2}", [_name, e.name, e.message]);
			}
		}

		/**
		 *
		 */

		private function isStreamingUrl(url:String):Boolean
		{
			return (url.search(/^rtmp/) !=-1) ? true : false;
		}

		private function initiateMediaManager(server:String):void
		{
			if(server)
				_mediaManager=new RTMPMediaManager();
			else
				_mediaManager=new MediaManager();
			_mediaManager.addEventListener(StreamingEvent.CONNECTED_CHANGE, onConnectionStatusChange);
			_mediaManager.connect(server);
		}

		private function onConnectionStatusChange(e:StreamingEvent):void
		{
			logger.debug("[{0}] Connection status changed", [_name]);
			if (_mediaManager.netConnected)
			{
				initiateNetStream(_mediaManager.netConnection);
			} else {
				//Dispatch an event to let the player know the netConnection failed for some reason.
			}
		}

		public function get connected():Boolean
		{
			return _connected;
		}

		public function play(/*params:Object*/):void
		{
			try
			{
				//logger.info("[{0}] Play {1}", [_name, Helpers.printObject(params)]);
				//_ns.play(params);
				logger.info("[{0}] Play {1}", [_name, _streamUrl]);
				_ns.play(_streamUrl);
			}
			catch (e:Error)
			{
				logger.error("[{0}] Play Error [{1}] {2}", [_name, e.name, e.message]);
			}
		}
		
		public function stop():void{
			logger.debug("Stop was called");
			if(_baseUrl)
				_ns.close();
			else
				_ns.play(false);
		}
		
		public function publish(mode:String='record'):void{
			_ns.publish(_streamUrl, mode);
		}

		/**
		 * if netstream uses a connection check the status if not (null nc for http connections) return the ns as is
		 *
		 */
		public function get netStream():NetStream
		{
			if (_nc)
			{
				return _nc.connected ? _ns : null;
			}
			else
			{
				return _ns;
			}
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

		public function get streamState():uint
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

		/*
		 * Event listeners
		 */
		public function onAsyncError(event:AsyncErrorEvent):void
		{

			logger.error("[{0}] AsyncError {1} {2}", [_name, event.error.name, event.error.message]);
		}

		public function onDrmError(event:DRMErrorEvent):void
		{
			logger.error("[{0}] DRM Error", [_name]);
		}

		public function onDrmStatus(event:DRMStatusEvent):void
		{
			logger.error("[{0}] DRM Status", [_name]);
		}

		public function onIoError(event:IOErrorEvent):void
		{
			logger.error("[{0}] AsyncError {1} {2}", [_name, event.target.toString(), event.text]);
		}

		public function onMediaTypeData(event:NetDataEvent):void
		{
			//logger.info("[{0}] MediaTypeData callback", [_name]);
			//logger.debug("[{0}] MediaTypeData {1}", [_name, Helpers.printObject(event.toString())]);
		}

		public function onNetStatus(event:NetStatusEvent):void
		{
			var info:Object=event.info;
			var messageClientId:int=info.clientid ? info.clientid : -1;
			var messageCode:String=info.code;
			var messageDescription:String=info.description ? info.description : '';
			var messageDetails:String=info.details ? info.details : '';
			var messageLevel:String=info.level;
			logger.debug("[{0}] NetStatus [{1}] {2} {3}", [_name, messageLevel, messageCode, messageDescription]);
			switch (messageCode)
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
						dispatchEvent(new NetStreamClientEvent(NetStreamClientEvent.PLAYBACK_STARTED, _name));
					}
					if (_streamStatus == STREAM_BUFFERING)
						_streamStatus=STREAM_STARTED;
					if (_streamStatus == STREAM_UNPAUSED)
						_streamStatus=STREAM_STARTED;
					if (_streamStatus == STREAM_SEEKING_END)
						_streamStatus = STREAM_STARTED;

					break;
				case "NetStream.Buffer.Flush":
					break;
				case "NetStream.Publish.Start":
					break;
				case "NetStream.Publish.Idle":
					break;
				case "NetStream.Unpublish.Success":
					break;
				case "NetStream.Play.Start":
					_streamStatus=STREAM_READY;
					break;
				case "NetStream.Play.Stop":
					_streamStatus=STREAM_STOPPED;
					break;
				case "NetStream.Play.Reset":
					break;
				case "NetStream.Play.PublishNotify":
					break;
				case "NetStream.Play.UnpublishNotify":
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
					dispatchEvent(new NetStreamClientEvent(NetStreamClientEvent.STREAM_NOT_FOUND, _name));
					break;
				case "NetStream.Play.Transition":
					break;
				case "NetStream.Pause.Notify":
					_streamStatus=STREAM_PAUSED;
					break;
				case "NetStream.Unpause.Notify":
					_streamStatus=STREAM_UNPAUSED;
					break;
				case "NetStream.Record.Start":
					break;
				case "NetStream.Record.Stop":
					break;
				case "NetStream.Seek.Notify":
					_streamStatus=STREAM_SEEKING_START;
					break;
				case "NetStream.SeekStart.Notify":
					_streamStatus=STREAM_SEEKING_START;
					break;
				case "NetStream.Seek.Complete":
					_streamStatus=STREAM_SEEKING_END;
					break;
				default:
					break;
			}
			dispatchEvent(new NetStreamClientEvent(NetStreamClientEvent.STATE_CHANGED, _name, _streamStatus));

		}

		public function onStatus(event:StatusEvent):void
		{
			logger.info("[{0}] Status callback", [_name]);
			logger.debug("[{0}] Status {1}", [_name, Helpers.printObject(event)]);
		}

		/*
		 * Client object callbacks
		 */
		public function onCuePoint(cuePoint:Object):void
		{
			logger.info("[{0}] CuePoint callback", [_name]);
			logger.debug("[{0}] CuePoint {1}", [_name, Helpers.printObject(cuePoint)]);
		}

		public function onImageData(imageData:Object):void
		{
			var rawData:ByteArray=imageData.data as ByteArray;
			logger.info("[{0}] ImageData callback", [_name]);
		}

		public function onMetaData(metaData:Object):void
		{
			//logger.info("[{0}] MetaData callback", [_name]);
			logger.debug("[{0}] MetaData {1}", [_name, Helpers.printObject(metaData)]);

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

			dispatchEvent(new NetStreamClientEvent(NetStreamClientEvent.METADATA_RETRIEVED, _name));
		}

		public function onPlayStatus(playStatus:Object):void
		{
			logger.debug("[{0}] PlayStatus [{1}] {2}", [_name, playStatus.level, playStatus.code]);
			//if(playStatus.code == "NetStream.Play.Complete"){
			//	_streamStatus=STREAM_FINISHED;
			//	dispatchEvent(new NetStreamClientEvent(NetStreamClientEvent.STATE_CHANGED, _name, _streamStatus));
			//}
			//logger.debug("[{0}] PlayStatus {1}", [_name, Helpers.printObject(playStatus)]);
		}

		public function onSeekPoint(seekPoint:Object):void
		{
			//logger.info("[{0}] SeekPoint callback", [_name]);
			//logger.debug("[{0}] SeekPoint {1}", [_name, Helpers.printObject(seekPoint)]);
		}

		public function onTextData(textData:Object):void
		{
			//logger.info("[{0}] TextData callback", [_name]);
			//logger.debug("[{0}] TextData {1}", [_name, Helpers.printObject(textData)]);
		}

		public function onXMPData(xmpData:Object):void
		{
			//data, a string The string is generated from a top-level UUID box. 
			//(The 128-bit UUID of the top level box is BE7ACFCB-97A9-42E8-9C71-999491E3AFAC.) This top-level UUID box contains exactly one XML document represented as a null-terminated UTF-8 string.
			//logger.info("[{0}] XMPData callback", [_name]);
			//logger.debug("[{0}] XMPData {1}", [_name, Helpers.printObject(xmpData)]);
		}
	}
}
