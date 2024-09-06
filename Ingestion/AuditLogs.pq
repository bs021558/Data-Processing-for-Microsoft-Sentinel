let
  // You can change it.
  #"LogicalTime" = "startofday(now())", 
  #"KQL_String" = " 
    let EndTime = "
    & LogicalTime
    & ";
    let StartTime = EndTime - 24h;
    AuditLogs
    | where TimeGenerated > StartTime and TimeGenerated < EndTime
  ", 
  #"TypeMap" = #table(
    {"AnalyticsTypes", "Type"}, 
    {
      {"string", Text.Type}, 
      {"int", Int32.Type}, 
      {"long", Int64.Type}, 
      {"real", Double.Type}, 
      {"timespan", Duration.Type}, 
      {"datetime", DateTimeZone.Type}, 
      {"bool", Logical.Type}, 
      {"guid", Text.Type}, 
      {"dynamic", Text.Type}
    }
  ), 
  #"Response" = Json.Document(
    Web.Contents(
      "https://api.loganalytics.io/v1/workspaces/{WORKSPACE_ID}/query", 
      [
        Query = [
          #"query"    = KQL_String, 
          #"x-ms-app" = "OmsAnalyticsPBI", 
          #"prefer"   = "ai.response-thinning=true"
        ], 
        Timeout = #duration(0, 0, 4, 0)
      ]
    )
  ), 
  #"DataTable" = #"Response"[tables]{0}, 
  #"Columns" = Table.FromRecords(#"DataTable"[columns]), 
  #"Rows" = Table.FromRows(#"DataTable"[rows], #"Columns"[name]), 
  #"ParsedType" = Table.Join(#"Columns", {"type"}, #"TypeMap", {"AnalyticsTypes"}), 
  #"ParsedJSON" = Table.TransformColumnTypes(
    #"Rows", 
    Table.ToList(#"ParsedType", (c) => {c{0}, c{3}})
  ), 
  #"ReplacedErrors" = Table.ReplaceErrorValues(
    #"ParsedJSON", 
    {
      {"TenantId", null}, 
      {"SourceSystem", null}, 
      {"TimeGenerated", null}, 
      {"ResourceId", null}, 
      {"OperationName", null}, 
      {"OperationVersion", null}, 
      {"Category", null}, 
      {"ResultType", null}, 
      {"ResultSignature", null}, 
      {"ResultDescription", null}, 
      {"DurationMs", null}, 
      {"CorrelationId", null}, 
      {"Resource", null}, 
      {"ResourceGroup", null}, 
      {"ResourceProvider", null}, 
      {"Identity", null}, 
      {"Level", null}, 
      {"Location", null}, 
      {"AdditionalDetails", null}, 
      {"Id", null}, 
      {"InitiatedBy", null}, 
      {"LoggedByService", null}, 
      {"Result", null}, 
      {"ResultReason", null}, 
      {"TargetResources", null}, 
      {"AADTenantId", null}, 
      {"ActivityDisplayName", null}, 
      {"ActivityDateTime", null}, 
      {"AADOperationType", null}, 
      {"Type", null}
    }
  ),
  AuditLogs = #"ReplacedErrors"
in
  AuditLogs