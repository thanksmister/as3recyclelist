package
{
	import com.thanksmister.touchlist.controls.TouchList;
	import com.thanksmister.touchlist.events.TouchListItemEvent;
	import com.thanksmister.touchlist.renderers.TouchListItemRenderer;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	
	import net.hires.debug.Stats;
	
	[SWF( backgroundColor = '#000000' )]
	public class AS3RecycleList extends Sprite
	{
		private var touchList:TouchList;
		
		public function AS3RecycleList()
		{
			super();
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			if(stage) 
				onAddedToStage();
			else
				stage.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		private function onAddedToStage(e:Event = null):void
		{
			stage.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			stage.addEventListener(Event.RESIZE, handleResize);
			
			// Create data provider
			var dataProvider:Array = new Array();
			for(var i:int = 0; i < 300; i++){
				dataProvider.push( "This is list item " + String(i) );
			}
			
			// add our list, listeners, item renderer, and data provider
			touchList = new TouchList(); 
			touchList.rowHeight = 80;
			touchList.itemRenderer = TouchListItemRenderer;
			touchList.dataProvider = dataProvider;
			touchList.setSize(stage.stageWidth, stage.stageHeight);
			touchList.addEventListener(TouchListItemEvent.ITEM_SELECTED, handlelistItemSelected);
			
			addChild(touchList);
			
			// add some stats
			var stats:Stats = new Stats();
			
			addChild(stats);
			stats.scaleX = 2;
			stats.scaleY = 2;
			stats.x = 280;
			stats.y = 10;
		}
		
		private function handleResize(e:Event):void
		{
			touchList.resize(stage.stageWidth, stage.stageHeight);
		}
		
		/**
		 * Handle list item seleced.
		 * */
		private function handlelistItemSelected(e:TouchListItemEvent):void
		{
			trace("List item selected: " + e.renderer.index);
		}
	}
}