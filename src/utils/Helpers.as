package utils
{
	import mx.utils.ObjectUtil;

	public class Helpers
	{
		public static function printObject(value:Object):String
		{
			var str:String;
			var type:String=value == null ? "null" : typeof(value);

			switch (type)
			{
				case "boolean":
				case "number":
				{
					return value.toString();
				}
				case "string":
				{
					return "\"" + value.toString() + "\"";
				}
				case "object":
				{
					str="\n(" + type + ") {\n";
					for (var v:* in value)
					{
						str+="    " + printObject(v) + ": " + printObject(value[v]) + "\n";
					}
					str+='}';
					return str;
				}
				case "xml":
				{
					return value.toXMLString();
				}
				default:
				{
					return "(" + type + ")";
				}
			}
		}
		
		/**
		 * Parse the given parameter to check whether it is an acceptable URL for either progressive download
		 * or streaming, retrieving the domain name along the process. 
		 * 
		 * @param url 
		 */		
		public static function parseRTMPUrl(url:String):Array{
			if (url.length >=4096) 
				return null;
			
			//var stRegExp:RegExp=new RegExp("(^rtmp[t|e|s]?\:\\/\\/.+)\\/(.+)"); //Greedy baseurl
			var stRegExp:RegExp=new RegExp("(^rtmp[t|e|s]?\:\\/\\/.+?\\/.+?)\\/(.+)"); //Non-greedy baseurl
			
			var resultSt:Array=stRegExp.exec(url);
			return resultSt;
		}
		
		public static function parseUrl(url:String):void{
			//var prRegExp:RegExp=new RegExp("(^http[s]?\:\\/\\/+)([^\\/]+$)");
		}
	}
}
