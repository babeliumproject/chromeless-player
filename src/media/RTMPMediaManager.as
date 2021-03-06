package media
{
	import events.StreamingEvent;
	
	import flash.errors.IOError;
	import flash.events.AsyncErrorEvent;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.net.FileReference;
	import flash.net.NetConnection;
	import flash.net.ObjectEncoding;
	import flash.utils.Dictionary;
	
	import org.as3commons.logging.api.ILogger;
	import org.as3commons.logging.api.getLogger;
	import org.as3commons.logging.setup.LogSetupLevel;
	import org.osmf.net.NetClient;


	public class RTMPMediaManager extends MediaManager implements INetConnectionCallbacks
	{
		//RTMP protocol constants
	//	public static const RTMP:String = "rtmp";
	//	public static const RTMPT:String = "rtmpt";
	//	public static const RTMPS:String = "rtmps";
	//	public static const RTMPE:String = "rtmpe";
		
	//	public static const RTMP_PORT:uint=1935;
	//	public static const RTMPT_PORT:uint=80;
		

		//NetConnection management variables
		
		public var bandwidthInfo:Object;
	
		public var netConnectOngoingAttempt:Boolean;

		//Domain setup
	//	public var server:String='babelium';
	//	public var uploadDomain:String="http://" + server + "/";
		
		//Streaming resource setup
	//	public var streamingResourcesPath:String=streamingProtocol+"://" + server + ":"+ streamingPort + "/" + streamingApp;
	//	public var streamingProtocol:String=RTMP;
	//	public var streamingPort:uint=RTMP_PORT;
	//	public var streamingApp:String="vod";
	//	public var evaluationStreamsFolder:String="evaluations";
	//	public var responseStreamsFolder:String="responses";
	//	public var exerciseStreamsFolder:String="exercises";
		
		private var encapsulateRTMP:Boolean=false;
		private var proxy:String='none';
		private var encoding:uint=ObjectEncoding.AMF0;
		
		private var streamingResourcesPath:String;
		
		private static const logger:ILogger=getLogger(RTMPMediaManager);
		
		public function RTMPMediaManager()
		{
			super();
		}

		/**
		 * Attempts to connect to the streaming server using the settings of DataModel and the provided proxy and AMF encodings
		 * @param proxy
		 * @param encoding
		 */
		override public function connect(... args):void
		{
			if(args.length >= 1){
				this.streamingResourcesPath = (args[0] is String) ? args[0] : '';
				this.proxy = (args[1] is String) ? args[1] : 'none';
				this.encoding = (args[2] is uint) ? args[2] : ObjectEncoding.DEFAULT;
			}
			
			if(!this.streamingResourcesPath){
				logger.error("No streaming url was provided");	
			}
			
			//We check if another connect attempt is still ongoing
			if (!netConnectOngoingAttempt)
			{
				netConnectOngoingAttempt=true;

				if(netConnection)
					netConnection = new NetConnection();
				netConnection.client=this;

				netConnection.objectEncoding=encoding;
				netConnection.proxyType=proxy;
				// Setup the NetConnection and listen for NetStatusEvent and SecurityErrorEvent events.
				netConnection.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
				netConnection.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onNetASyncError);
				netConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onNetSecurityError);
				netConnection.addEventListener(IOErrorEvent.IO_ERROR, onNetIOError);
				// connect to server
				try
				{
					//streamingProtocol = streamingResourcesPath.search('rtmpt') ? RTMPT : RTMP;
					//streamingPort = encapsulateRTMP ?  RTMPT_PORT : RTMP_PORT;
					//streamingResourcesPath = streamingProtocol+"://"+server+":"+streamingPort+"/"+streamingApp;
					logger.info("Connecting to {0}", [streamingResourcesPath]);
					// Create connection with the server.
					netConnection.connect(streamingResourcesPath);
				}
				catch (e:ArgumentError)
				{
					// Invalid parameters.
					switch (e.errorID)
					{
						case 2004:
							logger.error("Invalid server location: {0}", [streamingResourcesPath]);
							netConnectOngoingAttempt=false;
							netConnected=false;
							dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
							break;
						default:
							logger.error("Undetermined problem while connecting with: {0}", [streamingResourcesPath]);
							netConnectOngoingAttempt=false;
							netConnected=false;
							dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
							break;
					}
				}
				catch (e:IOError)
				{
					logger.error("IO error while connecting to: {0}", [streamingResourcesPath]);
					netConnectOngoingAttempt=false;
					netConnected=false;
					dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
				}
				catch (e:SecurityError)
				{
					logger.error("Security error while connecting to: {0}", [streamingResourcesPath]);
					netConnectOngoingAttempt=false;
					netConnected=false;
					dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
				}
				catch (e:Error)
				{
					logger.error("Unidentified error while connecting to: {0}", [streamingResourcesPath]);
					netConnectOngoingAttempt=false;
					netConnected=false;
					dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
				}
			}
		}

		/**
		 * Callback dispatched when info about the current connection attempt is received from the server
		 * @param event
		 */
		protected function onNetStatus(event:NetStatusEvent):void
		{
			netConnectOngoingAttempt=false;

			var info:Object=event.info;
			var messageClientId:int=info.clientid ? info.clientid : -1;
			var messageCode:String=info.code;
			var messageDescription:String=info.description ? info.description : '';
			var messageDetails:String=info.details ? info.details : '';
			var messageLevel:String=info.level;
			logger.debug("NetStatus [{0}] {1} {2}", [messageLevel, messageCode, messageDescription]);

			try
			{
				switch (messageCode)
				{
					case "NetConnection.Connect.Success":
						//Set a flag in the model to denote the successful connection
						netConnected=true;
						// find out if it's a secure (HTTPS/TLS) connection
						if (event.target.connectedProxyType == "HTTPS" || event.target.usingTLS)
							logger.info("Connected to secure server");
						else
							logger.info("Connected to server");
						dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
						break;

					case "NetConnection.Connect.Failed":
						logger.info("Connection to server failed");
						//if(!encapsulateRTMP){
						//	encapsulateRTMP = true;
						//} else {
							netConnected=false;
							dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
						//}
						//connect(proxy,encoding);
						break;

					case "NetConnection.Connect.Closed":
						logger.info("Connection to server closed");
						netConnected=false;
						dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
						break;

					case "NetConnection.Connect.InvalidApp":
						logger.info("Application not found on server");
						netConnected=false;
						dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
						break;

					case "NetConnection.Connect.AppShutDown":
						logger.info("Application has been shutdown");
						netConnected=false;
						dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
						break;

					case "NetConnection.Connect.Rejected":
						logger.info("No permissions to connect to the application");
						netConnected=false;
						dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
						break;

					default:
						// statements
						break;
				}
			}
			catch (e:Error)
			{
				logger.error("NetStatus threw an error: {0}", [e.message]);
				netConnected=false;
				dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
			}
		}

		/**
		 *
		 * @param event
		 */
		protected function onNetSecurityError(event:SecurityErrorEvent):void
		{
			netConnectOngoingAttempt=false;
			logger.error("Security error - {0}", [event.text]);
		}
		
		/**
		 *
		 * @param event
		 */
		protected function onNetIOError(event:IOErrorEvent):void
		{
			netConnectOngoingAttempt=false;
			logger.error("Input/output error - {0}", [event.text]);
		}
		
		/**
		 *
		 * @param event
		 */
		protected function onNetASyncError(event:AsyncErrorEvent):void
		{
			netConnectOngoingAttempt=false;
			logger.error("Asynchronous code error - {0}", [event.error]);
		}
		
		
		/**
		 * Details of the ongoing bandwidth measurement between the client and the server
		 * @param info
		 */
		public function onBWCheck(info:Object=null):void{
			if(info){
				/*
				trace("[bwCheck] count: "+info.count+" cumLatency: "+info.cumLatency+" latency: "+info.latency+" sent: "+info.sent+" timePassed: "+info.timePassed);
				var payload:Array = info.payload as Array;
				var payloadTrace:String = '';
				for (var i:int; i<payload.length; i++){
				payloadTrace += " ("+i+") "+payload[i];
				}
				trace("payload: "+payloadTrace);
				*/
			}
		}
		
		/**
		 * Results of the bandwidth measurement
		 * @param info
		 */
		public function onBWDone(info:Object=null):void
		{
			if(info){
				bandwidthInfo = info;
				logger.debug("Bandwidth Measurement done. deltaDown: {0} deltaTime: {1} kbitDown: {2} latency: {3}", [info.deltaDown,info.deltaTime,info.kbitDown,info.latency]);
			}
		}

	}
}
