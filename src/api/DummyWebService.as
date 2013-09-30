package api
{
	import utils.Helpers;

	/**
	 * Fake the service until we develop the actual API. Requests should be accompanied of an access_token the
	 * client got via OAuth2 + REST
	 *
	 */
	public class DummyWebService
	{
		private static var baseurl:String='rtmpt://babelium/vod/';
		private static const MAX_RECORD_SECONDS:uint = 600;
		private static const MIN_RECORD_SECONDS:uint = 15;

		public static function retrieveVideoById(id:String):String
		{
			if (!Helpers.parseUrl(id)) //Check whether the provided id has a valid format or not
			{
				if (id.search(/^resp-/) != -1)
				{
					return baseurl + "responses/" + id;
				}
				else
				{
					return baseurl + "exercises/" + id;
				}
			}
			else
			{
				return id;
			}
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
