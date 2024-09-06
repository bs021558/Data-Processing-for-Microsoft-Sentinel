let
  Source = CloudAppEvents,
  #"Choose columns" = Table.SelectColumns(Source, {"ActionType"}),
  #"Grouped rows" = Table.Group(
    action_type,
    {"ActionType"},
    {{"Count", each Table.RowCount(_), Int64.Type}}
  ),
  #"Sorted rows" = Table.Sort(#"Grouped rows", {{"Count", Order.Descending}}),
  ActionTypes = #"Sorted rows"
in
  ActionTypes