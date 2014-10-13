package api
{
	import util.Helpers;

	/**
	 * Fake the service until we develop the actual API. Requests should be accompanied of an access_token the
	 * client got via OAuth2 + REST
	 *
	 */
	public class DummyWebService
	{
		private static var baseurl:String='rtmpt://babelium/vod/';
		private static var posterurl:String='http://development/chromeless_player/images/posters/';
		
		private static const MAX_RECORD_SECONDS:uint = 180;
		private static const MIN_RECORD_SECONDS:uint = 15;

		public static function retrieveVideoById(id:String):Array
		{
			var a:Array = new Array();
			if (!Helpers.parseUrl(id)) //Check whether the provided id has a valid format or not
			{
				if (id.search(/^resp-/) != -1)
				{
					a['url'] = baseurl + "responses/" + id;
				}
				else
				{
					a['url'] = baseurl + "exercises/" + id;
				}
				a['poster'] = posterurl + id + '/default.jpg';
			}
			else
			{
				a['url'] = id;
				a['poster'] = null;
			}
			return a;
		}

		public static function requestRecordingSlot():Array
		{
			var d:Date=new Date();
			var responseId:String="resp-" + d.getTime().toString();
			var recordUri:String = baseurl + "responses/" + responseId;
			var a:Array = new Array();
			a['url'] = recordUri;
			a['maxduration'] = MAX_RECORD_SECONDS;
			return a;
		}
	}
}
