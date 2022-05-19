require("town.nut");
require("route.nut");
require("location.nut");

class AstarAI extends AIController {

    function Start();
}

function AstarAI::Start() {
  AILog.Info("AstarAI started.");
  AILog.Info(AICompany.GetBankBalance(AICompany.COMPANY_SELF));
  ChooseCompanyName();
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
  AILog.Info("Company name is set");
  AILog.Info("GetLoanAmount: " + AICompany.GetLoanAmount());
  AILog.Info("GetLoanInterval: " + AICompany.GetLoanInterval());
  AILog.Info("GetMaxLoanAmount: " + AICompany.GetMaxLoanAmount());
  AILog.Info("GetMapSize: " + AIMap.GetMapSize());
  local townCount = AITown.GetTownCount ();
  local mostPopulationTown = 0;
  local mostPopulation = 0;
  for (local i =0; i < townCount; i++) {
    if (AITown.GetPopulation(i) > mostPopulation) {
      mostPopulation = AITown.GetPopulation(i);
      mostPopulationTown = i;
    }
  }
  AILog.Info(AITown.GetName(mostPopulationTown) + ": " + mostPopulation + "prod pass: " + AITown.GetLastMonthProduction(mostPopulationTown, 0));
  local location = AITown.GetLocation (mostPopulationTown);
  LogTile(location/*, mostPopulationTown*/, location);
  LogTile(location-1/*, mostPopulationTown*/, location);
  local cargo = AICargoList();
  foreach (x,y in cargo) {
      AILog.Info(AICargo.GetName(x));
  }
  //LogTileNeigbourhood(location, mostPopulationTown);
  //SearchBuildable(location);
  local route = searchValuableRoadRoute();
  AILog.Info("route from: " + route.locationFrom);
  AILog.Info("route to: " + route.locationTo);

  if (BuildStationInCityCenter(route.locationFrom)) {
    if (BuildStationInCityCenter(route.locationTo)) {
      AILog.Info("station built");
    } else {
      AILog.Info("station to can not built");
    }    
  } else {
    AILog.Info("station from can not built");
  }
  SearchPossibleRoadBetweenLocations(route.locationFrom, route.locationTo);
  while (true) {
    AILog.Info("in loop.");
    this.Sleep(1000);
  }
}

function AstarAI::BuildStationInCityCenter(location) {
  return GetClosestRoad(location) != null;
  /*local x = AIMap.GetTileX(stopLocation);
  local y = AIMap.GetTileY(stopLocation);
  if (AIRoad.BuildDriveThroughRoadStation(stopLocation, AIMap.GetTileIndex(x+1, y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)) {
    return true;
  }
  AILog.Info("BuildStationInCityCenter 2.");
  if (AIRoad.BuildDriveThroughRoadStation(stopLocation, AIMap.GetTileIndex(x-1, y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)) {
    return true;
  }
  AILog.Info("BuildStationInCityCenter 3.");
  if (AIRoad.BuildDriveThroughRoadStation(stopLocation, AIMap.GetTileIndex(x, y-1), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)) {
    return true;
  }
  AILog.Info("BuildStationInCityCenter 4.");
  if (AIRoad.BuildDriveThroughRoadStation(stopLocation, AIMap.GetTileIndex(x, y-1), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)) {
    return true;
  }
  AILog.Info("BuildStationInCityCenter was not success.");*/
  //return false;
}

function AstarAI::GetClosestRoad(location) {
  local stopLocation = location;
  local xIndex = AIMap.GetTileX(location);
  local yIndex = AIMap.GetTileY(location);
  local x = xIndex;
  local y = yIndex;
  local isRoadLocation = CanBuildDriveThroughRoadStation(AIMap.GetTileIndex(xIndex, yIndex)) && BuildDriveThroughRoadStation(AIMap.GetTileIndex(x, y));
  local i = 1;
  while (!isRoadLocation && i < 10) {
    for (local j=0; j < i; j++) {
      AILog.Info("start: " + i)
      x = xIndex + i;
      y = yIndex + j;
      if (CanBuildDriveThroughRoadStation(AIMap.GetTileIndex(x, y)) && BuildDriveThroughRoadStation(AIMap.GetTileIndex(x, y))) {
        isRoadLocation = true;
        break;
      }
      x = xIndex - i;
      y = yIndex - j;
      if (CanBuildDriveThroughRoadStation(AIMap.GetTileIndex(x, y)) && BuildDriveThroughRoadStation(AIMap.GetTileIndex(x, y))) {
        isRoadLocation = true;
        break;
      }
      x = xIndex;
      y = yIndex + j;
      if (CanBuildDriveThroughRoadStation(AIMap.GetTileIndex(x, y)) && BuildDriveThroughRoadStation(AIMap.GetTileIndex(x, y))) {
        isRoadLocation = true;
        break;
      }
      y = yIndex - j;
      if (CanBuildDriveThroughRoadStation(AIMap.GetTileIndex(x, y)) && BuildDriveThroughRoadStation(AIMap.GetTileIndex(x, y))) {
        isRoadLocation = true;
        break;
      }
    }
    AILog.Info("road not found in this circle: " + i)
    i++;
  }
  AILog.Info("road found in (x, y): " + x + "," + y);
  return isRoadLocation ? AIMap.GetTileIndex(x, y) : null;
}

function AstarAI::BuildDriveThroughRoadStation(stopLocation) {
  local x = AIMap.GetTileX(stopLocation);
  local y = AIMap.GetTileY(stopLocation);
  AILog.Info("try to build " + stopLocation + " (" + x + "," + y + ")");
  if (AIRoad.BuildDriveThroughRoadStation(stopLocation, AIMap.GetTileIndex(x+1, y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)) {
    return true;
  }
  //AILog.Info("BuildStationInCityCenter 2.");
  if (AIRoad.BuildDriveThroughRoadStation(stopLocation, AIMap.GetTileIndex(x-1, y), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)) {
    return true;
  }
  //AILog.Info("BuildStationInCityCenter 3.");
  if (AIRoad.BuildDriveThroughRoadStation(stopLocation, AIMap.GetTileIndex(x, y-1), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)) {
    return true;
  }
  //AILog.Info("BuildStationInCityCenter 4.");
  if (AIRoad.BuildDriveThroughRoadStation(stopLocation, AIMap.GetTileIndex(x, y-1), AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)) {
    return true;
  }
  AILog.Info("BuildStationInCityCenter was not success.");
  return false;
}

function CanBuildDriveThroughRoadStation(location) {
  local x = AIMap.GetTileX(location);
  local y = AIMap.GetTileY(location);
  //AILog.Info("location is road: " + AIRoad.IsRoadTile(location));
  local x_ = AIRoad.IsRoadTile(AIMap.GetTileIndex(x+1, y));
  local _x = AIRoad.IsRoadTile(AIMap.GetTileIndex(x-1, y));
  local y_ = AIRoad.IsRoadTile(AIMap.GetTileIndex(x, y+1));
  local _y = AIRoad.IsRoadTile(AIMap.GetTileIndex(x, y-1));
  if (AIRoad.IsRoadTile(location)) {
    return x_ && _x && !y_ && !_y 
      || !x_ && !_x && y_ && _y;
  }
  if (AITile.PlantTree(location)) {
    AILog.Info("Tree is built!!! " + location + " (" + x + "," + y + ")");
    this.Sleep(100);
  }
  return false;
}

function SearchPossibleRoadBetweenLocations(f, t) {
  local road = [];
  local from = Location.get(f);
  local to = Location.get(t);
  local currentLocation = from;
  local directionX = true;
  local nextLocation;
  AILog.Info(from);
  AILog.Info(to);
  while (!currentLocation.equals(to)) {
    nextLocation = currentLocation.getNextTo(to, directionX);
    AILog.Info(nextLocation);
    if (AIRoad.IsRoadTile(nextLocation.id)) {
      AILog.Info("is road");
      road.append(nextLocation);
      directionX = true;
    } else if (AITile.IsBuildable(nextLocation.id)) {
      AILog.Info("is buildable");
      road.append(nextLocation);
      directionX = true;
    } else if (directionX) {
      directionX = false;
    } else {
      AILog.Info("road can not build");
      break;
    } 
    break;
  }
}

/**
 * Searches a valuable route for buses. not too far not too close
 */
function AstarAI::searchValuableRoadRoute() {
  local townList = getTowns();
  /*townList.sort(
    function(a,b) { 
      if (a.population == b.population) return 0;
      if (a.population > b.population) return -1;
      return 1;
    }
  );  */
  local maxProd = 0;
  local fromTownIndex = 0;
  local toTownIndex = 0;
  foreach( townFrom in townList ) {
    local locationFrom = AITown.GetLocation(townFrom.id);
    foreach( townTo in townList ) {
      local locationTo = AITown.GetLocation(townTo.id);
      local distance = AIMap.DistanceManhattan(locationFrom, locationTo)
      if (distance > 50 && distance < 70) {
        local prodFrom = AITown.GetLastMonthProduction(townFrom.id, 0);
        local prodTo = AITown.GetLastMonthProduction(townTo.id, 0);
        if (maxProd < prodFrom + prodTo) {
          maxProd = prodFrom + prodTo;
          fromTownIndex = townFrom.id;
          toTownIndex = townTo.id;
          AILog.Info(maxProd);
        }
      }
    }
  }
  LogTown(fromTownIndex);
  LogTown(toTownIndex);
  AILog.Info(maxProd);
  return Route(AITown.GetLocation(fromTownIndex), AITown.GetLocation(toTownIndex));
}

function AstarAI::getTowns() {
  local townCount = AITown.GetTownCount ();
  local towns = [];
  for (local i = 0; i < townCount; i++) {
    towns.append(Town(i, AITown.GetName(i), AITown.GetPopulation(i)));
  }
  return towns;
}


function AstarAI::LogTileNeigbourhood(location/*, townId*/) {
  AILog.Info("LogTileNeigbourhood");
  local xIndex = AIMap.GetTileX(location);
  local yIndex = AIMap.GetTileY(location);
  for (local x=xIndex - 5; x <= xIndex + 5; x++) {
    for (local y=yIndex - 5; y <= yIndex + 5; y++) {
      local locationToLog = AIMap.GetTileIndex(x, y);
      LogTile(locationToLog/*, townId*/, location);
    }
  }
}

function AstarAI::LogTown(townIndex) {
  local location = AITown.GetLocation(townIndex);
  AILog.Info("Name: " + AITown.GetName(townIndex) + ", location: " + location + "(" + AIMap.GetTileX(location) + ", " + AIMap.GetTileY(location) + ")");
}

function AstarAI::LogTile(location/* townId*/, townLocation) {
  /*
  AILog.Info("location: " + location + " (" + AIMap.GetTileX(location) + ", " + AIMap.GetTileY(location) + ")");
  AILog.Info("  IsWithinTownInfluence: " + AITown.IsWithinTownInfluence(townId, location));
  AILog.Info("  IsRoadTile: " + AIRoad.IsRoadTile(location));
  AILog.Info("  AreRoadTilesConnected: " + AIRoad.AreRoadTilesConnected(location, location-1));
  AILog.Info("  GetNeighbourRoadCount: " + AIRoad.GetNeighbourRoadCount(location));
  AILog.Info("  GetDistanceManhattanToTile: " + AITile.GetDistanceManhattanToTile(location, location-1));
  AILog.Info("  GetDistanceSquareToTile: " + AITile.GetDistanceSquareToTile(location, location-1));
  */
  AILog.Info("location: " + location + " (" + AIMap.GetTileX(location) + ", " + AIMap.GetTileY(location) + ")"
    //+ ";IsWithinTownInfluence: " + AITown.IsWithinTownInfluence(townId, location) + ";"
    + "IsRoadTile: " + AIRoad.IsRoadTile(location) + ";"
    + "AreRoadTilesConnected: " + AIRoad.AreRoadTilesConnected(location, townLocation) + ";"
    + "GetNeighbourRoadCount: " + AIRoad.GetNeighbourRoadCount(location) + ";"
    + "DistanceManhattan: " + AIMap.DistanceManhattan(location, townLocation) + ";"
    + "DistanceMax: " + AIMap.DistanceMax(location, townLocation) + ";"
    + "DistanceFromEdge: " + AIMap.DistanceFromEdge(location) + ";"
    + "DistanceSquare: " + AIMap.DistanceSquare(location, townLocation));
}



function AstarAI::SearchBuildable(location) {
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
  local buildable = AITile.IsBuildable(location);
  AILog.Info(buildable);
  local isRoad = AIRoad.IsRoadTile(location);
  AILog.Info("isRoad: " + isRoad);
  if (isRoad) {
  AILog.Info("location - 1 is road: " + AIRoad.IsRoadTile(location-1));
  /*local stationResult = AIRoad.BuildDriveThroughRoadStation(location, location - 1, AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW);
  AILog.Info("stationResult: " + stationResult);
  local stationResult2 = AIRoad.BuildDriveThroughRoadStation(location-1, location - 2, AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW);
  AILog.Info("stationResult: " + stationResult2);*/
  }
}

function AstarAI::ChooseCompanyName() {
  if (!AICompany.SetName("AstarAI")) {
    local i = 2;
    while (!AICompany.SetName("AstarAI #" + i)) {
      i = i + 1;
    }
  }
}

/**
 * The function called when stopping the AI.
 */
function AstarAI::Stop() {
}

function AstarAI::Save() {
  local table = {};
  return table;
}
function AstarAI::Load(version,data) {
}
