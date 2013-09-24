package media
{
	import events.StreamingEvent;
	
	import flash.events.AsyncErrorEvent;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.NetConnection;
	
	import org.as3commons.logging.api.ILogger;
	import org.as3commons.logging.api.getLogger;
	
	public class MediaManager extends EventDispatcher
	{
		
		public var netConnection:NetConnection;
		public var netConnected:Boolean;
		
		private static const logger:ILogger=getLogger(MediaManager);
		
		public function MediaManager()
		{
			netConnection=new NetConnection();
		}
		
		public function connect(... args):void{
			
			if(netConnection)
				netConnection = new NetConnection();
			netConnection.client=this;
			netConnection.connect(null);
			netConnected=true;
			dispatchEvent(new StreamingEvent(StreamingEvent.CONNECTED_CHANGE));
		}
		
		/**
		 * Closes the currently active NetConnection
		 */
		public function close():void
		{
			if (netConnection)
			{
				netConnection.close();
			}
		}
		
		
		
	}
}