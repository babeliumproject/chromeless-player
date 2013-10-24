package assets
{
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.geom.Matrix;
	
	public class VectorShape extends Shape
	{
		
		private var shapeBgColors:Array = [0xe4e4e4, 0xa3a3a3];
		private var shapeBgAlphas:Array = [1, 1];
		private var shapeBgRatios:Array = [127, 255];
		private var shapeVecCmd:Vector.<int> = new Vector.<int>(); 
		private var shapeVecData:Vector.<Number> = new Vector.<Number>();
		private var shapeMatr:Matrix = new Matrix();
		
		public function VectorShape(width:uint, height:uint, vcmd:Array, vdata:Array, colors:Array, alphas:Array, ratios:Array, angle:uint=0, lineWeight:uint=0, lineColor:uint=0, lineAlpha:uint=0)
		{
			super();
			
			var angledec:Number = angle*Math.PI/180;
			
			//Shape drawing vectors
			shapeVecCmd.push(vcmd);
			shapeVecData.push(vdata);
			
			shapeMatr.createGradientBox(width, height, angledec, 0, 0);
			
			//Do the actual drawing
			graphics.clear();
			graphics.lineStyle(lineWeight, lineColor, lineAlpha);
			graphics.beginGradientFill(GradientType.RADIAL, shapeBgColors, shapeBgAlphas, shapeBgRatios, shapeMatr);
			graphics.drawPath(shapeVecCmd, shapeVecData);
			graphics.endFill();
		}
	}
}