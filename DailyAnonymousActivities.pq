let
  Source = CloudAppEvents, 

  #"Parsed JSON" = Table.TransformColumns(
    Source, 
    {{"RawEventData", each Json.Document(_), type record}}
  ), 
  #"Expanded RawEventData" = Table.ExpandRecordColumn(
    #"Parsed JSON", 
    "RawEventData", 
    {"UserId"}, 
    {"RawEventData.UserId"}
  ), 
  #"Anonymous Activities" = Table.SelectRows(
    #"Expanded RawEventData", 
    each Text.Contains([RawEventData.UserId], "anon#") and [RawEventData.UserId] <> ""
  ),

  #"Changed Type" = Table.TransformColumns(
    #"Anonymous Activities", 
    {{"Timestamp", each DateTime.Date(_), type date}}
  ),
   
  #"Grouped rows" = Table.Group(
    #"Changed Type", 
    {"Timestamp"}, 
    {{"anonymous_count", each Table.RowCount(_), Int64.Type}}
  ),
  DailyAnonymousActivities = #"Grouped rows"
in
  DailyAnonymousActivities