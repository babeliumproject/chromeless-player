package model
{
	import streaming.PrivacyManager;
	import streaming.NetConnectionClient;

	/** 
	 * @author 
	 * 
	 */	
	public class SharedData
	{
		public static var instance:SharedData;
		
		public var privacyManager:PrivacyManager;
		public var streamingManager:NetConnectionClient;
		
		
		
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
			privacyManager=new PrivacyManager();
			streamingManager=new NetConnectionClient();
		}
		
		
	}
}