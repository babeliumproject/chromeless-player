package player
{
	import events.NetStreamClientEvent;
	import events.PlayPauseEvent;
	import events.ScrubberBarEvent;
	import events.StopEvent;
	import events.StreamingEvent;
	import events.VideoPlayerEvent;
	import events.VolumeEvent;

	import flash.display.Sprite;
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.utils.Timer;

	import media.NetConnectionClient;
	import media.NetStreamClient;

	import model.SharedData;

	public class VideoPlayer extends Sprite
	{

		/**
		 * Variables
		 */
		protected var _video:Video;
		protected var _nsc:NetStreamClient;
		protected var _nc:NetConnection;

		private var _videoSource:String=null;
		protected var _streamSource:String=null;
		private var _state:String=null;
		private var _autoPlay:Boolean=true;
		private var _smooth:Boolean=true;
		private var _currentTime:Number=0;
		private var _autoScale:Boolean=false;
		protected var _duration:Number=0;
		protected var _started:Boolean=false;
		protected var _defaultMargin:Number=0;

		protected var _spriteWidth:Number=640;
		protected var _spriteHeight:Number=360;

		private var _currentVolume:SoundTransform;
		private var _muted:Boolean=false;

		private var _reconnectionTimer:Timer;
		private var _reconnectionDelay:uint=5000; //5 seconds

		/*
		public static const PLAYBACK_READY_STATE:int=0;
		public static const PLAYBACK_STARTED_STATE:int=1;
		public static const PLAYBACK_STOPPED_STATE:int=2;
		public static const PLAYBACK_FINISHED_STATE:int=3;
		public static const PLAYBACK_PAUSED_STATE:int=4;
		public static const PLAYBACK_UNPAUSED_STATE:int=5;
		public static const PLAYBACK_BUFFERING_STATE:int=6;
*/
	//public var playbackState:int;

		private var playPauseStatus:Boolean=true;

		/**
		 * CONSTRUCTOR
		 **/
		public function VideoPlayer()
		{
			drawGraphics();

			//Event Listeners
			addEventListener(VideoPlayerEvent.VIDEO_SOURCE_CHANGED, onSourceChange);
			addEventListener(VideoPlayerEvent.VIDEO_FINISHED_PLAYING, onVideoFinishedPlaying);


			onComplete();

		}

		private function drawGraphics():void
		{

			graphics.clear();
			graphics.beginFill(0x0000FF, 1);
			graphics.drawRect(0, 0, _spriteWidth, _spriteHeight);
			graphics.endFill();

			_video=new Video();
			_video.smoothing=_smooth;
			_video.x=_video.y=0;
			addChild(_video);
		}


		/**
		 * Video streaming source
		 *
		 */
		public function set videoSource(location:String):void
		{
			_videoSource=location;
			//if(!StreamingManager.getInstance().netConnected)
			//	return;

			if (location != "")
				dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.VIDEO_SOURCE_CHANGED));
			else
				resetAppearance();
		}

		public function get videoSource():String
		{
			return _videoSource;
		}

		/**
		 * Flash server
		 */
		public function set streamSource(location:String):void
		{
			_streamSource=location;
		}

		public function get streamSource():String
		{
			return _streamSource;
		}

		/**
		 * Autoplay
		 */
		public function set autoPlay(tf:Boolean):void
		{
			_autoPlay=tf;
		}

		public function get autoPlay():Boolean
		{
			return _autoPlay;
		}


		/**
		 * Smooting
		 */
		public function set videoSmooting(tf:Boolean):void
		{
			_autoPlay=_smooth;
		}

		public function get videoSmooting():Boolean
		{
			return _smooth;
		}

		/**
		 * Autoscale
		 */
		public function set scaleToFit(flag:Boolean):void
		{
			_autoScale=flag;
		}

		public function get scaleToFit():Boolean
		{
			return _autoScale;
		}

		/**
		 * Seek
		 */
		public function set seekable(value:Boolean):void
		{
			//TODO
		}

		public function seekTo(time:Number):void
		{
			if (!isNaN(time) && time >= 0 && time < _duration)
			{
				_nsc.netStream.seek(time);
			}
		}

		public function get duration():Number
		{
			return _duration;
		}

		public function get streamTime():Number
		{
			return _nsc.netStream ? _nsc.netStream.time : 0;
		}

		public function getLoadedFragment():Number
		{
			return _nsc.netStream ? (_nsc.netStream.bytesLoaded / _nsc.netStream.bytesTotal) : 0;
		}

		public function getBytesTotal():Number
		{
			return _nsc.netStream ? _nsc.netStream.bytesTotal : 0;
		}

		public function getBytesLoaded():Number
		{
			return _nsc.netStream ? _nsc.netStream.bytesLoaded : 0;
		}

		public function get mute():Boolean
		{
			return _muted;
		}

		public function set mute(value:Boolean):void
		{
			_muted=value;
			if (value)
			{
				_nsc.netStream.soundTransform=new SoundTransform(0);
			}
			else
			{
				_nsc.netStream.soundTransform=_currentVolume;
			}
		}

		public function get volume():Number
		{
			return _nsc.netStream ? _nsc.netStream.soundTransform.volume * 100 : 0;
		}

		public function set volume(value:Number):void
		{
			if (!isNaN(value) && value >= 0 && value <= 100 && _nsc.netStream)
			{
				_currentVolume.volume=value / 100;
				_nsc.netStream.soundTransform=_currentVolume;
			}
		}

		/**
		 * Set width/height of video widget
		 */
		/*
		override public function set width(w:Number):void
		{
			totalWidth=w;
			_videoWidth=w - 2 * _defaultMargin;

		}

		override public function set height(h:Number):void
		{
			totalHeight=h;
			_videoHeight=h - 2 * _defaultMargin;
		}
*/
	/**
			 * Set total width/height of videoplayer
			 */
		protected function set totalWidth(w:Number):void
		{
			super.width=w;
		}

		protected function set totalHeight(h:Number):void
		{
			super.height=h;
		}

		/**
		 * On creation complete
		 */
		private function onComplete():void
		{
			//Establish a binding to listen the status of netConnection
			//BindingUtils.bindSetter(onStreamNetConnect, DataModel.getInstance(), "netConnected");
			//StreamingManager.getInstance().addEventListener(StreamingEvent.CONNECTED_CHANGE,onStreamNetConnect);
			trace("videoPlayer onComplete");
			//onStreamNetConnect();

			// Dispatch CREATION_COMPLETE event
			dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.CREATION_COMPLETE));
		}

		/**
		 * On stream connect
		 */
		protected function onStreamNetConnect(event:StreamingEvent=null):void
		{
			if (SharedData.getInstance().streamingManager.netConnected == true)
			{
				if (_reconnectionTimer != null)
					stopReconnectionTimer();
				//Get the netConnection reference
				_nc=SharedData.getInstance().streamingManager.netConnection;

				loadVideo();
				playPauseStatus=false;
				if (!_autoPlay)
					pauseVideo();

				this.dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.CONNECTED));
			}
			else
			{
				if (_reconnectionTimer == null || !_reconnectionTimer.running)
					startReconnectionTimer(); //connectToStreamingServer();
			}
		}

		public function startReconnectionTimer():void
		{
			connectToStreamingServer();
			_reconnectionTimer=new Timer(_reconnectionDelay, 0);
			_reconnectionTimer.start();
			_reconnectionTimer.addEventListener(TimerEvent.TIMER, onReconnectionTimerTick);

		}

		public function stopReconnectionTimer():void
		{

			_reconnectionTimer.stop();
			_reconnectionTimer.removeEventListener(TimerEvent.TIMER, onReconnectionTimerTick);
		}

		public function onReconnectionTimerTick(event:TimerEvent):void
		{

			connectToStreamingServer();
		}

		public function connectToStreamingServer():void
		{
			if (!SharedData.getInstance().streamingManager.netConnection.connected)
			{
				trace("Trying to connect");
				SharedData.getInstance().streamingManager.connect();
			}
			else
			{
				onStreamNetConnect();
			}
		}

		public function disconnectFromStreamingService():void
		{
			if (SharedData.getInstance().streamingManager.netConnection.connected)
				SharedData.getInstance().streamingManager.close();
		}

		public function loadVideoByUrl(url:String):void
		{
			//Decentralize the streaming manager
			//pieces = parseVideoUrl(url)
			//if (^rtmp || rtmpt)
			//	streaming
			//connect to streaming server and return _nc reference, this is asynchronous
			//check how to do it
			//else
			//progressive
			//return a null _nc reference, or maybe say whether it's progressive or not

		}

		/**
		 * Stream controls
		 */
		public function loadVideo():void
		{
			if (!_nc || !_nc.connected || !SharedData.getInstance().streamingManager.netConnected)
			{
				playPauseStatus=true;
				return;
			}

			if (_nsc && _nsc.netStream)
				_nsc.netStream.dispose();

			_nsc=new NetStreamClient(_nc, "playbackStream");
			_video.attachNetStream(_nsc.netStream);
			_video.visible=true;
			_currentVolume=new SoundTransform();
			_nsc.netStream.soundTransform=_currentVolume;
			_nsc.addEventListener(NetStreamClientEvent.METADATA_RETRIEVED, onMetaData);
			_nsc.addEventListener(NetStreamClientEvent.STATE_CHANGED, onStreamStateChange);

			if (_videoSource != '')
			{
				_nsc.play(_videoSource);

				_started=true;
			}
		}

		public function playVideo():void
		{
			if (!_nsc.netStream)
				return;
			if (_nsc.streamState == NetStreamClient.STREAM_PAUSED)
			{
				resumeVideo();
			}
			else
			{
				if (!_nsc.netStream.time)
					loadVideo();
			}
		}

		public function pauseVideo():void
		{
			if (_nsc.netStream && (_nsc.streamState == NetStreamClient.STREAM_STARTED || _nsc.streamState == NetStreamClient.STREAM_BUFFERING))
				_nsc.netStream.togglePause();
		}

		public function resumeVideo():void
		{
			if (_nsc.netStream && _nsc.streamState == NetStreamClient.STREAM_PAUSED)
				_nsc.netStream.togglePause();
		}

		public function stopVideo():void
		{
			if (!SharedData.getInstance().streamingManager.netConnected)
				return;

			if (_nsc.netStream)
			{
				trace("stop video")
				_nsc.play(false);
				_video.clear();
					//_ns.pause();
					//_ns.seek(0);
			}

			playPauseStatus=false;
		}

		public function endVideo():void
		{
			stopVideo();
			if (_nsc.netStream)
				_nsc.netStream.close();
		}

		/**
		 * On video information retrieved
		 */
		public function onMetaData(event:NetStreamClientEvent):void
		{
			_duration=_nsc.duration;
			_video.width=_nsc.videoWidth;
			_video.height=_nsc.videoHeight;

			this.dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.METADATA_RETRIEVED));

			scaleVideo();
		}

		public function onStreamStateChange(event:NetStreamClientEvent):void
		{
			if (event.state == NetStreamClient.STREAM_FINISHED)
			{
				stopVideo();
			}
			if (event.state == NetStreamClient.STREAM_STARTED)
			{
				//TODO
			}
			dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.STATE_CHANGED, event.state));
		}

		/**
		 * On video source changed
		 */
		public function onSourceChange(e:VideoPlayerEvent):void
		{
			trace("onSourceChange")

			// If it's connected go ahead and try to play the video otherwise, attempt to connect to server
			if (_nc && _nc.connected && SharedData.getInstance().streamingManager.netConnected)
			{
				loadVideo();
				playPauseStatus=false;

				if (!autoPlay)
					pauseVideo();
			}
			else
			{
				SharedData.getInstance().streamingManager.addEventListener(StreamingEvent.CONNECTED_CHANGE, onStreamNetConnect);
				onStreamNetConnect();
			}
		}



		/**
		 * On video finished playing
		 */
		protected function onVideoFinishedPlaying(e:VideoPlayerEvent):void
		{
			trace("[INFO] Exercise stream: Finished playing video " + _videoSource);
			stopVideo();
		}

		/**
		 * Scale the Video object to adjust it to the size of the video player.
		 * If <code>scaleToFit=true</code> the video object will be scaled to fit the
		 * size of the video player horizontally and vertically. If <code>scaleToFit=false</code>
		 * the video will be scaled keeping its aspect ratio as much as possible.
		 */
		protected function scaleVideo():void
		{
			if (!scaleToFit)
			{
				//trace("Scaling info");

				//If the scalation is different in height and width take the smaller one
				var scaleY:Number=_spriteHeight / _video.height;
				var scaleX:Number=_spriteWidth / _video.width;
				var scaleC:Number=scaleX < scaleY ? scaleX : scaleY;

				//Center the video in the stage
				_video.y=Math.floor(_spriteHeight / 2 - (_video.height * scaleC) / 2);
				_video.x=Math.floor(_spriteWidth / 2 - (_video.width * scaleC) / 2);

				//Leave space for the margins
				_video.y+=_defaultMargin;
				_video.x+=_defaultMargin;

				//Scale the video
				_video.width=Math.ceil(_video.width * scaleC);
				_video.height=Math.ceil(_video.height * scaleC);

					//trace("Scaling info");

					// 1 black pixel, being smarter
					//_video.y+=1;
					//_video.height-=2;
					//_video.x+=1;
					//_video.width-=2;
			}
			else
			{
				_video.width=_spriteWidth;
				_video.height=_spriteHeight;
				_video.y=_defaultMargin;
				_video.height-=_defaultMargin * 2;
				_video.x=_defaultMargin;
				_video.width-=_defaultMargin * 2;
			}
		}

		/**
		 * Resets videoplayer appearance
		 **/
		protected function resetAppearance():void
		{
			_video.attachNetStream(null);
			_video.visible=false;
		}
	}
}
