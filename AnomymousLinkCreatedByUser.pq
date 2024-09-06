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
    #"Filtered rows" = Table.SelectRows(#"Expanded RawEventData", each [ActionType] = "AnonymousLinkCreated"),
    #"Grouped rows" = Table.Group(anonymous_link_created, {"AccountDisplayName", "RawEventData.UserId"}, {{"Count", each Table.RowCount(_), Int64.Type}, {"LastCreated", each List.Max([Timestamp]), type nullable datetime}}),
    AnonymousLineCreatedByUser = #"Grouped rows"
in
    AnonymousLineCreatedByUser