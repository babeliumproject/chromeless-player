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
	
	import media.MediaManager;
	import media.NetStreamClient;
	
	import model.SharedData;
	
	import org.as3commons.logging.api.ILogger;
	import org.as3commons.logging.api.getLogger;

	public class VideoPlayer extends Sprite
	{

		protected const DEFAULT_VOLUME:Number = 0.7;
		
		protected var _video:Video;
		protected var _nsc:NetStreamClient;
		protected var _nc:NetConnection;

		private var _videoSource:String=null;
		protected var _streamSource:String=null;

		private var _autoPlay:Boolean=true;
		private var _smooth:Boolean=true;
		private var _currentTime:Number=0;
		private var _autoScale:Boolean=false;
		protected var _duration:Number=0;
		protected var _started:Boolean=false;
		protected var _defaultMargin:Number=0;

		protected var _spriteWidth:Number=640;
		protected var _spriteHeight:Number=360;

		private var _playbackSoundTransform:SoundTransform;
		private var _lastVolume:Number;
		private var _muted:Boolean=false;

		private var playPauseStatus:Boolean=true;

		private static const logger:ILogger=getLogger(VideoPlayer);

		public function VideoPlayer()
		{
			//TODO retrieve the volume from a previously stored flash/http cookie
			_playbackSoundTransform = new SoundTransform(DEFAULT_VOLUME);
			_lastVolume = DEFAULT_VOLUME;
			
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

		public function seekTo(seconds:Number):void
		{
			if (!isNaN(seconds) && seconds >= 0 && seconds < _duration)
			{
				_nsc.netStream.seek(seconds);
			}
		}

		public function get duration():Number
		{
			return _duration;
		}

		public function get streamTime():Number
		{
			return streamReady() ? _nsc.netStream.time : 0;
		}

		public function getLoadedFragment():Number
		{
			return streamReady() ? (_nsc.netStream.bytesLoaded / _nsc.netStream.bytesTotal) : 0;
		}

		public function getBytesTotal():Number
		{
			return streamReady() ? _nsc.netStream.bytesTotal : 0;
		}

		public function getBytesLoaded():Number
		{
			return streamReady() ? _nsc.netStream.bytesLoaded : 0;
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
				//Store the volume that we had before muting to restore to that volume when unmuting
				_lastVolume =_playbackSoundTransform.volume;
				_playbackSoundTransform.volume=0;
			}
			else
			{
				_playbackSoundTransform.volume=_lastVolume;
			}
			//Make sure we have a working NetStream object before setting its sound transform
			if(streamReady()) {
				_nsc.netStream.soundTransform=_playbackSoundTransform;
			}
		}

		public function getVolume():Number
		{
			try
			{
				return streamReady() ? _nsc.netStream.soundTransform.volume * 100 : 0;
			}
			catch (e:Error)
			{
				logger.error("Error while retrieving stream volume. [{0}] {1}", [e.errorID, e.message]);
			}
			return NaN;
		}

		public function setVolume(value:Number):void
		{
			if (!isNaN(value) && value >= 0 && value <= 100)
			{
				_playbackSoundTransform.volume=value / 100;
				if(streamReady()){
					_nsc.netStream.soundTransform=_playbackSoundTransform;
				}
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

				//Get the netConnection reference
				_nc=SharedData.getInstance().streamingManager.netConnection;

				loadVideo();
				playPauseStatus=false;
				if (!_autoPlay)
					pauseVideo();

				this.dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.CONNECTED));
			}
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
			try
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
				_nsc.netStream.soundTransform=_playbackSoundTransform;
				_nsc.addEventListener(NetStreamClientEvent.METADATA_RETRIEVED, onMetaData);
				_nsc.addEventListener(NetStreamClientEvent.STATE_CHANGED, onStreamStateChange);

				if (_videoSource != '')
				{
					_nsc.play(_videoSource);

					_started=true;
				}
			}
			catch (e:Error)
			{
				logger.error("Error while loading video. [{0}] {1}", [e.errorID, e.message]);
			}
		}

		public function playVideo():void
		{
			if (!_nsc || !_nsc.netStream)
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
			if (_nsc && _nsc.netStream && (_nsc.streamState == NetStreamClient.STREAM_STARTED || _nsc.streamState == NetStreamClient.STREAM_BUFFERING))
				_nsc.netStream.togglePause();
		}

		public function resumeVideo():void
		{
			if (_nsc && _nsc.netStream && _nsc.streamState == NetStreamClient.STREAM_PAUSED)
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
		
		protected function streamReady():Boolean {
			return _nsc && _nsc.netStream;
		}
	}
}
