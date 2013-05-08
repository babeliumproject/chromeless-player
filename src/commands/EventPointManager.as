package commands
{
	import events.StreamEvent;
	
	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;
	
	import mx.utils.ObjectUtil;

	public class EventPointManager extends EventDispatcher
	{
		private static var instance:EventPointManager=new EventPointManager();

		private var targetInstance:Object;

		public var cuelist:Array=new Array();

		private var currentEventTime:Number;


		/**
		 * Constructor - Singleton Pattern
		 **/
		public function EventPointManager()
		{
			if (instance)
				throw new Error("CuePointManager can only be accessed through CuePointManager.getInstance()");

			cuelist=new Array();
		}

		public static function getInstance():EventPointManager
		{
			return instance;
		}

		/**
		 * Reset CuePointManager on module change
		 **/
		public function reset():void
		{
			cuelist.removeAll();
			cuelist=new Array();
		}

		/**
		 * Cuelist manage functions
		 **/
		public function addCue(cueobj:Object):void
		{
			cuelist.addItem(cueobj);
		}

		public function setCueAt(cueobj:Object, pos:int):void
		{
			cuelist.setItemAt(cueobj, pos);
		}

		public function getCueAt(pos:int):Object
		{
			return cuelist.getItemAt(pos) as Object;
		}

		public function removeCueAt(pos:int):Object
		{
			return cuelist.removeItemAt(pos) as Object;
		}

		public function getCueIndex(cueobj:Object):int
		{
			return cuelist.getItemIndex(cueobj);
		}

		public function removeAllCue():void
		{
			cuelist.removeAll();
		}

		public function setCueList(cuelist:Array):void
		{
			this.cuelist=cuelist;
		}

		public function setCueListStartCommand(command:Function):void
		{
			for each (var cuepoint:Object in cuelist)
			{
				cuepoint.setStartCommand(command);
			}
		}

		public function setCueListEndCommand(command:Function):void
		{
			for each (var cuepoint:Object in cuelist)
			{
				cuepoint.setEndCommand(command);
			}
		}


		public function monitorCuePoints(ev:StreamEvent):void
		{
			var curTime:Number=ev.time * 1000;
			var threshold:Number = 80;
			for each (var cueobj:Object in cuelist)
			{
				if (((curTime - threshold) < cueobj.time && cueobj.time < (curTime + threshold)) && cueobj.time != currentEventTime)
				{
					currentEventTime=cueobj.time;
					cueobj.event.executeActions();
					break;
				}
			}
		}




		public function addCueFromSubtitleLine(subline:Object):void
		{
			//var cueObj:Object=new Object(subline.subtitleId, subline.showTime, subline.hideTime, subline.text, subline.exerciseRoleId, subline.exerciseRoleName,null,null,0x000000);
			//this.addCue(cueObj);
		}

		/**
		 * Getting cuelists for set their commands
		 **/
		public function getCuelist():Array
		{
			return cuelist;
		}

		/**
		 * Return cuepoint list in array mode with startTime and role
		 **/
		public function cues2rolearray():Array
		{
			var arrows:Array=new Array();

			for each (var cue:Object in getCuelist())
				arrows.addItem({startTime: cue.startTime, endTime: cue.endTime, role: cue.role});

			return arrows;
		}


		public function parseEventPoints(points:Object, targetInstance:Object):Boolean
		{
			if (!points || !targetInstance)
				return false;
			this.targetInstance=targetInstance;
			var time:Number;
			cuelist = new Array();
			for (var timestamp:String in points)
			{
				time=timeToSeconds(timestamp);
				if (time)
				{
					var actval:Array = new Array();
					if (points[timestamp].hasOwnProperty('exercise'))
					{
						var ex:Object=points[timestamp].exercise;
						var funcex:*=parseActionValue('exercise', ex);
						if(funcex != null) actval.push({func: (funcex as Function), params: ex.value});
					}
					if (points[timestamp].hasOwnProperty('response'))
					{
						var rp:Object=points[timestamp].response;
						var funcrp:*=parseActionValue('response', rp);
						if(funcrp != null) actval.push({func: (funcrp as Function), params: ex.value});
					}
					var event:EventTrigger=new EventTrigger(actval);
					var cueobj:Object = {time: time, event: event};
					cuelist.push(cueobj);
				}
			}
			trace(ObjectUtil.toString(cuelist));
			return true;
		}

		public function parseActionValue(targetStream:String, actions:Object):*
		{
			if (!actions || !actions.hasOwnProperty('action') /*|| !actions.hasOwnProperty('value')*/)
				return null;
			var action:String=actions.action;
			var value:String= actions.hasOwnProperty(value) ? actions.value : null;

			
			//return targetInstance.hasOwnProperty(action) ? targetInstance[action] : null;
			
			switch (action)
			{
				case 'volumechange':
					if (targetStream == 'exercise')
						return this.targetInstance.setVolume;
					if (targetStream == 'response')
						return this.targetInstance.setVolumeRecording;
				case 'subtitlechange':
				//return videoPlayerInstance.setSubtitle;
				case 'roleboxchange':
				//return videoPlayerInstance.setRolebox;
				case 'highlightctrlchange':
				//return videoPlayerInstance.setHighlightControls;
				default:
					return null;
			}
			return null;
		}
		
		public function mapActionToFunction(label:String, stream:String):String{
			var func:String;
			switch(label)
			{
				case 'volumechange':
					break;
				case 'mute':
					func = stream ? 'muteRecording' : 'mute';
					break;
				
				default:
			}
			return func;
		}

		public function timeToSeconds(time:String):Number
		{
			var seconds:Number;
			var milliseconds:Number;
			var timeExp:RegExp=/(\d{2}):(\d{2}):(\d{2})\.(\d{3})/;
			var matches:Array=time.match(timeExp);
			if (matches && matches.length)
			{
				seconds=(matches[1] * 3600) + (matches[2] * 60) + (matches[3] * 1) + (matches[4] * .001);
				milliseconds = seconds * 1000;
			}
			return milliseconds;
		}

	}
}
