package api
{
	public class DummyWebService
	{
		private static var baseurl:String = 'rtmpt://babelium/vod/';
		
		
		public static function retrieveVideoById(id:String):String{
			if(id.search(/^resp-/) != -1){
				return baseurl + "responses/"+id;
			} else {
				return baseurl + "exercises/"+id;
			}
		}
	}
}