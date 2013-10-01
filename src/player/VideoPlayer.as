package player
{
	import api.DummyWebService;
	
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
	
	import media.NetStreamClient;
	import media.RTMPMediaManager;
	
	import model.SharedData;
	
	import org.as3commons.logging.api.ILogger;
	import org.as3commons.logging.api.getLogger;

	public class VideoPlayer extends Sprite
	{

		protected const DEFAULT_VOLUME:Number=0.7;

		protected var _video:Video;
		protected var _nsc:NetStreamClient;

		protected var _videoUrl:String=null;

		protected var _lastAutoplay:Boolean;
		protected var _autoPlay:Boolean=true;
		protected var _forcePlay:Boolean=false;
		protected var _smooth:Boolean=true;
		protected var _currentTime:Number=0;
		protected var _autoScale:Boolean=false;
		protected var _duration:Number=0;
		protected var _videoReady:Boolean=false;
		protected var _videoPlaying:Boolean=false;
		protected var _videoSeeking:Boolean=false;
		protected var _defaultMargin:Number=0;

		protected var _defaultWidth:Number=640;
		protected var _defaultHeight:Number=360;
		
		protected var _lastWidth:Number;
		protected var _lastHeight:Number;

		protected var _playbackSoundTransform:SoundTransform;
		protected var _lastVolume:Number;
		protected var _muted:Boolean=false;


		private static const logger:ILogger=getLogger(VideoPlayer);

		public function VideoPlayer()
		{
			//TODO retrieve the volume from a previously stored flash/http cookie
			_playbackSoundTransform=new SoundTransform(DEFAULT_VOLUME);
			_lastVolume=DEFAULT_VOLUME;
			
			_lastWidth = _defaultWidth;
			_lastHeight = _defaultHeight;
			
			_video=new Video();
			_video.smoothing=_smooth;
			
			addChild(_video);

			drawGraphics(_defaultWidth, _defaultHeight);

			dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.CREATION_COMPLETE));
		}

		private function drawGraphics(nWidth:uint, nHeight:uint):void
		{
			graphics.clear();
			graphics.beginFill(0x0000FF, 1);
			graphics.drawRect(0, 0, nWidth, nHeight);
			graphics.endFill();
			
			//_video.x=_video.y=0;
			scaleVideo();
		}
		
		protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			_lastWidth = unscaledWidth;
			_lastHeight = unscaledHeight;
			drawGraphics(unscaledWidth, unscaledHeight);
		}
		
		public function set unscaledWidth(nwidth:Number):void{
			_lastWidth = nwidth;
			updateDisplayList(nwidth, _lastHeight);
		}
		
		public function set unscaledHeight(nheight:Number):void{
			_lastHeight = nheight;
			updateDisplayList(_lastWidth, nheight);
		}

		/**
		 * Autoplay
		 */
		public function set autoPlay(value:Boolean):void
		{
			_autoPlay=value;
			_lastAutoplay=_autoPlay;
		}

		public function get autoPlay():Boolean
		{
			return _lastAutoplay;
		}


		public function set videoSmoothing(smooth:Boolean):void
		{
			_smooth=smooth;
		}

		public function get videoSmoothing():Boolean
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
			if (!isNaN(seconds) && seconds >= 0 && seconds < _duration && streamReady(_nsc))
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
			return streamReady(_nsc) ? _nsc.netStream.time : 0;
		}

		public function getLoadedFragment():Number
		{
			return streamReady(_nsc) ? (_nsc.netStream.bytesLoaded / _nsc.netStream.bytesTotal) : 0;
		}

		public function getBytesTotal():Number
		{
			return streamReady(_nsc) ? _nsc.netStream.bytesTotal : 0;
		}

		public function getBytesLoaded():Number
		{
			return streamReady(_nsc) ? _nsc.netStream.bytesLoaded : 0;
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
				_lastVolume=_playbackSoundTransform.volume;
				_playbackSoundTransform.volume=0;
			}
			else
			{
				_playbackSoundTransform.volume=_lastVolume;
			}
			//Make sure we have a working NetStream object before setting its sound transform
			if (streamReady(_nsc))
			{
				_nsc.netStream.soundTransform=_playbackSoundTransform;
			}
		}

		public function getVolume():Number
		{
			try
			{
				return streamReady(_nsc) ? _nsc.netStream.soundTransform.volume * 100 : 0;
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
				if (streamReady(_nsc))
				{
					_nsc.netStream.soundTransform=_playbackSoundTransform;
				}
			}
		}

		private function onComplete():void
		{

		}

		public function loadVideoByUrl(url:String):void
		{
			_videoReady=false;
			if (url != '')
			{
				resetAppearance();
				_videoUrl=url;
				if (streamReady(_nsc))
				{
					_nsc.netStream.dispose();
				}
				_nsc=null;
				_nsc=new NetStreamClient(_videoUrl, "playbackStream");
				_nsc.addEventListener(NetStreamClientEvent.NETSTREAM_READY, onNetStreamReady);
				_nsc.setup();
			}
			else
			{
				logger.info("Empty video url provided");
			}
		}

		public function loadVideoById(videoId:String):void
		{
			_videoReady=false;
			if (videoId != '')
			{
				resetAppearance();
				_videoUrl=DummyWebService.retrieveVideoById(videoId);
				if (streamReady(_nsc))
				{
					_nsc.netStream.dispose();
				}
				_nsc=null;
				_nsc=new NetStreamClient(_videoUrl, "playbackStream");
				_nsc.addEventListener(NetStreamClientEvent.NETSTREAM_READY, onNetStreamReady);
				_nsc.setup();
			}
			else
			{
				logger.info("Empty video ID provided");
			}
		}

		protected function onNetStreamReady(event:NetStreamClientEvent):void
		{
			logger.debug("NetStreamClient {0} is ready", [event.streamId]);
			_video.attachNetStream(_nsc.netStream);
			_video.visible=true;
			_nsc.netStream.soundTransform=_playbackSoundTransform;
			_nsc.addEventListener(NetStreamClientEvent.METADATA_RETRIEVED, onMetaData);
			_nsc.addEventListener(NetStreamClientEvent.STATE_CHANGED, onStreamStateChange);
			if (_videoUrl != '')
			{
				_videoReady=true;
				if (_autoPlay || _forcePlay)
				{
					startVideo();
					_forcePlay=false;
				}
			}
		}

		protected function startVideo():void
		{
			if (!_videoReady)
				return;
			try
			{
				//_nsc.play("exercises/"+_videoUrl);
				_nsc.play();
			}
			catch (e:Error)
			{
				_videoReady=false;
				logger.error("Error while loading video. [{0}] {1}", [e.errorID, e.message]);
			}
		}

		public function playVideo():void
		{
			if (!streamReady(_nsc)){
				logger.debug("Stream is not ready");
				return;
			}
			
			if (_nsc.streamState == NetStreamClient.STREAM_SEEKING_START){
				logger.debug("Cannot start playing while previous seek is not complete");
				return;
			}				
			if (_nsc.streamState == NetStreamClient.STREAM_PAUSED)
			{
				resumeVideo();
			}
			if (_nsc.streamState == NetStreamClient.STREAM_UNREADY){
				logger.debug("[PlayVideo] stream not ready");
				_forcePlay=true;
				loadVideoByUrl(_videoUrl);
			}
			if (_nsc.streamState == NetStreamClient.STREAM_READY || _nsc.streamState == NetStreamClient.STREAM_FINISHED){
				logger.debug("[PlayVideo] stream ready or finished");
				startVideo();
			}
			/*
			else
			{
				if (!_nsc.netStream.time)
				{
					logger.debug("Stream is not reporting its time, start or load the stream");
					if (!_videoReady)
					{
						_forcePlay=true;
						loadVideoByUrl(_videoUrl);
					}
					else
					{
						startVideo();
					}
				}
				logger.debug("Something went wrong, the stream is not ready and yet it returns a time value of: {0}", [_nsc.netStream.time]);
			}*/
		}

		public function pauseVideo():void
		{
			if (_nsc.streamState == NetStreamClient.STREAM_SEEKING_START)
				return;
			if (streamReady(_nsc) && (_nsc.streamState == NetStreamClient.STREAM_STARTED || _nsc.streamState == NetStreamClient.STREAM_BUFFERING))
				_nsc.netStream.togglePause();
		}

		public function resumeVideo():void
		{
			if (_nsc.streamState == NetStreamClient.STREAM_SEEKING_START)
				return;
			if (streamReady(_nsc) && _nsc.streamState == NetStreamClient.STREAM_PAUSED)
				_nsc.netStream.togglePause();
		}

		public function stopVideo():void
		{
			if (streamReady(_nsc))
			{
				//_nsc.play(false);
				_nsc.stop();
				_video.clear();
				//_videoReady=false;
			}
		}

		public function endVideo():void
		{
			stopVideo();
			if (streamReady(_nsc)){
				_nsc.netStream.close(); //Cleans the cache of the video
				_nsc = null;
				_videoReady=false;
			}
		}

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
				logger.debug("StreamFinished Event received");
				//stopVideo();
				_video.clear();
				_videoPlaying=false;
			}
			if (event.state == NetStreamClient.STREAM_STARTED)
			{
				//logger.debug("Stream State Change. _videoPlaying: {0}, _autoPlay: {1}", [_videoPlaying, _autoPlay]);
				//if(!_videoPlaying && !_autoPlay) pauseVideo();
				_videoPlaying=true;
			}
			
			dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.STREAM_STATE_CHANGED, event.state));
		}

		public function onSourceChange(e:VideoPlayerEvent):void
		{
			//trace("onSourceChange")
		}

		/*
		protected function onVideoFinishedPlaying(e:VideoPlayerEvent):void
		{
			logger.info("Finished playing video :" + _videoUrl);
			stopVideo();
		}*/

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
				//If the scalation amount is different for the X and Y axes take the smaller one
				var scaleY:Number=_lastHeight / _video.height;
				var scaleX:Number=_lastWidth / _video.width;
				var scaleC:Number=scaleX < scaleY ? scaleX : scaleY;

				//Center the video in the container
				_video.y=Math.floor(_lastHeight / 2 - (_video.height * scaleC) / 2);
				_video.x=Math.floor(_lastWidth / 2 - (_video.width * scaleC) / 2);

				//Leave space for the margins
				_video.y+=_defaultMargin;
				_video.x+=_defaultMargin;

				//Scale the video
				_video.width=Math.ceil(_video.width * scaleC);
				_video.height=Math.ceil(_video.height * scaleC);

				logger.debug("Video dimensions: w:{0}, h:{1}, x:{2}, y:{3}", [_video.width, _video.height, _video.x, _video.y]);
			}
			else
			{
				_video.width=_lastWidth;
				_video.height=_lastHeight;
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

		protected function streamReady(nsc:NetStreamClient):Boolean
		{
			return nsc && nsc.netStream;
		}
	}
}
