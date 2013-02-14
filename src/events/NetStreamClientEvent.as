package events
{
	import flash.events.Event;
	
	public class NetStreamClientEvent extends Event
	{
		
		public static const PLAYBACK_STARTED:String="playbackStarted";
		public static const PLAYBACK_FINISHED:String="playbackFinished";
		public static const METADATA_RETRIEVED:String="metadataRetrieved";
		public static const RECORDING_STARTED:String="recordingStarted";
		public static const RECORDING_FINISHED:String="recordingFinished";
		
		
		public static const STATE_CHANGED:String="stateChanged";
		public var state:int;
		
		public function NetStreamClientEvent(type:String, state:int=-1, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.state=state;
		}
	}
}