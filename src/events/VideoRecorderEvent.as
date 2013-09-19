package events
{
	import flash.events.Event;

	public class VideoRecorderEvent extends Event
	{
		
		public static const SECONDSTREAM_FINISHED_PLAYING:String = "SecondStreamFinishedPlaying";
		
		public static const RECORDER_STATE_CHANGED:String="recorderStateChanged";
		public var state:int;
		
		/**
		 * Fires the event 
		 * @param type
		 * 		The type of event that was dispatched
		 * @param state
		 * 		The new state of the video recorder. Accepted values are: 0=PLAY, 1=PLAY SIDE BY SIDE, 2=RECORD MIC, 3=RECORD MIC AND WEBCAM, 4=UPLOAD MODE
		 * @param bubbles
		 * @param cancelable
		 * 
		 */		
		public function VideoRecorderEvent(type:String, state:int=0, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.state=state;
		}
	}
}