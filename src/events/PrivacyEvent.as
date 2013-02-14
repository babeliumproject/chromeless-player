package events
{
	import flash.events.Event;

	public class PrivacyEvent extends Event
	{
		/*
		public static const AV_HARDWARE_DISABLED:String = "avHardwareDisabled";
		public static const NO_CAMERA_FOUND:String = "noCameraFound";
		public static const NO_MICROPHONE_FOUND:String = "noMicrophoneFound";
		public static const DEVICE_ACCESS_NOT_GRANTED:String = "deviceAccessNotGranted";
		public static const DEVICE_ACCESS_GRANTED:String = "deviceAccessGranted";
		*/

		public static const DEVICE_STATE_CHANGE:String="deviceStateChange";
		public static const CLOSE:String="close";

		public static const AV_HARDWARE_DISABLED:int=-1;
		public static const NO_MICROPHONE_FOUND:int=0;
		public static const NO_CAMERA_FOUND:int=1;
		public static const DEVICE_ACCESS_NOT_GRANTED:int=2;
		public static const DEVICE_ACCESS_GRANTED:int=3;

		public var state:int;

		//-1: disabled by adm, 0: mic not found, 1: cam not found, 2: permission denied, 
		//3: permission granted, 4: display privacy settings

		public function PrivacyEvent(type:String, state:int=-1, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.state=state;
		}
	}
}
