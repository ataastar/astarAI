 class AstarAI extends AIInfo
 {
   function GetAuthor()        { return "Astar"; }
   function GetName()          { return "AstarAI"; }
   function GetDescription()   { return "An AI for test purpose."; }
   function GetVersion()       { return 1; }
 //  function MinVersionToLoad() { return 1; }
   function GetDate()          { return "2022-05-01"; }
   function CreateInstance()   { return "AstarAI"; }
   function GetShortName()     { return "ASTA"; }
   function GetAPIVersion()    { return "1.2"; }

 }

 RegisterAI(AstarAI());
