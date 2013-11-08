package media
{
	import events.NetStreamClientEvent;
	import events.StreamingEvent;

	import flash.errors.IOError;
	import flash.events.AsyncErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.NetConnection;
	import flash.net.ObjectEncoding;

	public class ARTMPManager extends AMediaManager
	{

		private var _encoding:uint;
		private var _proxy:String;

		private var _serverUrl:String;

		private var _netConnectOngoingAttempt:Boolean;

		public function ARTMPManager(id:String)
		{
			super(id);
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
			logger.debug("Stop was called");
			_ns.close();
		}
		
		public function publish(mode:String='record'):void{
			_ns.publish(_streamUrl, mode);
		}
		
		public function setup(... args):void{
			if(args.length){
				_streamUrl = (args[0] is String) ? args[0] : '';
				_serverUrl = (args[1] is String) ? args[1] : '';
			}
			this.addEventListener(StreamingEvent.CONNECTED_CHANGE, onConnectionStatusChange);
			connect(_serverUrl);
		}

		private function connect(... args):void
		{
			if (args.length >= 1)
			{
				var rtmpServerUrl:String=(args[0] is String) ? args[0] : '';
				_proxy=(args[1] is String) ? args[1] : 'none';
				_encoding=(args[2] is uint) ? args[2] : ObjectEncoding.DEFAULT;
			}

			if (!rtmpServerUrl)
			{
				logger.error("No streaming url was provided");
				_connected=false;
				dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
			}

			//We check if another connect attempt is still ongoing
			if (!_netConnectOngoingAttempt)
			{
				_netConnectOngoingAttempt=true;

				if (_nc)
					_nc=new NetConnection();
				_nc.client=this;

				_nc.objectEncoding=_encoding;
				_nc.proxyType=_proxy;
				// Setup the NetConnection and listen for NetStatusEvent and SecurityErrorEvent events.
				_nc.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
				_nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onAsyncError);
				_nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
				_nc.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
				// connect to server
				try
				{
					logger.info("Connecting to {0}", [_serverUrl]);
					// Create connection with the server.
					_nc.connect(_serverUrl);
				}
				catch (e:ArgumentError)
				{
					// Invalid parameters.
					switch (e.errorID)
					{
						case 2004:
							logger.error("Invalid server location: {0}", [_serverUrl]);
							_netConnectOngoingAttempt=false;
							_connected=false;
							dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
							break;
						default:
							logger.error("Undetermined problem while connecting with: {0}", [_serverUrl]);
							_netConnectOngoingAttempt=false;
							_connected=false;
							dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
							break;
					}
				}
				catch (e:IOError)
				{
					logger.error("IO error while connecting to: {0}", [_serverUrl]);
					_netConnectOngoingAttempt=false;
					_connected=false;
					dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
				}
				catch (e:SecurityError)
				{
					logger.error("Security error while connecting to: {0}", [_serverUrl]);
					_netConnectOngoingAttempt=false;
					_connected=false;
					dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
				}
				catch (e:Error)
				{
					logger.error("Unidentified error while connecting to: {0}", [_serverUrl]);
					_netConnectOngoingAttempt=false;
					_connected=false;
					dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
				}
			}
		}

		protected function onSecurityError(event:SecurityErrorEvent):void
		{
			_netConnectOngoingAttempt=false;
			logger.error("[{0}] SecurityError {1} {2}", [_id, event.errorID, event.text]);
		}


		override protected function onNetIOError(event:IOErrorEvent):void
		{
			super.onIoError(event);
			_netConnectOngoingAttempt=false;
		}

		override protected function onASyncError(event:AsyncErrorEvent):void
		{
			super.onAsyncError(event);
			_netConnectOngoingAttempt=false;
		}

		override protected function onNetStatus(event:NetStatusEvent):void
		{

			super.onNetStatus(event);
			if (event.currentTarget is NetConnection)
			{
				switch (_netStatusCode)
				{
					case "NetConnection.Connect.Success":
						_connected=true;
						if (event.target.connectedProxyType == "HTTPS" || event.target.usingTLS)
							logger.info("Connected to secure server");
						else
							logger.info("Connected to server");
						dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
						break;
					case "NetConnection.Connect.Failed":
						logger.info("Connection to server failed");
						_connected=false;
						dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
						break;

					case "NetConnection.Connect.Closed":
						logger.info("Connection to server closed");
						_connected=false;
						dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
						break;

					case "NetConnection.Connect.InvalidApp":
						logger.info("Application not found on server");
						_connected=false;
						dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
						break;

					case "NetConnection.Connect.AppShutDown":
						logger.info("Application has been shutdown");
						_connected=false;
						dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
						break;

					case "NetConnection.Connect.Rejected":
						logger.info("No permissions to connect to the application");
						_connected=false;
						dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
						break;
					default:
						break;
				}
			}
			else
			{
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
						if (_streamStatus == STREAM_SEEKING_END)
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
						dispatchEvent(new NetStreamClientEvent(NetStreamClientEvent.STREAM_NOT_FOUND, _id));
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
				dispatchEvent(new NetStreamClientEvent(NetStreamClientEvent.STATE_CHANGED, _id, _streamStatus));
			}
		}

	}
}
