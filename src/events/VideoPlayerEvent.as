package events
{
	import flash.events.Event;

	public class VideoPlayerEvent extends Event
	{
		
		public static const VIDEO_SOURCE_CHANGED:String = "VideoSourceChanged";
		public static const VIDEO_FINISHED_PLAYING:String = "VideoFinishedPlaying";
		public static const VIDEO_STARTED_PLAYING:String = "VideoStartedPlaying";
		public static const METADATA_RETRIEVED:String = "MetadataRetrieved";
		public static const CREATION_COMPLETE:String = "VideoPlayerCreationComplete";
		public static const CONNECTED:String = "VideoConnected";
		
		public static const STATE_CHANGED:String="stateChanged";
		public var state:int;
		
		public function VideoPlayerEvent(type:String, state:int=-1, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.state = state;
		}
		
	}
}