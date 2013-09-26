package player 
{
	import api.DummyWebService;
	
	import assets.MicImage;
	
	import commands.*;
	
	import events.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.media.*;
	import flash.net.*;
	import flash.sampler.getInvocationCount;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.*;
	
	import media.*;
	
	import model.*;
	
	import mx.utils.ObjectUtil;
	
	import org.as3commons.logging.api.ILogger;
	import org.as3commons.logging.api.getLogger;
	
	import view.*;

	public class VideoRecorder extends VideoPlayer
	{
		/**
		 * States
		 * NOTE:
		 * XXXX XXX1: split video panel into 2 views
		 * XXXX XX1X: recording modes
		 */
		public static const PLAY_STATE:int=0;        // 0000 0000
		public static const PLAY_SIDEBYSIDE_STATE:int=1;   // 0000 0001
		public static const RECORD_MIC_STATE:int=2;  // 0000 0010
		public static const RECORD_MICANDCAM_STATE:int=3; // 0000 0011
		public static const UPLOAD_MODE_STATE:int=4; // 0000 0100

		private const SPLIT_FLAG:int=1; // XXXX XXX1
		private const RECORD_FLAG:int=2; // XXXX XX1X
		private const UPLOAD_FLAG:int=4; // XXXX X1XX

		private const STREAM_TIMER_DELAY:int=20; // tick every X milliseconds

		private const COUNTDOWN_TIMER_SECS:int=5;
		
		private var _state:int;

		private var _recNsc:NetStreamClient;
		private var _sbsNsc:NetStreamClient;
		private var _secondStreamSource:String;

		private var _mic:Microphone;
		private var _camera:Camera;
		
		private var _camVideo:Video;
		private var _defaultCamWidth:Number=SharedData.getInstance().privacyManager.defaultCameraWidth;
		private var _defaultCamHeight:Number=SharedData.getInstance().privacyManager.defaultCameraHeight;
		private var _blackPixelsBetweenVideos:uint = 0;
		private var _lastVideoHeight:Number=0;

		private var _micCamEnabled:Boolean=false;

		private var privacyRights:UserDeviceManager;

		private var _countdown:Timer;
		private var _countdownTxt:TextField;

		//private var _fileName:String;
		private var _recordingUrl:String;
		private var _recordingMuted:Boolean=false;

		private var _cuePointTimer:Timer;

		public static const SUBTILE_INSERT_DELAY:Number=0.5;

		
		private var _onTop:Sprite;

		private var eventPointManager:EventPointManager;
		private var noConnectionSprite:ErrorOverlay;
		private var privacySprite:PrivacyPanel;
		private var _micImage:MicImage;
		
		private var _recordingReady:Boolean=false;
		private var _sideBySideReady:Boolean=false;
		
		private var _recording:Boolean=false;
		
		private var _eventData:Object;
		
		private static const logger:ILogger=getLogger(VideoRecorder);

		/**
		 * CONSTRUCTOR
		 */
		public function VideoRecorder()
		{
			super();
			
			//Retrieve the instance of the event point manager for later use
			eventPointManager = SharedData.getInstance().eventPointManager;
			
			_state=VideoRecorder.PLAY_STATE;
			drawGraphics();
		}

		private function drawGraphics():void{
			
			var _textFormat:TextFormat = new TextFormat();
			_textFormat.color = 0xffffff;
			_textFormat.align = "center";
			_textFormat.font = "Arial";
			_textFormat.bold = true;
			_textFormat.size = 45;
			
			_countdownTxt=new TextField();
			//If you use setTextFormat, the format gets forgotten whenever you change the text
			_countdownTxt.defaultTextFormat = _textFormat;
			_countdownTxt.text=COUNTDOWN_TIMER_SECS.toString();
			_countdownTxt.selectable=false;
			_countdownTxt.autoSize = TextFieldAutoSize.CENTER;
			_countdownTxt.x = _defaultWidth/2 - _countdownTxt.textWidth/2;
			_countdownTxt.y = _defaultHeight/2 - _countdownTxt.textHeight/2;
			_countdownTxt.visible=false;
			
			_camVideo=new Video();
			_camVideo.visible=false;
			
			_micImage=new MicImage();
			//_micImage.height = 128; 128 /
			//_micImage.width = 128;
			
			var scaleY:Number= 128 / _micImage.height;
			var scaleX:Number= 128 / _micImage.width;
			var scaleC:Number=scaleX < scaleY ? scaleX : scaleY;
			
			_micImage.width *= scaleC;
			_micImage.height *= scaleC;
			
			_micImage.x = _defaultWidth/2 - _micImage.width/2;
			_micImage.y = _defaultHeight/2 - _micImage.height/2;			
			_micImage.alpha = 0.7;
			_micImage.visible = false;
			
			/*
			_overlayButton=new Button();
			_overlayButton.setStyle("skinClass", OverlayPlayButtonSkin);
			_overlayButton.width=128;
			_overlayButton.height=128;
			_overlayButton.buttonMode=true;
			_overlayButton.visible=false;
			_overlayButton.addEventListener(MouseEvent.CLICK, overlayClicked);
			*/
			
			//_recStopBtn.addEventListener(RecStopButtonEvent.BUTTON_CLICK, onRecStopEvent);
			
			addChild(_micImage);
			addChild(_camVideo);
			
			addChild(_countdownTxt);
			
			//addChild(_overlayButton);
			
			noConnectionSprite=new ErrorOverlay();
			privacySprite = new PrivacyPanel();
			privacyRights=new UserDeviceManager();
			privacyRights.addEventListener(PrivacyEvent.DEVICE_STATE_CHANGE, onPrivacyStateChange);
			
			_onTop=new Sprite();
			addChild(_onTop);
		}
		
		/** Overriden repaint */
		
		protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			// Countdown
			_countdownTxt.x = _defaultWidth/2 - _countdownTxt.textWidth/2;
			_countdownTxt.y = _defaultHeight/2 - _countdownTxt.textHeight/2;
			//_countdownTxt.width=_spriteWidth;
			//_countdownTxt.height=_spriteHeight;
			
			//Play overlay
			//_overlayButton.width=_videoWidth;
			//_overlayButton.height=_videoHeight;
			
			//Error message overlay
			noConnectionSprite.updateChildren(this.width, this.height);
			
			//Privacy rights overlay
			//privacySprite.updateChildren(this.width, this.height);
		}
		
		
		/**
		 * Split video panel into 2 views
		 */
		private function splitVideoPanel():void
		{
			//The stage should be splitted only when the right state is set
			if (!(getState() & SPLIT_FLAG))
				return;
			
			var w:Number=_defaultWidth / 2 - _blackPixelsBetweenVideos;
			var h:int=Math.ceil(w * 0.75);//_video.height / _video.width);
			
			if (_defaultHeight != h) // cause we can call twice to this method
				_lastVideoHeight=_defaultHeight; // store last value
			
			_defaultHeight=h;
			
			var scaleY:Number=h / _video.height;
			var scaleX:Number=w / _video.width;
			var scaleC:Number=scaleX < scaleY ? scaleX : scaleY;
			
			_video.y=Math.floor(h / 2 - (_video.height * scaleC) / 2);
			_video.x=Math.floor(w / 2 - (_video.width * scaleC) / 2);
			_video.y+=_defaultMargin;
			_video.x+=_defaultMargin;
			
			_video.width*=scaleC;
			_video.height*=scaleC;
			
			//Resize the cam display
			scaleCamVideo(w,h);
			
			updateDisplayList(0, 0); // repaint
			
		}
		
		/**
		 * Recover video panel's original size
		 */
		private function recoverVideoPanel():void
		{
			logger.debug("Video panel was reset");
			// NOTE: problems with _videoWrapper.width
			if (_lastVideoHeight > _defaultHeight)
				_defaultHeight=_lastVideoHeight;
			
			scaleVideo();
			
			if(_camVideo) _camVideo.visible=false;
			if(_micImage) _micImage.visible=false;
		}
		
		private function scaleCamVideo(w:Number, h:Number,split:Boolean=true):void
		{
			
			var scaleY:Number=h / _defaultCamHeight;
			var scaleX:Number=w / _defaultCamWidth;
			var scaleC:Number=scaleX < scaleY ? scaleX : scaleY;
			
			_camVideo.width=_defaultCamWidth * scaleC;
			_camVideo.height=_defaultCamHeight * scaleC;
			
			if(split){
				_camVideo.y=Math.floor(h / 2 - _camVideo.height / 2);
				_camVideo.x=Math.floor(w / 2 - _camVideo.width / 2);
				_camVideo.y+=_defaultMargin;
				_camVideo.x+=(w + _defaultMargin);
			} else {
				_camVideo.y=_defaultMargin + 2;
				_camVideo.height-=4;
				_camVideo.x=_defaultMargin + 2;
				_camVideo.width-=4;
			}
			
			_micImage.y=(_defaultHeight - _micImage.height)/2;
			_micImage.x=_defaultWidth - _micImage.width - (_camVideo.width - _micImage.width)/2;
		}
		
		override protected function scaleVideo():void
		{
			super.scaleVideo();
			if (getState() & SPLIT_FLAG)
			{
				var w:Number=_defaultWidth / 2 - _blackPixelsBetweenVideos;
				var h:int=Math.ceil(w * 0.75);
				
				if (_defaultHeight != h) // cause we can call twice to this method
					_lastVideoHeight=_defaultHeight; // store last value
				
				_defaultHeight=h;
				
				var scaleY:Number=h / _video.height;
				var scaleX:Number=w / _video.width;
				var scaleC:Number=scaleX < scaleY ? scaleX : scaleY;
				
				_video.y=Math.floor(h / 2 - (_video.height * scaleC) / 2);
				_video.x=Math.floor(w / 2 - (_video.width * scaleC) / 2);
				_video.y+=_defaultMargin;
				_video.x+=_defaultMargin;
				
				_video.width*=scaleC;
				_video.height*=scaleC;
			}
		}
		
		override protected function resetAppearance():void
		{
			super.resetAppearance();
			
			if (getState() & SPLIT_FLAG)
			{
				_camVideo.attachNetStream(null);
				_camVideo.clear();
				_camVideo.visible=false;
				_micImage.visible=false;
			}
		}

		
		public function getState():int
		{
			return _state;
		}

		public function setState(newState:int):void
		{
			stopVideo();

			_state=newState;
			switchPerspective();
			dispatchEvent(new VideoRecorderEvent(VideoRecorderEvent.RECORDER_STATE_CHANGED,_state));
		}

		public function muteRecording(flag:Boolean):void
		{
			if (_recordingMuted == flag)
				return;
			_recordingMuted=flag;

			if (getState() & RECORD_FLAG)
				(flag) ? _mic.gain=0 : _mic.gain=DEFAULT_VOLUME*100;
			else if (getState() == PLAY_SIDEBYSIDE_STATE)
			{
				if (flag && _sbsNsc && _sbsNsc.netStream){
					_sbsNsc.netStream.soundTransform=new SoundTransform(0);
				}else if (_sbsNsc && _sbsNsc.netStream){
					_sbsNsc.netStream.soundTransform=new SoundTransform(DEFAULT_VOLUME);
				}
			}
		}
		
		private function streamPositionTimer(enable:Boolean):void{
			if(enable){
				if(!_cuePointTimer){
					_cuePointTimer=new Timer(STREAM_TIMER_DELAY, 0); //Try to tick every 20ms
					_cuePointTimer.addEventListener(TimerEvent.TIMER, onEnterFrame);
					_cuePointTimer.start();
				}
			} else {
				if(_cuePointTimer){
					_cuePointTimer.removeEventListener(TimerEvent.TIMER, onEnterFrame);
					_cuePointTimer.reset();
				}
			}
		}

		/**
		 * Gives parent component an ENTER_FRAME event
		 * with current stream time (CuePointManager should catch this)
		 */
		private function onEnterFrame(e:TimerEvent):void
		{
			if (streamReady(_nsc))
				this.dispatchEvent(new PollingEvent(PollingEvent.ENTER_FRAME, _nsc.netStream.time));
		}
		
		
		override public function playVideo():void
		{
			//A stream is being recorded
			if(getState() & RECORD_FLAG && _recording)
				return;	
			if(_state == PLAY_SIDEBYSIDE_STATE){
				playSidebysideVideo();
			} else {
				super.playVideo();
			}
		}
		
		private function playSidebysideVideo():void{
			if(!streamReady(_nsc) || !streamReady(_sbsNsc))
				return;
			if (_nsc.streamState == NetStreamClient.STREAM_SEEKING_START || _sbsNsc.streamState == NetStreamClient.STREAM_SEEKING_START)
				return;
			if (_nsc.streamState == NetStreamClient.STREAM_PAUSED || _sbsNsc.streamState == NetStreamClient.STREAM_PAUSED)
			{
				resumeVideo();
			}
			else
			{
				logger.debug("Play side by side {0}", [_sideBySideReady]);
				if (!_sbsNsc.netStream.time){
					if(!_sideBySideReady){
						_forcePlay=true;
						loadSideBySideVideosById(_videoUrl, _secondStreamSource, _eventData);
					}else{
						startVideo();
					}
				}
			}
		}
		
		override protected function startVideo():void{
			if(_state == PLAY_SIDEBYSIDE_STATE){
				if(!_sideBySideReady) return;
				try{
					logger.info("Start playing right video {0}", [_secondStreamSource]);
					//_sbsNsc.play("responses/"+_secondStreamSource);
					_sbsNsc.play();
				}catch(e:Error){
					_sideBySideReady=false;
					logger.error("Error while loading video. [{0}] {1}", [e.errorID, e.message]);
				}
			}
			super.startVideo();
		}

		/**
		 * Pauses the streams that are currently playing. If a stream is being recorded, nothing will be paused
		 * because that would cause a length mismatch between the reference stream (if any) and the recording stream.
		 */
		override public function pauseVideo():void
		{
			//A stream is being recorded
			if(getState() & RECORD_FLAG && _recording)
				return;
			
			super.pauseVideo();

			if (getState() == PLAY_SIDEBYSIDE_STATE){
				if (streamReady(_sbsNsc) && (_sbsNsc.streamState == NetStreamClient.STREAM_STARTED || _sbsNsc.streamState == NetStreamClient.STREAM_BUFFERING))
					_sbsNsc.netStream.togglePause();
			}
		}

		override public function resumeVideo():void
		{
			//A stream is being recorded
			if(getState() & RECORD_FLAG && _recording)
				return;
			
			super.resumeVideo();

			if (getState() == PLAY_SIDEBYSIDE_STATE){
				if (streamReady(_sbsNsc) && _sbsNsc.streamState == NetStreamClient.STREAM_PAUSED)
					_sbsNsc.netStream.togglePause();
			}
		}

		/**
		 * Overriden stop video:
		 * - Stops talk if any role is talking
		 * - Stops second stream if any
		 */
		override public function stopVideo():void
		{
			super.stopVideo();

			if (getState() & RECORD_FLAG /*&& _recording*/){
				//_recNsc.netStream.close();
				_recNsc.netStream.dispose();
			}

			if (getState() == PLAY_SIDEBYSIDE_STATE)
			{
				if (streamReady(_sbsNsc))
				{
					//_sbsNsc.play(false);
					_sbsNsc.stop();
					_camVideo.clear();
					_sideBySideReady=false;
				}
			}

			//setSubtitle("");
		}

		override public function endVideo():void
		{
			super.endVideo();

			if (getState() == PLAY_SIDEBYSIDE_STATE && streamReady(_sbsNsc))
			{
				_sbsNsc.netStream.dispose();
				_sbsNsc=null;
			}
		}

	

		/**
		 * On subtitling controls clicked: start or end subtitling button
		 * This method adds ns.time to event and gives it to parent component
		 *
		 * NOTE: Made public because the subtitling module has it's own subtitling
		 * controls that need access to the current video time.
		 */
		public function onSubtitlingEvent(e:SubtitlingEvent):void
		{
			var time:Number=_nsc.netStream != null ? _nsc.netStream.time : 0;

			this.dispatchEvent(new SubtitlingEvent(e.type, time - SUBTILE_INSERT_DELAY));
		}


		/**
		 * Switch video's perspective based on video player's
		 * actual state
		 */
		private function switchPerspective():void
		{
			switch (getState())
			{
				case RECORD_MICANDCAM_STATE:
					prepareDevices();
					break;

				case RECORD_MIC_STATE:
					recoverVideoPanel(); // original size
					prepareDevices();
					break;
				
				case UPLOAD_MODE_STATE:
					recoverVideoPanel();
					scaleCamVideo(_defaultWidth,_defaultHeight,false);
					prepareDevices();
					break;

				case PLAY_SIDEBYSIDE_STATE:
					//_micActivityBar.visible=false;
					//dispatchEvent(new ControlDisplayEvent(ControlDisplayEvent.DISPLAY_MIC_ACTIVITY,false));
					this.updateDisplayList(0,0);
					break;

				default: // PLAY_STATE
					recoverVideoPanel();
					_camVideo.attachCamera(null); // TODO: deattach camera
					_camVideo.visible=false;
					_micImage.visible=false;

					this.updateDisplayList(0, 0);

					// Enable seek
					seekable=true;

					break;
			}
		}


		private function prepareDevices():void
		{
			var requestMicAndCam:Boolean = _state == RECORD_MICANDCAM_STATE ? true : false;
			var privacyManager:UserDeviceManager=SharedData.getInstance().privacyManager;
			
			privacyManager.useMicAndCamera = requestMicAndCam;
			privacyManager.initDevices();
			
			var micReady:Boolean = privacyManager.microphoneReady();
			var micAndCamReady:Boolean = micReady && privacyManager.cameraReady();
			
			logger.info("Camera ready: {0}", [micAndCamReady]);
			logger.info("Microphone ready: {0}", [micReady]);
			
			//The devices are permitted and initialized. Time to configure them
			if (_state == RECORD_MIC_STATE && micReady || _state == RECORD_MICANDCAM_STATE && micAndCamReady || _state == UPLOAD_MODE_STATE && micAndCamReady) 
			{
				configureDevices();
			}
			else
			{
				_onTop.removeChildren();
				_onTop.addChild(privacySprite);
				
				privacySprite.addEventListener(PrivacyEvent.CLOSE, privacyBoxClosed);
				privacySprite.displaySettings();
			}
		}

		private function configureDevices():void
		{	
			var privacyManager:UserDeviceManager=SharedData.getInstance().privacyManager;
			if (getState() == RECORD_MICANDCAM_STATE || getState() == UPLOAD_MODE_STATE)
			{
				_camera=privacyManager.camera;
				_camera.setMode(privacyManager.defaultCameraWidth, privacyManager.defaultCameraHeight, 15, false);
			}
			_mic=privacyManager.microphone;
			//_mic.setUseEchoSuppression(true);
			_mic.setLoopBack(false);
			_mic.setSilenceLevel(0, 60000000);

			_video.visible=false;
			_micImage.visible=false;
			_countdownTxt.visible=true;

			prepareRecording();
			//startCountdown();
		}

		private function onPrivacyStateChange(event:PrivacyEvent):void{
			dispatchEvent(new PrivacyEvent(event.type,event.state));
			if(event.state==PrivacyEvent.DEVICE_ACCESS_GRANTED){
				configureDevices();
			} else {
				//Some kind of error in the privacy settings abort the recording and prompt the user.
				
			}
		}

		private function privacyBoxClosed(event:Event):void
		{
			var privacyManager:UserDeviceManager=SharedData.getInstance().privacyManager;
			//Remove the privacy settings & the rest of layers from the top layer
			_onTop.removeChildren();

			_micCamEnabled=privacyManager.deviceAccessGranted;
			if (getState() == RECORD_MIC_STATE)
			{
				if (_micCamEnabled && privacyManager.microphoneFound)
					configureDevices();
				else
					dispatchEvent(new RecordingEvent(RecordingEvent.ABORTED));
			}
			if (getState() == RECORD_MICANDCAM_STATE || getState() == UPLOAD_MODE_STATE)
			{
				if (_micCamEnabled && privacyManager.microphoneFound && privacyManager.cameraFound)
					configureDevices();
				else
					dispatchEvent(new RecordingEvent(RecordingEvent.ABORTED));
			}
		}
		
		private function startCountdown():void
		{
			_countdown=new Timer(1000, COUNTDOWN_TIMER_SECS)
			_countdown.addEventListener(TimerEvent.TIMER, onCountdownTick);
			_countdown.start();
		}
		
		private function resetCountdown():void{
			_countdownTxt.visible=false;
			
			// Reset countdown timer
			_countdownTxt.text=COUNTDOWN_TIMER_SECS.toString();
			if(_countdown){
				_countdown.stop();
				_countdown.reset();
			}
		}
		
		private function onCountdownTick(tick:TimerEvent):void
		{
			if (_countdown.currentCount == _countdown.repeatCount)
			{
				resetCountdown();
				startRecording();
			}
			else if (getState() != PLAY_STATE)
				_countdownTxt.text=new String(COUNTDOWN_TIMER_SECS - _countdown.currentCount);
		}

		// splits panel into a 2 different views
		private function prepareRecording():void
		{
			// Disable seek
			seekable=false;
			//_mic.setLoopBack(false);

			if (getState() & SPLIT_FLAG)
			{
				// Attach Camera
				_camVideo.attachCamera(_camera);
				_camVideo.smoothing=true;

				splitVideoPanel();
				_camVideo.visible=false;
				_micImage.visible=false;
				//disableControls();
				logger.debug("Panel splitting done");
			}

			if (getState() & RECORD_FLAG)
			{
				_recordingReady=false;
				_recordingUrl = DummyWebService.retrieveRecordingUrl();
				_recNsc=new NetStreamClient(_recordingUrl, "recordingStream");
				_recNsc.addEventListener(NetStreamClientEvent.NETSTREAM_READY, onNetStreamReady);
				_recNsc.setup();
				//disableControls();
			}
			
			if(getState() & UPLOAD_FLAG){
				// Attach Camera
				_recordingReady=false;
				_camVideo.attachCamera(_camera);
				_camVideo.smoothing=true;
				
				//	splitVideoPanel();
				_camVideo.visible=false;
				_micImage.visible=false;
				_recNsc=new NetStreamClient('recordingurl', "recordingStream");
				_recNsc.addEventListener(NetStreamClientEvent.NETSTREAM_READY, onNetStreamReady);
				_recNsc.setup();
			}

			//_micActivityBar.visible=true;
			//dispatchEvent(new ControlDisplayEvent(ControlDisplayEvent.MIC_ACTIVYTY_BAR,true));
			//_micActivityBar.mic=_mic;
			this.updateDisplayList(0, 0);
		}
		
		override protected function onNetStreamReady(event:NetStreamClientEvent):void{
			switch(event.streamId){
				case "recordingStream":
					_recordingReady=true;
					break;
				case "sidebysideStream":
					_sideBySideReady=true;	
					break;
				case "playbackStream":			
					super.onNetStreamReady(event);
					break;
				default:
					break;
			}
			if(_videoReady && _recordingReady && (_state & RECORD_FLAG)){
				startCountdown();
			}
			if(_videoReady && _sideBySideReady){
				logger.debug("NetStreamClient {0} is ready", [event.streamId]);
				_camVideo.attachNetStream(_sbsNsc.netStream);
				_camVideo.visible=true;
				_sbsNsc.netStream.soundTransform=_playbackSoundTransform;
				_sbsNsc.addEventListener(NetStreamClientEvent.METADATA_RETRIEVED, onMetaData);
				_sbsNsc.addEventListener(NetStreamClientEvent.STATE_CHANGED, onStreamStateChange);
				if (_secondStreamSource != '')
				{
					//_secondStreamSource=true;
					logger.debug("Secondstreamsource: {0}", [_secondStreamSource]);
					if(_autoPlay || _forcePlay) {
						logger.debug("ABout to call startVideo");
						startVideo();
						_autoPlay=_lastAutoplay;
						_forcePlay=false;
					}
				}
			}
		}

		/**
		 * Start recording
		 */
		private function startRecording():void
		{
			_video.visible=true;
			
			if (getState() == RECORD_MICANDCAM_STATE || getState() == UPLOAD_MODE_STATE)
			{
				_camVideo.visible=true;
				_micImage.visible=true;
			}
			
			
			if (!(getState() & RECORD_FLAG))
				return; // security check

			//var d:Date=new Date();
			//_fileName="resp-" + d.getTime().toString();
			//var responseFilename:String= "responses/" + _fileName;

			//_nsc.netStream.togglePause();
			startVideo();
			
			if (getState() & RECORD_FLAG)
			{
				_recNsc.netStream.attachAudio(_mic);
				muteRecording(true); // mic starts muted
			}
			
			if (getState() == RECORD_MICANDCAM_STATE)
				_recNsc.netStream.attachCamera(_camera);
			
			
			//_recNsc.netStream.publish(responseFilename, "record");
			_recNsc.publish();
			
			_recording=true;

			logger.info("Started recording a stream {0}", [_recordingUrl]);
		}

		override public function onStreamStateChange(event:NetStreamClientEvent):void{
			super.onStreamStateChange(event);
			if (event.state == NetStreamClient.STREAM_FINISHED)
			{
				if(_state & RECORD_FLAG){
					unattachUserDevices();
					logger.info("Finished recording stream {0}", [_recordingUrl]);
					_recording=false;
					streamPositionTimer(false);
					//_autoPlay=_lastAutoplay;
					setState(VideoRecorder.PLAY_SIDEBYSIDE_STATE);
					loadSideBySideVideosById(_videoUrl, _recordingUrl, null);
					dispatchEvent(new RecordingEvent(RecordingEvent.END, _recordingUrl));
				} else {
					//Parent onStreamStateChange does not call the recorder's stopVideo function
					//stopVideo();
					dispatchEvent(new RecordingEvent(RecordingEvent.REPLAY_END));
				}
			}
		}
		
		public function unattachUserDevices():void{
			_camVideo.clear();
			_camVideo.attachCamera(null);
			if (streamReady(_recNsc))
			{
				_recNsc.netStream.attachCamera(null);
				_recNsc.netStream.attachAudio(null);
				_recNsc.netStream.dispose();
			}

			//if((_onTop.numChildren > 0) && (_onTop.getChildAt(0) is PrivacyRights) )
			//	removeAllChildren(_onTop); //Remove the privacy box in case someone cancels the recording before starting
		}
		
		public function recordVideo(useWebcam:Boolean, exerciseId:String = null, recdata:Object = null):void{
						
			//Clean the previous sessions
			unattachUserDevices();
			removeEventListener(PollingEvent.ENTER_FRAME, eventPointManager.pollEventPoints);
			
			if(recdata){
				if(eventPointManager.parseEventPoints(recdata.eventpoints, this)){
					_eventData = recdata;
					//Add a listener to poll for event points
					addEventListener(PollingEvent.ENTER_FRAME, eventPointManager.pollEventPoints);
				} else {
					logger.debug("No event points found in given recdata");
				}
			}
			
			//Enable the polling timer
			streamPositionTimer(true);
			
			//Set autoplay to false to avoid the exercise from playing once loading is done
			_lastAutoplay=_autoPlay;
			_autoPlay=false;
			//_videoPlaying=false;
			
			if(exerciseId){
				//Load the exercise to play alongside the recording, if any
				
				//parse the given exercise id
				//if _videoId = exerciseId
				loadVideoById(exerciseId);
			}
			
			//Set the video player's state to recording
			var newState:int = useWebcam ? VideoRecorder.RECORD_MICANDCAM_STATE : VideoRecorder.RECORD_MIC_STATE;
			setState(newState);
		}
		
		public function abortRecording():void{
			resetCountdown();
			unattachUserDevices();
			
			removeEventListener(PollingEvent.ENTER_FRAME, eventPointManager.pollEventPoints);
			
			//Remove the polling timer
			streamPositionTimer(false);
			
			setState(PLAY_STATE);
		}
		
		
		public function loadSideBySideVideosById(leftStreamId:String, rightStreamId:String, eventData:Object = null):void{
			logger.debug("Load side by side was called: {0}, {1}", [leftStreamId, rightStreamId]);
			super.loadVideoById(leftStreamId);
			
			_sideBySideReady=false;
			if (rightStreamId != '')
			{
				_secondStreamSource=rightStreamId;
				if(streamReady(_sbsNsc)){
					_sbsNsc.netStream.close();
					_sbsNsc.netStream.dispose();
					_sbsNsc.removeEventListener(NetStreamClientEvent.NETSTREAM_READY, onNetStreamReady);
				}
				_sbsNsc=null;
				_sbsNsc=new NetStreamClient(rightStreamId, "sidebysideStream");
				_sbsNsc.addEventListener(NetStreamClientEvent.NETSTREAM_READY, onNetStreamReady);
				_sbsNsc.setup();
			}
			else
			{
				logger.error("Empty video ID provided");
			}
		}
		
		public function loadSideBySideVideosByUrl(leftStreamUrl:String, rightStreamUrl:String, eventData:Object = null):void{
			//TODO
		}
		
		
		public function setVolumeRecording(value:Number):void{
			if (!isNaN(value) && value >= 0 && value <= 100){
				if (value == 0) muteRecording(true);
				if (value == 100) muteRecording(false);
			}
		}
		
		public function get leftStreamDuration():Number
		{
			return super.streamTime;
		}
		
		public function get rightStreamDuration():Number
		{
			return streamReady(_sbsNsc) ? _sbsNsc.duration : 0;
		}
		
		public function get letfStreamTime():Number
		{
			return super.streamTime;
		}
		
		public function get rightStreamTime():Number
		{
			return streamReady(_sbsNsc) ? _sbsNsc.netStream.time : 0;
		}
		
		public function leftStreamLoadedFragment():Number
		{
			return super.getLoadedFragment();
		}
		
		public function rightStreamLoadedFragment():Number
		{
			return streamReady(_sbsNsc) ? (_sbsNsc.netStream.bytesLoaded / _sbsNsc.netStream.bytesTotal) : 0;
		}
		
		public function leftStreamBytesTotal():Number
		{
			return super.getBytesTotal();
		}
		
		public function rightStreamBytesTotal():Number
		{
			return streamReady(_sbsNsc) ? _sbsNsc.netStream.bytesTotal : 0;
		}
		
		public function letfStreamBytesLoaded():Number
		{
			return super.getBytesLoaded();
		}
		
		public function rightStreamBytesLoaded():Number
		{
			return streamReady(_sbsNsc) ? _sbsNsc.netStream.bytesLoaded : 0;
		}
		
		public function getLeftStreamVolume():Number
		{
			return super.getVolume();
		}
			
		public function getRightStreamVolume():Number
		{
			try
			{
				return streamReady(_sbsNsc) ? _sbsNsc.netStream.soundTransform.volume * 100 : 0;
			}
			catch (e:Error)
			{
				logger.error("Error while retrieving right stream volume. [{0}] {1}", [e.errorID, e.message]);
			}
			return NaN;
		}
	}
}
