package 
{
	import assets.MicImage;
	
	import events.PlayPauseEvent;
	import events.PrivacyEvent;
	import events.RecordingEvent;
	import events.StreamEvent;
	import events.StreamingEvent;
	import events.SubtitleButtonEvent;
	import events.SubtitlingEvent;
	import events.VideoPlayerBabeliaEvent;
	import events.VideoPlayerEvent;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.media.*;
	import flash.net.*;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.*;
	
	import model.SharedData;
	
	import mx.resources.ResourceManager;
	
	import overlay.ErrorOverlay;
	
	import streaming.NetStreamClient;
	import streaming.PrivacyManager;
	import streaming.StreamingManager;
	
	import views.PrivacyButton;
	import views.PrivacyPanel;
	
	//import vo.ResponseVO;

	public class VideoPlayerBabelia extends VideoPlayer
	{
		/**
		 * Recording related variables
		 */

		/**
		 * States
		 * NOTE:
		 * XXXX XXX1: split video panel into 2 views
		 * XXXX XX1X: recording modes
		 */
		public static const PLAY_STATE:int=0;        // 0000 0000
		public static const PLAY_BOTH_STATE:int=1;   // 0000 0001
		public static const RECORD_MIC_STATE:int=2;  // 0000 0010
		public static const RECORD_BOTH_STATE:int=3; // 0000 0011
		public static const UPLOAD_MODE_STATE:int=4; // 0000 0100

		private const SPLIT_FLAG:int=1; // XXXX XXX1
		private const RECORD_FLAG:int=2; // XXXX XX1X
		private const UPLOAD_FLAG:int=4; // XXXX X1XX

		private var _state:int;

		// Other constants
		private const RESPONSE_FOLDER:String=SharedData.getInstance().streamingManager.responseStreamsFolder;
		private const DEFAULT_VOLUME:Number=40;
		private const COUNTDOWN_TIMER_SECS:int=5;

		private var _outNs:NetStreamClient;
		private var _inNs:NetStreamClient;
		private var _secondStreamSource:String;

		private var _mic:Microphone;
		private var _volumeTransform:SoundTransform=new SoundTransform();

		private var _camera:Camera;
		private var _camVideo:Video;
		private var _defaultCamWidth:Number=SharedData.getInstance().privacyManager.defaultCameraWidth;
		private var _defaultCamHeight:Number=SharedData.getInstance().privacyManager.defaultCameraHeight;
		private var _blackPixelsBetweenVideos:uint = 0;
		private var _lastVideoHeight:Number=0;

		private var _micCamEnabled:Boolean=false;

		private var privacyRights:PrivacyManager;

		private var _countdown:Timer;
		private var _countdownTxt:TextField;

		private var _fileName:String;
		private var _recordingMuted:Boolean=false;

		private var _cuePointTimer:Timer;

		public static const SUBTILE_INSERT_DELAY:Number=0.5;

		
		private var _onTop:Sprite;

		private var noConnectionSprite:ErrorOverlay;
		private var privacySprite:PrivacyPanel;
		private var _micImage:MicImage;

		/**
		 * CONSTRUCTOR
		 */
		public function VideoPlayerBabelia()
		{
			super();

			var _textFormat:TextFormat = new TextFormat();
			_textFormat.color = 0xffffff;
			_textFormat.align = "center";
			_textFormat.font = "Arial";
			_textFormat.bold = true;
			_textFormat.size = 45;
			
			_countdownTxt=new TextField();
			//If you use setTextFormat, the format gets forgotten whenever you change the text
			_countdownTxt.defaultTextFormat = _textFormat;
			_countdownTxt.text="5";
			_countdownTxt.selectable=false;
			_countdownTxt.autoSize = TextFieldAutoSize.CENTER;
			_countdownTxt.x = _spriteWidth/2 - _countdownTxt.textWidth/2;
			_countdownTxt.y = _spriteHeight/2 - _countdownTxt.textHeight/2;
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
			
			_micImage.x = _spriteWidth/2 - _micImage.width/2;
			_micImage.y = _spriteHeight/2 - _micImage.height/2;			
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
			privacyRights=new PrivacyManager();
			privacyRights.addEventListener(PrivacyEvent.DEVICE_STATE_CHANGE, onPrivacyStateChange);

			_onTop=new Sprite();
			addChild(_onTop);

		}

		/**
		 * Setters and Getters
		 *
		 */
		public function setSubtitle(text:String, textColor:uint=0xffffff):void
		{
			//_subtitleBox.setText(text, textColor);
		}

		public function set subtitles(flag:Boolean):void
		{
			//_subtitlePanel.visible=flag;
			//_subtitleButton.setEnabled(flag);
			this.updateDisplayList(0, 0);
		}

		public function get subtitlePanelVisible():Boolean
		{
			//return _subtitlePanel.visible;
			return true;
		}

		

		// show/hide arrow panel
		public function set arrows(flag:Boolean):void
		{
			/*
			if (_state != PLAY_STATE)
			{
				_arrowContainer.visible=flag;
				this.updateDisplayList(0, 0);
			} else {
				_arrowContainer.visible=false;
				this.updateDisplayList(0, 0);
			}
			*/
		}

		/**
		 * Set role to talk in role talking panel
		 * @param duration in seconds
		 **/
		public function startTalking(role:String, duration:Number):void
		{
			/*
			if (!_roleTalkingPanel.talking)
				_roleTalkingPanel.setTalking(role, duration);
			*/
		}

		/**
		 * Enable/disable subtitling controls
		 */
		public function set subtitlingControls(flag:Boolean):void
		{
			/*
			_subtitleStartEnd.visible=flag;
			this.updateDisplayList(0,0); //repaint component
			*/
		}

		public function get subtitlingControls():Boolean
		{
			/*
			return _subtitlingControls.visible;
			*/
			return true;
		}

	
		/**
		 * Autoplay
		 */
		override public function set autoPlay(tf:Boolean):void
		{
			super.autoPlay=tf;
			//tf ? _overlayButton.visible=false : _overlayButton.visible=true;
		}

		/**
		 * Video player's state
		 */
		public function get state():int
		{
			return _state;
		}

		public function set state(state:int):void
		{
			//Do nothing if there's not an active connection
			if (!SharedData.getInstance().streamingManager.netConnected)
				return;

			stopVideo();

			if (state == PLAY_BOTH_STATE || state == PLAY_STATE)
				enableControls();

			_state=state;
			switchPerspective();
		}

		public function overlayClicked(event:MouseEvent):void
		{
			//_ppBtn.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
		}

		override protected function onPPBtnChanged(e:PlayPauseEvent):void
		{
			super.onPPBtnChanged(e);
			//if(_overlayButton.visible)
			//	_overlayButton.visible=false;
		}


		public function muteRecording(flag:Boolean):void
		{
			if (_recordingMuted == flag)
				return;
			_recordingMuted=flag;

			if (state & RECORD_FLAG)
				(flag) ? _mic.gain=0 : _mic.gain=DEFAULT_VOLUME;
			else if (state == PLAY_BOTH_STATE)
			{
				if (flag && _inNs && _inNs.netStream){
					_inNs.netStream.soundTransform=new SoundTransform(0);
				}else if (_inNs && _inNs.netStream){
					_inNs.netStream.soundTransform=new SoundTransform(DEFAULT_VOLUME / 100);
				}
			}
		}

		/**
		 * Adds new source to play_both video state
		 **/
		public function set secondSource(source:String):void
		{
			trace("[INFO] Video player: Second video added to stage");
			if (state != PLAY_BOTH_STATE)
				return;

			_secondStreamSource=source;

			if (_nc == null)
			{
				if (_video != null)
					_video.clear();
				return;
			}
			else
				playSecondStream();

			// splits video panel into 2 views
			splitVideoPanel();
		}

		
		/**
		 *  Highlight components
		 **/
		public function set highlight(flag:Boolean):void
		{
			//_arrowPanel.highlight=flag;
			//_roleTalkingPanel.highlight=flag;
		}


		/**
		 * Get video time
		 **/
		

		/**
		 * Methods
		 *
		 */

		/** Overriden repaint */

		protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			// Countdown
			_countdownTxt.x = _spriteWidth/2 - _countdownTxt.textWidth/2;
			_countdownTxt.y = _spriteHeight/2 - _countdownTxt.textHeight/2;
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
		 * Overriden play video:
		 * - Adds a listener to video widget
		 */
		override public function loadVideo():void
		{
			super.loadVideo();
			if(state == PLAY_BOTH_STATE)
				playSecondStream();

			if (!_cuePointTimer)
			{
				_cuePointTimer=new Timer(20, 0); //Try to tick every 20ms
				_cuePointTimer.addEventListener(TimerEvent.TIMER, onEnterFrame);
				_cuePointTimer.start();
			}
		}

		/**
		 * Gives parent component an ENTER_FRAME event
		 * with current stream time (CuePointManager should catch this)
		 */
		private function onEnterFrame(e:TimerEvent):void
		{
			if (_nsc != null)
				this.dispatchEvent(new StreamEvent(StreamEvent.ENTER_FRAME, _nsc.netStream.time));
		}

		/**
		 * Overriden pause video:
		 * - Pauses talk if any role is talking
		 * - Pauses second stream if any
		 */
		override public function pauseVideo():void
		{
			super.pauseVideo();

			//if (_roleTalkingPanel.talking)
			//	_roleTalkingPanel.pauseTalk();

			if (state & RECORD_FLAG && _micCamEnabled) // TODO: test
				_outNs.netStream.pause();

			if (state == PLAY_BOTH_STATE){
				_inNs.netStream.pause();
			}
		}

		/**
		 * Overriden resume video:
		 * - Resumes talk if any role is talking
		 * - Resumes secon stream if any
		 */
		override public function resumeVideo():void
		{
			super.resumeVideo();

			//if (_roleTalkingPanel.talking)
			//	_roleTalkingPanel.resumeTalk();

			if (state & RECORD_FLAG && _micCamEnabled) // TODO: test
				_outNs.netStream.resume();

			if (state == PLAY_BOTH_STATE){
				_inNs.netStream.resume();
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

			//if (_roleTalkingPanel.talking)
			//	_roleTalkingPanel.stopTalk();

			if (state & RECORD_FLAG && _micCamEnabled)
				_outNs.netStream.close();

			if (state == PLAY_BOTH_STATE)
			{
				if (_inNs && _inNs.netStream)
				{
					_inNs.netStream.play(false);
				}
			}

			setSubtitle("");
		}

		override public function endVideo():void
		{
			super.endVideo();

			if (state == PLAY_BOTH_STATE && _inNs && _inNs.netStream)
			{
				_inNs.netStream.dispose();
				_inNs=null;
			}
		}

		/**
		 * On subtitle button clicked:
		 * - Do show/hide subtitle panel
		 */
		private function onSubtitleButtonClicked(e:SubtitleButtonEvent):void
		{
			if (e.state)
				doShowSubtitlePanel();
			else
				doHideSubtitlePanel();
		}

		/**
		 * Subtitle Panel's show animation
		 */
		private function doShowSubtitlePanel():void
		{
			/*
			_subtitlePanel.visible=true;
			var a1:AnimateProperty=new AnimateProperty();
			a1.target=_subtitlePanel;
			a1.property="alpha";
			a1.toValue=1;
			a1.duration=250;
			a1.play();

			this.drawBG(); // Repaint bg
			*/
		}

		/**
		 * Subtitle Panel's hide animation
		 */
		private function doHideSubtitlePanel():void
		{/*
			var a1:AnimateProperty=new AnimateProperty();
			a1.target=_subtitlePanel;
			a1.property="alpha";
			a1.toValue=0;
			a1.duration=250;
			a1.play();
			a1.addEventListener(EffectEvent.EFFECT_END, onHideSubtitleBar);
			*/
		}

		private function onHideSubtitleBar(e:Event):void
		{/*
			_subtitlePanel.visible=false;
			this.drawBG(); // Repaint bg
			*/
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
			switch (_state)
			{
				case RECORD_BOTH_STATE:
					prepareDevices();
					break;

				case RECORD_MIC_STATE:
					recoverVideoPanel(); // original size
					prepareDevices();
					break;
				
				case UPLOAD_MODE_STATE:
					recoverVideoPanel();
					scaleCamVideo(_spriteWidth,_spriteHeight,false);
					prepareDevices();
					break;

				case PLAY_BOTH_STATE:
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

		override protected function onStreamNetConnect(event:StreamingEvent=null):void
		{
			super.onStreamNetConnect(/*value*/);
			if (SharedData.getInstance().streamingManager.netConnected)
			{
				_onTop.removeChildren();
			}
			else
			{
				//Add the no connection error sprite in the top layer
				_onTop.removeChildren();
				_onTop.addChild(noConnectionSprite);
				//Unattach user devices if they were attached (connection failed while recording)
				unattachUserDevices();
				//If status is different than PLAY_STATE switch to that state
				if (_state != PLAY_STATE)
				{
					_state=PLAY_STATE;
					arrows=false;
					//removeArrows();
				}
			}
		}

		/**
		 * Countdown before recording
		 */

		// Prepare countdown timer
		private function startCountdown():void
		{
			_countdown=new Timer(1000, COUNTDOWN_TIMER_SECS)
			_countdown.addEventListener(TimerEvent.TIMER, onCountdownTick);
			_countdown.start();
		}

		// On Countdown tick
		private function onCountdownTick(tick:TimerEvent):void
		{
			if (_countdown.currentCount == _countdown.repeatCount)
			{
				_countdownTxt.visible=false;
				_video.visible=true;

				if (state == RECORD_BOTH_STATE || state == UPLOAD_MODE_STATE)
				{
					_camVideo.visible=true;
					_micImage.visible=true;
				}

				// Reset countdown timer
				_countdownTxt.text="5";
				_countdown.stop();
				_countdown.reset();

				startRecording();
			}
			else if (state != PLAY_STATE)
				_countdownTxt.text=new String(5 - _countdown.currentCount);
		}


		/**
		 * Methods to prepare the recording
		 */
		private function prepareDevices():void
		{
			var privacyManager:PrivacyManager=SharedData.getInstance().privacyManager;
			//The devices are permitted and initialized. Time to configure them
			if ((state == RECORD_MIC_STATE && privacyManager.microphoneReady()) || 
				(state == RECORD_BOTH_STATE && privacyManager.cameraReady() && privacyManager.microphoneReady()) ||
				(state == UPLOAD_MODE_STATE && privacyManager.cameraReady() && privacyManager.microphoneReady()))
			{
				configureDevices();
			}
			else
			{
				if (state == RECORD_BOTH_STATE || state == UPLOAD_MODE_STATE)
					privacyManager.useMicAndCamera=true;
				if (state == RECORD_MIC_STATE)
					privacyManager.useMicAndCamera=false;
				
				_onTop.removeChildren();
				_onTop.addChild(privacySprite);
				
				privacySprite.addEventListener(PrivacyEvent.CLOSE, privacyBoxClosed);
				privacySprite.displaySettings();
			}
		}

		private function configureDevices():void
		{	
			var privacyManager:PrivacyManager=SharedData.getInstance().privacyManager;
			if (state == RECORD_BOTH_STATE || state == UPLOAD_MODE_STATE)
			{
				_camera=privacyManager.camera;
				_camera.setMode(privacyManager.defaultCameraWidth, privacyManager.defaultCameraHeight, 15, false);
			}
			_mic=privacyManager.microphone;
			_mic.setUseEchoSuppression(true);
			_mic.setLoopBack(true);
			_mic.setSilenceLevel(0, 60000000);

			_video.visible=false;
			_micImage.visible=false;
			_countdownTxt.visible=true;

			prepareRecording();
			startCountdown();
		}

		/*
		public function micActivityHandler(event:ActivityEvent):void
		{
			//The mic has received an input louder than the 0% volume, so there's a mic working correctly.
			if (event.activating)
			{
				DataModel.getInstance().gapsWithNoSound=0;
				DataModel.getInstance().soundDetected=true;
				DataModel.getInstance().microphone.removeEventListener(ActivityEvent.ACTIVITY, micActivityHandler);
			}
		}*/
		
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
			var privacyManager:PrivacyManager=SharedData.getInstance().privacyManager;
			//Remove the privacy settings & the rest of layers from the top layer
			_onTop.removeChildren();

			_micCamEnabled=privacyManager.deviceAccessGranted;
			if (state == RECORD_MIC_STATE)
			{
				if (_micCamEnabled && privacyManager.microphoneFound)
					configureDevices();
				else
					dispatchEvent(new RecordingEvent(RecordingEvent.ABORTED));
			}
			if (state == RECORD_BOTH_STATE || state == UPLOAD_MODE_STATE)
			{
				if (_micCamEnabled && privacyManager.microphoneFound && privacyManager.cameraFound)
					configureDevices();
				else
					dispatchEvent(new RecordingEvent(RecordingEvent.ABORTED));
			}
		}

		// splits panel into a 2 different views
		private function prepareRecording():void
		{
			// Disable seek
			seekable=false;
			_mic.setLoopBack(false);

			if (state & SPLIT_FLAG)
			{
				// Attach Camera
				_camVideo.attachCamera(_camera);
				_camVideo.smoothing=true;

				splitVideoPanel();
				_camVideo.visible=false;
				_micImage.visible=false;
				disableControls();
			}

			if (state & RECORD_FLAG)
			{
				_outNs=new NetStreamClient(_nc,"outNs");
				disableControls();
			}
			
			if(state & UPLOAD_FLAG){
				// Attach Camera
				_camVideo.attachCamera(_camera);
				_camVideo.smoothing=true;
				
				//	splitVideoPanel();
				_camVideo.visible=false;
				_micImage.visible=false;
				_outNs=new NetStreamClient(_nc,"outNs");
			}

			//_micActivityBar.visible=true;
			//dispatchEvent(new ControlDisplayEvent(ControlDisplayEvent.MIC_ACTIVYTY_BAR,true));
			//_micActivityBar.mic=_mic;
			this.updateDisplayList(0, 0);
		}

		/**
		 * Start recording
		 */
		private function startRecording():void
		{
			if (!(state & RECORD_FLAG))
				return; // security check

			var d:Date=new Date();
			_fileName="resp-" + d.getTime().toString();
			var responseFilename:String=RESPONSE_FOLDER + "/" + _fileName;

			//if (_started)
			//	resumeVideo();
			//else
			loadVideo();

			if (state & RECORD_FLAG)
			{
				_outNs.netStream.attachAudio(_mic);
				muteRecording(true); // mic starts muted
			}

			if (state == RECORD_BOTH_STATE)
				_outNs.netStream.attachCamera(_camera);

			//_ppBtn.State=PlayButton.PAUSE_STATE;
			//playPauseState = false;

			_outNs.netStream.publish(responseFilename, "record");

			trace("[INFO] Response stream: Started recording " + _fileName);

			//TODO: new feature - enableControls();
		}


		/**
		 * Split video panel into 2 views
		 */
		private function splitVideoPanel():void
		{
			//The stage should be splitted only when the right state is set
			if (!(state & SPLIT_FLAG))
				return;

			var w:Number=_spriteWidth / 2 - _blackPixelsBetweenVideos;
			var h:int=Math.ceil(w * 0.75);//_video.height / _video.width);

			if (_spriteHeight != h) // cause we can call twice to this method
				_lastVideoHeight=_spriteHeight; // store last value

			_spriteHeight=h;
			
			//trace("[INFO] Video player Babelium: BEFORE SPLIT VIDEO PANEL Video area dimensions: "+_videoWidth+"x"+_videoHeight+" video dimensions: "+_video.width+"x"+_video.height+" video placement: x="+_video.x+" y="+_video.y+" last video area heigth: "+_lastVideoHeight);

			var scaleY:Number=h / _video.height;
			var scaleX:Number=w / _video.width;
			var scaleC:Number=scaleX < scaleY ? scaleX : scaleY;

			_video.y=Math.floor(h / 2 - (_video.height * scaleC) / 2);
			_video.x=Math.floor(w / 2 - (_video.width * scaleC) / 2);
			_video.y+=_defaultMargin;
			_video.x+=_defaultMargin;

			_video.width*=scaleC;
			_video.height*=scaleC;

			//trace("[INFO] Video player Babelium: AFTER SPLIT VIDEO PANEL Video area dimensions: "+_videoWidth+"x"+_videoHeight+" video dimensions: "+_video.width+"x"+_video.height+" video placement: x="+_video.x+" y="+_video.y+" last video area heigth: "+_lastVideoHeight);
			
			//Resize the cam display
			scaleCamVideo(w,h);

			updateDisplayList(0, 0); // repaint

			//trace("The video panel has been splitted");
		}

		/**
		 * Recover video panel's original size
		 */
		private function recoverVideoPanel():void
		{
			trace("[INFO] Video player Babelium: Recover video panel");
			// NOTE: problems with _videoWrapper.width
			if (_lastVideoHeight > _spriteHeight)
				_spriteHeight=_lastVideoHeight;

			scaleVideo();

			_camVideo.visible=false;
			_micImage.visible=false;
			//_micActivityBar.visible=false;
			//dispatchEvent(new ControlDisplayEvent(ControlDisplayEvent.MIC_ACTIVITY_BAR,false);

			//trace("The video panel recovered its original size");
		}

		// Aux: scaling cam image
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
				
				//trace("[INFO] Video player Babelium: CAM SCALE Video area dimensions: "+_videoWidth+"x"+_videoHeight+" cam dimensions: "+_camVideo.width+"x"+_camVideo.height+" cam placement: x="+_camVideo.x+" y="+_camVideo.y+" last video area heigth: "+_lastVideoHeight);
				
				
				// 1 black pixel, being smarter
				//_camVideo.y+=1;
				//_camVideo.height-=2;
				//_camVideo.x+=1;
				//_camVideo.width-=2;
			} else {
				_camVideo.y=_defaultMargin + 2;
				_camVideo.height-=4;
				_camVideo.x=_defaultMargin + 2;
				_camVideo.width-=4;
			}

			
			_micImage.y=(_spriteHeight - _micImage.height)/2;
			_micImage.x=_spriteWidth - _micImage.width - (_camVideo.width - _micImage.width)/2;
		}

		override protected function scaleVideo():void
		{
			super.scaleVideo();
			if (state & SPLIT_FLAG)
			{
				var w:Number=_spriteWidth / 2 - _blackPixelsBetweenVideos;
				var h:int=Math.ceil(w * 0.75);

				if (_spriteHeight != h) // cause we can call twice to this method
					_lastVideoHeight=_spriteHeight; // store last value

				_spriteHeight=h;

				var scaleY:Number=h / _video.height;
				var scaleX:Number=w / _video.width;
				var scaleC:Number=scaleX < scaleY ? scaleX : scaleY;

				_video.y=Math.floor(h / 2 - (_video.height * scaleC) / 2);
				_video.x=Math.floor(w / 2 - (_video.width * scaleC) / 2);
				_video.y+=_defaultMargin;
				_video.x+=_defaultMargin;

				_video.width*=scaleC;
				_video.height*=scaleC;
				//trace("[INFO] Video player babelia: AFTER SCALE Video area dimensions: "+_videoWidth+"x"+_videoHeight+" video dimensions: "+_video.width+"x"+_video.height+" video placement: x="+_video.x+" y="+_video.y+" last video area heigth: "+_lastVideoHeight);
			}
		}

		override protected function resetAppearance():void
		{
			super.resetAppearance();

			if (state & SPLIT_FLAG)
			{
				_camVideo.attachNetStream(null);
				_camVideo.clear();
				_camVideo.visible=false;
				_micImage.visible=false;
			}
		}

		/**
		 * Overriden on recording finished:
		 * Gives the filename to the parent component
		 **/
		override protected function onVideoFinishedPlaying(e:VideoPlayerEvent):void
		{
			super.onVideoFinishedPlaying(e);

			if (state & RECORD_FLAG || state == UPLOAD_MODE_STATE)
			{
				//addDummyVideo();
				unattachUserDevices();

				trace("[INFO] Response stream: Finished recording " + _fileName);
				dispatchEvent(new RecordingEvent(RecordingEvent.END, _fileName));
				enableControls(); 
			}
			else
				dispatchEvent(new RecordingEvent(RecordingEvent.REPLAY_END));
		}

		/**
		 * Flash 11.2.x has a bug that makes audio only FLV files non-playable. This workaround adds a dummy video stream to those files to recover
		 * the playback functionality while Adobe fixes this bug.
		 */
		/*
		protected function addDummyVideo():void{
			var r:ResponseVO = new ResponseVO();
			r.fileIdentifier = _fileName;
			new ResponseEvent(ResponseEvent.ADD_DUMMY_VIDEO,r).dispatch();
		}
		*/
		
		public function unattachUserDevices():void{
			if (_outNs && _outNs.netStream)
			{
				_outNs.netStream.attachCamera(null);
				_outNs.netStream.attachAudio(null);
				_camVideo.clear();
				_camVideo.attachCamera(null);
			}
			//if((_onTop.numChildren > 0) && (_onTop.getChildAt(0) is PrivacyRights) )
			//	removeAllChildren(_onTop); //Remove the privacy box in case someone cancels the recording before starting
		}

		/**
		 * PLAY_BOTH related commands
		 **/
		private function playSecondStream():void
		{
			if (_inNs && _inNs.netStream){
				_inNs.netStream.dispose();
			}

			if (_nc && _nc.connected)
			{
				_inNs=new NetStreamClient(_nc,"inNs");
				//_inNs.netStream.soundTransform=new SoundTransform(_audioSlider.getCurrentVolume());
				_inNs.netStream.soundTransform=new SoundTransform(0.7);
				
				_camVideo.clear();
				_camVideo.attachNetStream(_inNs.netStream);
				_camVideo.visible=true;
				_micImage.visible=true;

				_inNs.netStream.play(_secondStreamSource);

				// Needed for video mute
				muteRecording(false);
				muteRecording(true);

				if (_nsc != null)
				{
					//_ns.resume();
					_nsc.play(super.videoSource);
				}
				//_ppBtn.State=PlayButton.PAUSE_STATE;
				//playPauseStatus=false;
			}
		}
	}
}
