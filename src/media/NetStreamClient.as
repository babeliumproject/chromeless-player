package media
{
	import events.NetStreamClientEvent;
	import events.VideoPlayerBabeliaEvent;
	
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
	
	import org.as3commons.logging.api.ILogger;
	import org.as3commons.logging.api.getLogger;


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

		private static const logger:ILogger=getLogger(NetStreamClient);

		/*
		 * Functions
		 */
		public function NetStreamClient(connection:NetConnection, name:String)
		{
			try
			{
				super();

				_streamStatus=STREAM_UNREADY;
				_ns=new NetStream(connection);
				_ns.client=this;
				_ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onAsyncError);
				_ns.addEventListener(DRMErrorEvent.DRM_ERROR, onDrmError);
				_ns.addEventListener(DRMStatusEvent.DRM_STATUS, onDrmStatus);
				_ns.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
				_ns.addEventListener(NetDataEvent.MEDIA_TYPE_DATA, onMediaTypeData);
				_ns.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
				_ns.addEventListener(StatusEvent.STATUS, onStatus);

				_nc=connection;
				_name=name;
				_connected=true;

			}
			catch (e:Error)
			{
				//netconnection is not connected
				_connected=false;
				logger.error("Instantiation Error [{0}] {1}", [e.name, e.message]);
			}
		}

		public function play(params:Object):void
		{
			try
			{
				logger.info("Play {0}", [printObject(params)]);
				_ns.play(params);
			}
			catch (e:Error)
			{
				logger.error("Play Error [{0}] {1}", [e.name, e.message]);
			}
		}

		/**
		 * if netstream uses a connection check the status if not (null nc for http connections) return the ns as is 
		 *
		 */	
		public function get netStream():NetStream
		{
			if(_ns){
				if(_nc){
					return _nc.connected ? _ns : null;
				} else {
					return _ns;
				}
			} else {
				return null;
			}
			
			//return (_ns && _nc && _nc.connected) ? _ns : null;
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

			logger.error("AsyncError {0} {1}", [event.error.name, event.error.message]);
		}

		public function onDrmError(event:DRMErrorEvent):void
		{
			logger.error("DRM Error");
		}

		public function onDrmStatus(event:DRMStatusEvent):void
		{
			logger.error("DRM Status");
		}

		public function onIoError(event:IOErrorEvent):void
		{
			logger.error("AsyncError {0} {1}", [event.target.toString(), event.text]);
		}

		public function onMediaTypeData(event:NetDataEvent):void
		{
			logger.info("MediaTypeData callback");
			logger.debug("MediaTypeData {0}", [printObject(event.toString())]);
		}

		public function onNetStatus(event:NetStatusEvent):void
		{
			var info:Object=event.info;
			var messageClientId:int=info.clientid ? info.clientid : -1;
			var messageCode:String=info.code;
			var messageDescription:String=info.description ? info.description : '';
			var messageDetails:String=info.details ? info.details : '';
			var messageLevel:String=info.level;
			logger.debug("NetStatus [{0}] {1} {2}", [messageLevel, messageCode, messageDescription]);
			switch (messageCode)
			{
				case "NetStream.Buffer.Empty":
					if (_streamStatus == STREAM_STOPPED)
					{
						_streamStatus=STREAM_FINISHED;
							//dispatchEvent(new NetStreamClientEvent(NetStreamClientEvent.PLAYBACK_FINISHED));
					}
					else
						_streamStatus=STREAM_BUFFERING;
					break;
				case "NetStream.Buffer.Full":
					if (_streamStatus == STREAM_READY)
					{
						_streamStatus=STREAM_STARTED;
						dispatchEvent(new NetStreamClientEvent(NetStreamClientEvent.PLAYBACK_STARTED));
					}
					if (_streamStatus == STREAM_BUFFERING)
						_streamStatus=STREAM_STARTED;
					if (_streamStatus == STREAM_UNPAUSED)
						_streamStatus=STREAM_STARTED;

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
					dispatchEvent(new NetStreamClientEvent(NetStreamClientEvent.STREAM_NOT_FOUND));
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
					break;
				case "NetStream.Connect.Closed":
					_connected=false;
					break;
				case "NetStream.Connect.Success":
					_connected=true;
					break;
				default:
					break;
			}
			dispatchEvent(new NetStreamClientEvent(NetStreamClientEvent.STATE_CHANGED, _streamStatus));

		}

		public function onStatus(event:StatusEvent):void
		{
			logger.info("Status callback");
			logger.debug("Status {0}", [printObject(event)]);
		}

		/*
		 * Client object callbacks
		 */
		public function onCuePoint(cuePoint:Object):void
		{
			logger.info("CuePoint callback");
			logger.debug("CuePoint {0}", [printObject(cuePoint)]);
		}

		public function onImageData(imageData:Object):void
		{
			var rawData:ByteArray=imageData.data as ByteArray;
			logger.info("ImageData callback");
		}

		public function onMetaData(metaData:Object):void
		{
			logger.info("MetaData callback");
			logger.debug("MetaData {0}", [printObject(metaData)]);

			_metaData=metaData;
			_duration=metaData.duration ? metaData.duration : _duration;
			
			_videoWidth=metaData.width ? metaData.width : _videoWidth;
			_videoHeight=metaData.height ? metaData.height : _videoHeight;
			
			_hasVideo=(metaData.videocodecid && metaData.videocodecid != -1) ? true : _hasVideo;
			_hasAudio=(metaData.audiocodecid && metaData.audiocodecid != -1) ? true : _hasAudio;
			
			_audioCodecID = metaData.audiocodecid ? metaData.audiocodecid : _audioCodecID;
			_videoCodecID = metaData.videocodecid ? metaData.videocodecid : _videoCodecID;
			_frameRate = metaData.framerate ? metaData.framerate : _frameRate;
			_audioSampleRate = metaData.audiosamplerate ? metaData.audiosamplerate : _audioSampleRate;
			_audioSampleSize = metaData.aduiosamplesize ? metaData.audiosamplesize : _audioSampleSize;
			_fileSize = metaData.filesize ? metaData.filesize : _fileSize;
			_videoDataRate = metaData.videodatarate ? metaData.videodatarate : _videoDataRate;
			_audioDataRate = metaData.audiodatarate ? metaData.audiodatarate : _audioDataRate;
			_stereo = metaData.stereo ? metaData.stereo : _stereo;
			
			_canSeekToEnd = metaData.canSeekToEnd ? metaData.canSeekToEnd : _canSeekToEnd;

			dispatchEvent(new NetStreamClientEvent(NetStreamClientEvent.METADATA_RETRIEVED));
		}

		public function onPlayStatus(playStatus:Object):void
		{
			//level, code
			logger.info("PlayStatus callback");
			logger.debug("PlayStatus {0}", [printObject(playStatus)]);
		}

		public function onSeekPoint(seekPoint:Object):void
		{
			logger.info("SeekPoint callback");
			logger.debug("SeekPoint {0}", [printObject(seekPoint)]);
		}

		public function onTextData(textData:Object):void
		{
			logger.info("TextData callback");
			logger.debug("TextData {0}", [printObject(textData)]);
		}

		public function onXMPData(xmpData:Object):void
		{
			//data, a string The string is generated from a top-level UUID box. 
			//(The 128-bit UUID of the top level box is BE7ACFCB-97A9-42E8-9C71-999491E3AFAC.) This top-level UUID box contains exactly one XML document represented as a null-terminated UTF-8 string.
			logger.info("XMPData callback");
			logger.debug("XMPData {0}",[printObject(xmpData)]);
		}
		
		public function printObject(value:Object):String
		{		
			var str:String;
			var type:String = value == null ? "null" : typeof(value);	
			
			switch (type)
			{
				case "boolean":
				case "number":
				{
					return value.toString();
				}	
				case "string":
				{
					return "\"" + value.toString() + "\"";
				}
				case "object":
				{
					str = "\n("+ type + ") {\n";
					for(var v:* in value){	
						str += "    "+printObject(v)+": "+printObject(value[v])+"\n";
					}
					str += '}';
					return str;
				}
				case "xml":
				{
					return value.toXMLString();
				}
				default:
				{
					return "(" + type + ")";
				}
			}
		}
	}
}
