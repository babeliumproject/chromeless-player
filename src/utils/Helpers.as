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
	}
}
