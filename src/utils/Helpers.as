package utils
{

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
		public static function parseUrl(url:String):void{
			if (url.length >=4096) return;
			
			//var prRegExp:RegExp=new RegExp("(^http[s]?\:\\/\\/+)([^\\/]+$)");
			//var stRegExp:RegExp=new RegExp("^rtmp[t|e|s]?\:\\/\\/([^\\/]+)");
			var stRegExp:RegExp=new RegExp("(^rtmp[t|e|s]?\:\\/\\/.+)\\/(.+)");
			//var resultPr:Object=prRegExp.exec(url);
			var resultSt:Object=stRegExp.exec(url);
			//trace(""+resultPr.toString());
			if(resultSt)
				trace("Parse: "+resultSt[0]+"\t"+resultSt[1]+"\t"+resultSt[2]);
			//if (!resultPr && !resultSt){
			//
			//}
		}
	}
}
