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
  #"Choose columns" = Table.SelectColumns(
    #"Expanded RawEventData", 
    {"RawEventData.UserId", "Timestamp"}
  ), 
  #"Changed column type to date" = Table.TransformColumnTypes(
    #"Choose columns", 
    {{"Timestamp", type date}}
  ), 
  #"Grouped rows" = Table.Group(
    #"Changed column type to date", 
    {"Timestamp"}, 
    {{"Count", each Table.RowCount(Table.Distinct(_)), Int64.Type}}
  ), 
  DailyActiveUsers = #"Grouped rows"
in
  DailyActiveUsers