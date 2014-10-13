package util
{
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;

	dynamic public class StageProxy extends Proxy
	{
		private var container:DisplayObjectContainer;
		
		public static var stageAllowedValue:Boolean=true;

		public function StageProxy(container:DisplayObjectContainer)
		{
			super();
			this.container=container;
		}

		/**
		 * Object proxy methods
		 **/
		override flash_proxy function hasProperty(name:*):Boolean
		{
			try
			{
				return this.element.stage.hasOwnProperty(name);
			}
			catch (e:SecurityError)
			{
				stageAllowedValue=false;
			}
			return false;
		}

		override flash_proxy function getProperty(name:*):*
		{
			try
			{
				return this.container.stage[name];
			}
			catch (e:SecurityError)
			{
				stageAllowedValue=false;
			}
		}

		override flash_proxy function setProperty(name:*, value:*):void
		{
			try
			{
				this.container.stage[name]=value;
			}
			catch (e:SecurityError)
			{
				stageAllowedValue=false;
			}
		}

		override flash_proxy function callProperty(name:*, ... parameters):*
		{
			try
			{
				return this.container.stage[name].apply(null, parameters);
			}
			catch (e:SecurityError)
			{
				stageAllowedValue=false;
			}
		}

		public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=true):void
		{
			try
			{
				this.element.stage.addEventListener(type, listener, useCapture, priority, useWeakReference);
			}
			catch (e:SecurityError)
			{
				stageAllowedValue=false;
			}
		}
		
		/**
		 * If the stage uses ScaleMode.NO_SCALE is used the Stage will dispatch a resize event and update 
		 * its width and height to the new dimensions for example, when entering the full screen mode. 
		 */
		public function resize():void
		{
			this.dispatchEvent(new Event(Event.RESIZE));
		}
	}
}
