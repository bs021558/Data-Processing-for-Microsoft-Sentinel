let
  // You can change it.
  #"LogicalTime" = "startofday(now())", 
  #"KQL_String" = "
    let EndTime = " & #"LogicalTime" & ";
    let StartTime = EndTime - 24h;
    CloudAppEvents
    | where Timestamp > StartTime and Timestamp < EndTime
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
          #"query"    = #"KQL_String", 
          #"x-ms-app" = "OmsAnalyticsPBI", 
          #"prefer"   = "ai.response-thinning=true"
        ], 
        Timeout = #duration(0, 0, 4, 0)
      ]
    )
  ), 
  #"DataTable" = #"Response"[tables]{0}, 
  #"Columns" = Table.FromRecords(#"DataTable"[columns]), 
  #"ParsedType" = Table.Join(#"Columns", {"type"}, #"TypeMap", {"AnalyticsTypes"}), 
  #"Rows" = Table.FromRows(#"DataTable"[rows], #"Columns"[name]), 
  #"ParsedJSON" = Table.TransformColumnTypes(#"Rows", Table.ToList(#"ParsedType", (c) => {c{0}, c{3}})), 
  #"ReplacedErrors" = Table.ReplaceErrorValues(
    #"ParsedJSON", 
    {
      {"TenantId", null}, 
      {"AccountId", null}, 
      {"AccountType", null}, 
      {"AdditionalFields", null}, 
      {"RawEventData", null}, 
      {"ReportId", null}, 
      {"ObjectId", null}, 
      {"ObjectType", null}, 
      {"ObjectName", null}, 
      {"ActivityObjects", null}, 
      {"ActivityType", null}, 
      {"UserAgent", null}, 
      {"ISP", null}, 
      {"City", null}, 
      {"CountryCode", null}, 
      {"IsAnonymousProxy", null}, 
      {"IsExternalUser", null}, 
      {"IsImpersonated", null}, 
      {"IPAddress", null}, 
      {"IPCategory", null}, 
      {"IPTags", null}, 
      {"OSPlatform", null}, 
      {"DeviceType", null}, 
      {"IsAdminOperation", null}, 
      {"AccountDisplayName", null}, 
      {"AccountObjectId", null}, 
      {"AppInstanceId", null}, 
      {"ApplicationId", null}, 
      {"Application", null}, 
      {"ActionType", null}, 
      {"UserAgentTags", null}, 
      {"TimeGenerated", null}, 
      {"Timestamp", null}, 
      {"SourceSystem", null}, 
      {"Type", null}
    }
  ),
  CloudAppEvents = #"ReplaceErrors"
in
  CloudAppEvents