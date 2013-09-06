package model
{
	import commands.EventPointManager;
	
	import media.MediaManager;
	import media.UserDeviceManager;

	public class SharedData
	{
		public static var instance:SharedData;
		
		public var privacyManager:UserDeviceManager;
		public var streamingManager:MediaManager;
		public var eventPointManager:EventPointManager;
		public var localizationBundle:Object;
		
		/**
		 * Retrieves the current instance of SharedData or creates a new one 
		 * @return 
		 * 		The singleton instance of this object
		 */		
		public static function getInstance():SharedData
		{
			if (!instance)
				instance=new SharedData();
			return instance;
		}
		
		/**
		 * Constructor function
		 * Init here any managers that need to be shared across all the code
		 */		
		public function SharedData()
		{
			privacyManager=new UserDeviceManager();
			streamingManager=new MediaManager();
			eventPointManager=new EventPointManager();
			localizationBundle=new Object();
		}
		
		
	}
}