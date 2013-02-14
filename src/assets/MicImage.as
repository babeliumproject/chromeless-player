package assets
{
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.geom.Matrix;
	
	public class MicImage extends Shape
	{
		private var micBgColors:Array = [0xe4e4e4, 0xa3a3a3];
		private var micBgAlphas:Array = [1, 1];
		private var micBgRatios:Array = [127, 255];
		private var micVecCmd:Vector.<int> = new Vector.<int>(); 
		private var micVecData:Vector.<Number> = new Vector.<Number>();
		private var micMatr:Matrix = new Matrix();
		
		public function MicImage()
		{
			super();
			
			//Mic drawing vectors
			micVecCmd.push(1, 6, 2, 6, 6, 2, 6, 2, 1, 2, 6, 6, 2, 2, 2, 6, 2, 2, 2, 2, 2, 2, 2, 2, 2, 6, 2, 2, 2);
			micVecData.push(144, 352, 188.183, 352, 224, 316.183, 224, 272, 224, 80, 224, 35.817, 188.183, 0, 144, 0, 99.817, 0, 64, 35.817, 64, 80, 64, 272, 64, 316.183, 99.818, 352, 144, 352, 144, 352, 256, 224, 256, 272, 256, 333.855, 205.855, 384, 144, 384, 82.144, 384, 32, 333.855, 32, 272, 32, 224, 0, 224, 0, 272, 0, 346.119, 56.002, 407.15, 128, 415.11, 128, 480, 64, 480, 64, 512, 128, 512, 160, 512, 224, 512, 224, 480, 160, 480, 160, 415.11, 231.997, 407.15, 288, 346.119, 288, 272, 288, 224, 256, 224, 256, 224);
			
			//micVecCmd.push (1, 6, 2, 6, 6, 2, 6, 2, 1, 2, 6, 6, 2, 2, 2, 6, 2, 2, 2, 2, 2, 2, 2, 2, 2, 6, 2, 2, 2);
			//micVecData.push(256, 352, 300.183, 352, 336, 316.183, 336, 272, 336, 80, 336, 35.817, 300.183, 0, 256, 0, 211.817, 0, 176, 35.817, 176, 80, 176, 272, 176, 316.183, 211.81799999999998, 352, 256, 352, 256, 352, 368, 224, 368, 272, 368, 333.855, 317.855, 384, 256, 384, 194.144, 384, 144, 333.855, 144, 272, 144, 224, 112, 224, 112, 272, 112, 346.119, 168.002, 407.15, 240, 415.11, 240, 480, 176, 480, 176, 512, 240, 512, 272, 512, 336, 512, 336, 480, 272, 480, 272, 415.11, 343.997, 407.15, 400, 346.119, 400, 272, 400, 224, 368, 224, 368, 224);
			micMatr.createGradientBox(512, 512, 0, 0, 0);
			
			//Do the actual drawing
			graphics.clear();
			//graphics.lineStyle(5,0x00,1);
			graphics.beginGradientFill(GradientType.RADIAL, micBgColors, micBgAlphas, micBgRatios,micMatr);
			graphics.drawPath(micVecCmd,micVecData);
			graphics.endFill();
		}
	}
}