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
	
	import media.AMediaManager;
	import media.ARTMPManager;
	import media.AVideoManager;
	import media.NetStreamClient;
	import media.RTMPMediaManager;
	
	import model.SharedData;
	
	import mx.utils.ObjectUtil;
	
	import org.as3commons.logging.api.ILogger;
	import org.as3commons.logging.api.getLogger;
	
	import util.Helpers;
	
	import view.BitmapSprite;
	import view.ErrorSprite;

	public class VideoPlayer extends Sprite
	{

		protected const DEFAULT_VOLUME:Number=70;

		protected var _video:Video;
		protected var _nsc:AMediaManager;

		protected var _videoUrl:String=null;
		protected var _videoPosterUrl:String=null;

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

		protected var _currentVolume:Number;
		protected var _lastVolume:Number;
		protected var _muted:Boolean=false;
		
		protected var _posterSprite:BitmapSprite;
		protected var _errorSprite:ErrorSprite;
		protected var _topLayer:Sprite;


		private static const logger:ILogger=getLogger(VideoPlayer);

		public function VideoPlayer()
		{
			//TODO retrieve the volume from a previously stored flash/http cookie
			_currentVolume=DEFAULT_VOLUME;
			_lastVolume=DEFAULT_VOLUME;
			
			_lastWidth = _defaultWidth;
			_lastHeight = _defaultHeight;
			
			_lastAutoplay = _autoPlay;
			
			_video=new Video();
			_video.smoothing=_smooth;
			
			_topLayer = new Sprite();
			
			addChild(_video);
			addChild(_topLayer);

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
			if(_nsc)
				_nsc.seek(seconds);
		}

		public function get duration():Number
		{
			return _nsc ? _nsc.duration : 0;
		}

		public function get streamTime():Number
		{
			return _nsc ? _nsc.currentTime : 0;
		}

		public function getLoadedFragment():Number
		{
			return _nsc ? _nsc.loadedFraction : 0;
		}

		public function getBytesTotal():Number
		{
			return _nsc ? _nsc.bytesTotal : 0;
		}

		public function getBytesLoaded():Number
		{
			return _nsc ? _nsc.bytesLoaded : 0;
		}
		
		public function getStartBytes():Number
		{
			return _nsc ? _nsc.startBytes : 0;
		}

		public function get mute():Boolean
		{
			return _muted;
		}

		public function set mute(value:Boolean):void
		{
			_muted=value;
			var newVolume:Number;
			if (value)
			{
				//Store the volume that we had before muting to restore to that volume when unmuting
				_lastVolume=_currentVolume;
				newVolume=0;
			}
			else
			{
				newVolume=_lastVolume;
			}
			//Make sure we have a working NetStream object before setting its sound transform
			if (_nsc) _nsc.volume=newVolume;
		}

		public function getVolume():Number
		{
			return _currentVolume;
		}

		public function setVolume(value:Number):void
		{
			if (!isNaN(value) && value >= 0 && value <= 100)
			{
				_currentVolume=value;
				if(_nsc) _nsc.volume = value;
			}
		}

		private function onComplete():void
		{

		}
		
		protected function loadVideo():void{
			_videoReady=false;
			if (_videoUrl != '')
			{
				resetAppearance();
				
				
				if(!_autoPlay){
					_posterSprite = new BitmapSprite(_videoPosterUrl, _lastWidth, _lastHeight);
					_topLayer.addChild(_posterSprite);
				}
				
				if (streamReady(_nsc))
				{
					_nsc.netStream.dispose();
				}
				
				_nsc=null;
				var rtmpFragments:Array = Helpers.parseRTMPUrl(_videoUrl);
				if(rtmpFragments){
					_nsc=new ARTMPManager("playbackStream");
					_nsc.addEventListener(NetStreamClientEvent.NETSTREAM_READY, onNetStreamReady);
					_nsc.addEventListener(NetStreamClientEvent.NETSTREAM_ERROR, onNetStreamUnready);
					_nsc.setup(rtmpFragments[1], rtmpFragments[2]);
				} else {
					_nsc=new AVideoManager("playbackStream");
					_nsc.addEventListener(NetStreamClientEvent.NETSTREAM_READY, onNetStreamReady);
					_nsc.addEventListener(NetStreamClientEvent.NETSTREAM_ERROR, onNetStreamUnready);
					_nsc.setup(_videoUrl);
				}
				
				//_nsc=null;
				//_nsc=new NetStreamClient(_videoUrl, "playbackStream");
				
			}
		}

		public function loadVideoByUrl(url:String):void
		{
			if (url != '')
			{
				_videoUrl=url;
				loadVideo();
			}
			else
			{
				logger.info("Empty video url provided");
			}
		}

		public function loadVideoById(videoId:String):void
		{
			if (videoId != '')
			{
				var videoData:Array=DummyWebService.retrieveVideoById(videoId);
				_videoUrl=videoData['url'];
				_videoPosterUrl=videoData['poster'];
				loadVideo();
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
			_nsc.volume=_currentVolume;
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
		
		protected function onNetStreamUnready(event:NetStreamClientEvent):void{
			_errorSprite=new ErrorSprite(event.message, _lastWidth, _lastHeight);
			_topLayer.removeChildren();
			_topLayer.addChild(_errorSprite);
		}

		protected function startVideo():void
		{
			if (!_videoReady)
				return;
			try
			{
				//_nsc.play("exercises/"+_videoUrl);
				_topLayer.removeChildren();
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

		protected function streamReady(nsc:AMediaManager):Boolean
		{
			return nsc && nsc.netStream;
		}
	}
}
