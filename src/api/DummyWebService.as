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

		public static function retrieveRecordingUrl():String
		{
			var d:Date=new Date();
			var responseId:String="resp-" + d.getTime().toString();
			return baseurl + "responses/" + responseId;
		}
	}
}
