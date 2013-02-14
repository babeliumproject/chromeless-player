package assets
{
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.geom.Matrix;
	
	public class UnlockImage extends Shape
	{
		
		private var bgColors:Array = [0xe4e4e4, 0xa3a3a3];
		private var bgAlphas:Array = [1, 1];
		private var bgRatios:Array = [127, 255];
		private var bgMatr:Matrix = new Matrix();
		private var vecCmd:Vector.<int> = new Vector.<int>(); 
		private var vecData:Vector.<Number> = new Vector.<Number>();
		
		public function UnlockImage()
		{
			super();
			
			graphics.clear();
			graphics.beginGradientFill(GradientType.RADIAL, bgColors, bgAlphas, bgRatios, bgMatr);
			graphics.drawPath(vecCmd, vecData);
			graphics.endFill();
		}
	}
}