package assets
{
	import flash.display.Shape;
	import flash.display.Sprite;
	
	public class EncircledShape extends Sprite
	{
		public var vectorShape:VectorShape;
		public var circle:Shape;
		
		public function EncircledShape()
		{
			super();
		}
		
		public function draw(width:uint, height:uint, vcmd:Array, vdata:Array, type:String,
										colors:Array, alphas:Array, ratios:Array, angle:uint=0,
										lineWeight:uint=0, lineColor:uint=0, lineAlpha:uint=0):void
		{
			vectorShape=new VectorShape(width, height, vcmd, vdata, type, colors, alphas, 
									    ratios, angle, lineWeight, lineColor, lineAlpha);
			encircle();
			
			//Center shape in circle
			vectorShape.x = (-vectorShape.offsetX) + (circle.width - vectorShape.width) / 2;
			vectorShape.y = (-vectorShape.offsetY) + (circle.height - vectorShape.height) / 2;
			circle.x=circle.width/2;
			circle.y=circle.height/2;
			addChild(circle);
			addChild(vectorShape);
		}
		
		private function encircle():void{
			var c:Number = vectorShape.width < vectorShape.height ? vectorShape.height : vectorShape.width;
			var h:Number = Math.sqrt(Math.pow(c,2)+Math.pow(c,2));
			var radius:Number = (h/2)*1.05;
			var lineWidth:Number = c*0.1;
			
			circle = new Shape();
			circle.graphics.clear();
			circle.graphics.beginFill(0,0);
			circle.graphics.lineStyle(lineWidth, vectorShape.gradient_colors[0], vectorShape.gradient_alphas[0]);
			circle.graphics.drawCircle(0,0,radius);
			circle.graphics.endFill();
		}
	}
}