package assets
{
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.geom.Matrix;
	
	public class VectorShape extends Shape
	{
		public var commands:Vector.<int>;
		public var pathData:Vector.<Number>;
		public var matrix:Matrix = new Matrix();
		
		public var shape_width:uint;
		public var shape_height:uint;
		
		public var gradient_type:String;
		public var gradient_colors:Array;
		public var gradient_alphas:Array;
		public var gradient_ratios:Array;
		public var gradient_angle:Number;
		
		/**
		 * Creates a new <code>Shape</code> with the given parameters.
		 *  
		 * @param width
		 * @param height
		 * @param vcmd
		 * @param vdata
		 * @param colors
		 * @param alphas
		 * @param ratios
		 * @param angle
		 * @param lineWeight
		 * @param lineColor
		 * @param lineAlpha
		 * 
		 */		
		public function VectorShape(width:uint, height:uint, vcmd:Array, vdata:Array, type:String,
									colors:Array, alphas:Array, ratios:Array, angle:uint=0,
									lineWeight:uint=0, lineColor:uint=0, lineAlpha:uint=0)
		{
			super();
			
			shape_width = width ? width : 256;
			shape_height = height ? height : 256;
			
			commands = vcmd ? Vector.<int>(vcmd) : Vector.<int>();
			pathData = vdata ? Vector.<Number>(vdata) : Vector.<Number>();

			gradient_type = (type != GradientType.LINEAR && type != GradientType.RADIAL) ? type : GradientType.LINEAR; 
			gradient_colors = colors ? colors : [0xffffff,0xf0f0f0];
			gradient_alphas = alphas ? alphas : [1,1];
			gradient_ratios = ratios ? ratios : [0,255];
			gradient_angle = angle*Math.PI/180;
					
			matrix.createGradientBox(shape_width, shape_height, gradient_angle, 0, 0);
			
			graphics.clear();
			graphics.lineStyle(lineWeight, lineColor, lineAlpha);
			graphics.beginGradientFill(gradient_type, gradient_colors, gradient_alphas, gradient_ratios, matrix);
			graphics.drawPath(commands, pathData);
			graphics.endFill();
		}
		
		public function get offsetX():Number{
			return scaleX * getRect(this).x;
		}
		
		public function get offsetY():Number{
			return scaleY * getRect(this).y;
		}
	}
}