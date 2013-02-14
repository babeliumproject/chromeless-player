package streaming
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
	import flash.utils.Dictionary;
	
	import org.osmf.net.NetClient;


	public class StreamingManager extends EventDispatcher
	{
		//RTMP protocol constants
		public static const RTMP:String = "rtmp";
		public static const RTMPT:String = "rtmpt";
		public static const RTMPS:String = "rtmps";
		public static const RTMPE:String = "rtmpe";
		
		public static const RTMP_PORT:uint=1935;
		public static const RTMPT_PORT:uint=80;
		

		//NetConnection management variables
		public var netConnection:NetConnection;
		public var bandwidthInfo:Object;
		public var netConnected:Boolean;
		public var netConnectOngoingAttempt:Boolean;

		//Domain setup
		public var server:String='babelium';
		public var uploadDomain:String="http://" + server + "/";
		
		//Streaming resource setup
		public var streamingResourcesPath:String=streamingProtocol+"://" + server + ":"+ streamingPort + "/" + streamingApp;
		public var streamingProtocol:String=RTMP;
		public var streamingPort:uint=RTMP_PORT;
		public var streamingApp:String="vod";
		public var evaluationStreamsFolder:String="evaluations";
		public var responseStreamsFolder:String="responses";
		public var exerciseStreamsFolder:String="exercises";
		
	
	
		
		private var encapsulateRTMP:Boolean=false;
		private var proxy:String='none';
		private var encoding:uint=3;
		
		public function StreamingManager()
		{
			netConnection=new NetConnection();
		}
		
		public function parseUrl(url:String):void{
			//TODO
		}
		
		private function retrieveVideoById():void{
			//TODO
		}

		/**
		 * Attempts to connect to the streaming server using the settings of DataModel and the provided proxy and AMF encodings
		 * @param proxy
		 * @param encoding
		 */
		public function connect(proxy:String='none', encoding:uint=3):void
		{
			this.proxy=proxy;
			this.encoding=encoding;
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
				netConnection.addEventListener(NetStatusEvent.NET_STATUS, netStatus);
				netConnection.addEventListener(AsyncErrorEvent.ASYNC_ERROR, netASyncError);
				netConnection.addEventListener(SecurityErrorEvent.SECURITY_ERROR, netSecurityError);
				netConnection.addEventListener(IOErrorEvent.IO_ERROR, netIOError);
				// connect to server
				try
				{
					streamingProtocol = encapsulateRTMP ?  RTMPT : RTMP;
					streamingPort = encapsulateRTMP ?  RTMPT_PORT : RTMP_PORT;
					streamingResourcesPath = streamingProtocol+"://"+server+":"+streamingPort+"/"+streamingApp;
					trace("Connecting to " + streamingResourcesPath);
					// Create connection with the server.
					netConnection.connect(streamingResourcesPath);
				}
				catch (e:ArgumentError)
				{
					// Invalid parameters.
					switch (e.errorID)
					{
						case 2004:
							trace("Invalid server location: " + streamingResourcesPath);
							netConnectOngoingAttempt=false;
							netConnected=false;
							dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
							break;
						default:
							trace("Undetermined problem while connecting with: " + streamingResourcesPath);
							netConnectOngoingAttempt=false;
							netConnected=false;
							dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
							break;
					}
				}
				catch (e:IOError)
				{
					trace("IO error while connecting to: " + streamingResourcesPath);
					netConnectOngoingAttempt=false;
					netConnected=false;
					dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
				}
				catch (e:SecurityError)
				{
					trace("Security error while connecting to: " + streamingResourcesPath);
					netConnectOngoingAttempt=false;
					netConnected=false;
					dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
				}
				catch (e:Error)
				{
					trace("Unidentified error while connecting to: " + streamingResourcesPath);
					netConnectOngoingAttempt=false;
					netConnected=false;
					dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
				}
			}
		}

		/**
		 * Closes the currently active NetConnection
		 */
		public function close():void
		{
			if (netConnection)
			{
				netConnection.close();
			}
		}

		/**
		 * Callback dispatched when info about the current connection attempt is received from the server
		 * @param event
		 */
		protected function netStatus(event:NetStatusEvent):void
		{
			netConnectOngoingAttempt=false;

			var info:Object=event.info;
			var statusCode:String=info.code;

			try
			{
				switch (statusCode)
				{
					case "NetConnection.Connect.Success":
						//Set a flag in the model to denote the successful connection
						netConnected=true;
						// find out if it's a secure (HTTPS/TLS) connection
						if (event.target.connectedProxyType == "HTTPS" || event.target.usingTLS)
							trace("Connected to secure server");
						else
							trace("Connected to server");
						dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
						break;

					case "NetConnection.Connect.Failed":
						trace("Connection to server failed");
						if(!encapsulateRTMP){
							encapsulateRTMP = true;
						} else {
							netConnected=false;
							dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
						}
						connect(proxy,encoding);
						break;

					case "NetConnection.Connect.Closed":
						trace("Connection to server closed");
						netConnected=false;
						dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
						break;

					case "NetConnection.Connect.InvalidApp":
						trace("Application not found on server");
						netConnected=false;
						dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
						break;

					case "NetConnection.Connect.AppShutDown":
						trace("Application has been shutdown");
						netConnected=false;
						dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
						break;

					case "NetConnection.Connect.Rejected":
						trace("No permissions to connect to the application");
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
				trace("NetStatus threw an error: " + e.message);
				netConnected=false;
				dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
			}
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
				trace("[bwDone] deltaDown: "+info.deltaDown+" deltaTime: "+info.deltaTime+" kbitDown: "+info.kbitDown+" latency: "+info.latency);
			}
		}
		

		/**
		 *
		 * @param event
		 */
		protected function netSecurityError(event:SecurityErrorEvent):void
		{
			netConnectOngoingAttempt=false;
			trace("Security error - " + event.text);
		}

		/**
		 *
		 * @param event
		 */
		protected function netIOError(event:IOErrorEvent):void
		{
			netConnectOngoingAttempt=false;
			trace("Input/output error - " + event.text);
		}

		/**
		 *
		 * @param event
		 */
		protected function netASyncError(event:AsyncErrorEvent):void
		{
			netConnectOngoingAttempt=false;
			trace("Asynchronous code error - " + event.error);
		}

	}
}
