package media
{
	/**
	 * Callbacks of the client object from the NetConnection class
	 * 
	 * @author inko
	 * 
	 */	
	public interface IMediaManagerCallbacks
	{
		function onBWCheck(info:Object=null):void;
		
		function onBWDone(info:Object=null):void;
	}
}