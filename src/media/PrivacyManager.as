package media
{
	import events.PrivacyEvent;
	
	import flash.display.PixelSnapping;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.StatusEvent;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.system.Capabilities;
	import flash.system.Security;
	import flash.system.SecurityPanel;

	public class PrivacyManager extends EventDispatcher
	{
		private var _microphoneChanged:Boolean=false;
		private var _microphoneSoundTestPassed:Boolean=false;
		
		private var _cameraChanged:Boolean=false;
		
		public var deviceAccessGranted:Boolean=false;
		
		public var microphoneFound:Boolean=false;
		public var cameraFound:Boolean=false;
		
		public var useMicAndCamera:Boolean=false;
		
		public var microphone:Microphone;
		public var camera:Camera;
		
		public var defaultCameraWidth:int=320;
		public var defaultCameraHeight:int=240;
		
		
		public function PrivacyManager()
		{
		}
		
		public function cameraReady():Boolean
		{
			return (microphone && !microphone.muted);
		}
		
		public function microphoneReady():Boolean
		{
			return (camera && !camera.muted);
		}
		
		public function initDevices():void
		{
			if (devicesAdministrativelyProhibited())
			{
				//dispatchEvent(new PrivacyEvent(PrivacyEvent.AV_HARDWARE_DISABLED));
				dispatchEvent(new PrivacyEvent(PrivacyEvent.DEVICE_STATE_CHANGE, PrivacyEvent.AV_HARDWARE_DISABLED));
				trace("Error: User has no rigths to access devices.");
			}
			else
			{
				if (microphoneAvailable())
				{
					microphoneFound=true;
					var currentMic:Microphone=Microphone.getMicrophone();
					if (!microphone)
					{
						_microphoneChanged=true;
						microphone=currentMic;
					}
					else if (microphone != currentMic)
					{
						_microphoneChanged=true;
						microphone=currentMic;
						trace("Mic device changed.");
					}
					if (microphone.muted)
					{
						deviceAccessGranted=false;
						//showPrivacySettings();
						microphone.addEventListener(StatusEvent.STATUS, microphonePrivacyStatus);
						//dispatchEvent(new PrivacyEvent(PrivacyEvent.DEVICE_ACCESS_NOT_GRANTED));
						dispatchEvent(new PrivacyEvent(PrivacyEvent.DEVICE_STATE_CHANGE, PrivacyEvent.DEVICE_ACCESS_NOT_GRANTED));
					}
					else
					{
						deviceAccessGranted=true;
						dispatchEvent(new PrivacyEvent(PrivacyEvent.DEVICE_STATE_CHANGE, PrivacyEvent.DEVICE_ACCESS_GRANTED));
					}
					
					if (useMicAndCamera)
					{
						if (cameraAvailable())
						{
							cameraFound=true;
							var currentCam:Camera=Camera.getCamera();
							if (!camera)
							{
								_cameraChanged=true;
								camera=currentCam;
							}
							else if (camera != currentCam)
							{
								_cameraChanged=true;
								camera=currentCam;
								
								trace("Camera device changed.");
							}
							if (camera.muted)
							{
								deviceAccessGranted=false;
								//showPrivacySettings();
								camera.addEventListener(StatusEvent.STATUS, cameraPrivacyStatus);
								//dispatchEvent(new PrivacyEvent(PrivacyEvent.DEVICE_ACCESS_NOT_GRANTED));
								dispatchEvent(new PrivacyEvent(PrivacyEvent.DEVICE_STATE_CHANGE, PrivacyEvent.DEVICE_ACCESS_NOT_GRANTED));
							}
							else
							{
								deviceAccessGranted=true;
								dispatchEvent(new PrivacyEvent(PrivacyEvent.DEVICE_STATE_CHANGE, PrivacyEvent.DEVICE_ACCESS_GRANTED));
							}
						}
						else
						{
							cameraFound=false;
							//dispatchEvent(new PrivacyEvent(PrivacyEvent.NO_CAMERA_FOUND));
							dispatchEvent(new PrivacyEvent(PrivacyEvent.DEVICE_STATE_CHANGE, PrivacyEvent.NO_CAMERA_FOUND));
							trace("Error: No camera was detected.");
						}
					}
				}
				else
				{
					microphoneFound=false;
					//dispatchEvent(new PrivacyEvent(PrivacyEvent.NO_MICROPHONE_FOUND));
					dispatchEvent(new PrivacyEvent(PrivacyEvent.DEVICE_STATE_CHANGE, PrivacyEvent.NO_MICROPHONE_FOUND));
					trace("Error: No mic was detected.");
				}
			}
			if (deviceAccessGranted)
			{
				devicesAllowed();
			}
		}
		
		private function devicesAllowed():void{
			if (useMicAndCamera)
			{
				if (microphoneFound && cameraFound){
					//dispatchEvent(new PrivacyEvent(PrivacyEvent.DEVICE_ACCESS_GRANTED));
					dispatchEvent(new PrivacyEvent(PrivacyEvent.DEVICE_STATE_CHANGE, PrivacyEvent.DEVICE_ACCESS_GRANTED));
				}
			}
			else
			{
				if (microphoneFound){
					//dispatchEvent(new PrivacyEvent(PrivacyEvent.DEVICE_ACCESS_GRANTED));
					dispatchEvent(new PrivacyEvent(PrivacyEvent.DEVICE_STATE_CHANGE, PrivacyEvent.DEVICE_ACCESS_GRANTED));
				}
			}
		}
		
		private function devicesAdministrativelyProhibited():Boolean
		{
			return (Capabilities.avHardwareDisable);
		}
		
		public function showPrivacySettings():void
		{
			Security.showSettings(SecurityPanel.PRIVACY);
		}
		
		public function cameraAvailable():Boolean
		{
			return (Camera.names.length > 0);
		}
		
		// In Linux always returns true due to Flash identifying the system's dummy audio input as a microphone
		public function microphoneAvailable():Boolean
		{
			return (Microphone.names.length > 0);
		}
		
		private function microphonePrivacyStatus(event:StatusEvent):void
		{
			if (event.code == "Microphone.Muted")
			{
				deviceAccessGranted=false;
				dispatchEvent(new PrivacyEvent(PrivacyEvent.DEVICE_STATE_CHANGE, PrivacyEvent.DEVICE_ACCESS_NOT_GRANTED));
			}
			if (event.code == "Microphone.Unmuted")
			{
				deviceAccessGranted=true;
				devicesAllowed();
			}
		}
		
		private function cameraPrivacyStatus(event:StatusEvent):void
		{
			if (event.code == "Camera.Muted")
			{
				deviceAccessGranted=false;
				dispatchEvent(new PrivacyEvent(PrivacyEvent.DEVICE_STATE_CHANGE, PrivacyEvent.DEVICE_ACCESS_NOT_GRANTED));
			}
			if (event.code == "Camera.Unmuted")
			{
				deviceAccessGranted=true;
				devicesAllowed();
			}
		}
	}
}