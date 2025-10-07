#property copyright ""
#property link      ""
#property version   "1.00"
#property strict
#property description "Marks major pivot points where a candle's high/low dominates the surrounding 10 candles."

input int InpPivotDepth = 10; // Number of candles on each side required for a major pivot
input color InpPivotHighColor = clrRed;   // Color for pivot high markers
input color InpPivotLowColor  = clrBlue;  // Color for pivot low markers

//--- internal state
datetime last_processed_bar_time = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   ClearPivotMarkers();
   last_processed_bar_time = 0;
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // leave the objects on the chart when the EA is removed
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(InpPivotDepth <= 0)
      return;

   if(Bars(_Symbol,_Period) <= 2*InpPivotDepth)
      return;

   datetime current_bar_time = iTime(_Symbol,_Period,0);
   if(current_bar_time == last_processed_bar_time)
      return;

   last_processed_bar_time = current_bar_time;

   int pivot_index = InpPivotDepth;
   if(pivot_index >= Bars(_Symbol,_Period) - InpPivotDepth)
      return;

   CheckAndMarkPivot(pivot_index);
  }

//+------------------------------------------------------------------+
//| Check and mark pivots for the specified index                     |
//+------------------------------------------------------------------+
void CheckAndMarkPivot(const int index)
  {
   if(IsMajorPivotHigh(index))
      CreatePivotMarker(index,true);

   if(IsMajorPivotLow(index))
      CreatePivotMarker(index,false);
  }

//+------------------------------------------------------------------+
//| Determines whether the bar at index is a major pivot high         |
//+------------------------------------------------------------------+
bool IsMajorPivotHigh(const int index)
  {
   if(index < InpPivotDepth)
      return(false);

   int total_bars = Bars(_Symbol,_Period);
   if(index + InpPivotDepth >= total_bars)
      return(false);

   double pivot_value = iHigh(_Symbol,_Period,index);

   for(int offset = 1; offset <= InpPivotDepth; ++offset)
     {
      double left_value = iHigh(_Symbol,_Period,index - offset);
      double right_value = iHigh(_Symbol,_Period,index + offset);

      if(left_value >= pivot_value || right_value > pivot_value)
         return(false);
     }

   return(true);
  }

//+------------------------------------------------------------------+
//| Determines whether the bar at index is a major pivot low          |
//+------------------------------------------------------------------+
bool IsMajorPivotLow(const int index)
  {
   if(index < InpPivotDepth)
      return(false);

   int total_bars = Bars(_Symbol,_Period);
   if(index + InpPivotDepth >= total_bars)
      return(false);

   double pivot_value = iLow(_Symbol,_Period,index);

   for(int offset = 1; offset <= InpPivotDepth; ++offset)
     {
      double left_value = iLow(_Symbol,_Period,index - offset);
      double right_value = iLow(_Symbol,_Period,index + offset);

      if(left_value <= pivot_value || right_value < pivot_value)
         return(false);
     }

   return(true);
  }

//+------------------------------------------------------------------+
//| Create a chart object to mark the pivot                           |
//+------------------------------------------------------------------+
void CreatePivotMarker(const int index,const bool is_high)
  {
   datetime pivot_time = iTime(_Symbol,_Period,index);
   double  pivot_price = is_high ? iHigh(_Symbol,_Period,index) : iLow(_Symbol,_Period,index);

   string name_prefix = is_high ? "PivotHigh_" : "PivotLow_";
   string object_name = name_prefix + IntegerToString((int)pivot_time);

   if(ObjectFind(0,object_name) >= 0)
      return;

   if(!ObjectCreate(0,object_name,OBJ_ARROW,0,pivot_time,pivot_price))
      return;

   ObjectSetInteger(0,object_name,OBJPROP_WIDTH,2);
   ObjectSetInteger(0,object_name,OBJPROP_COLOR,is_high ? InpPivotHighColor : InpPivotLowColor);
   ObjectSetInteger(0,object_name,OBJPROP_ARROWCODE,is_high ? 233 : 234); // Wingdings arrows
   ObjectSetInteger(0,object_name,OBJPROP_ANCHOR,is_high ? ANCHOR_BOTTOM : ANCHOR_TOP);

   double price_offset = 2.0 * _Point;
   double display_price = is_high ? pivot_price + price_offset : pivot_price - price_offset;
   ObjectSetDouble(0,object_name,OBJPROP_PRICE,display_price);
  }

//+------------------------------------------------------------------+
//| Remove existing pivot markers created by this EA                  |
//+------------------------------------------------------------------+
void ClearPivotMarkers()
  {
   for(int i = ObjectsTotal(0,0,-1) - 1; i >= 0; --i)
     {
      string name = ObjectName(0,i,0,-1);
      if(StringFind(name,"PivotHigh_") == 0 || StringFind(name,"PivotLow_") == 0)
         ObjectDelete(0,name);
     }
  }
