package commands
{
	public class EventTrigger
	{
		private var actionValues:Array;
		
		public function EventTrigger(actionValues:Array)
		{
			this.actionValues=actionValues;
		}
		
		public function executeActions():void{
			for each(var av:Object in actionValues){
				//trace("Function name: "+av.func + " params: "+av.params);
				av.func(av.params);
			}
		}
	}
}