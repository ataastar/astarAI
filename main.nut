require("town.nut");
require("route.nut");
require("location.nut");
require("constants.nut");
require("engine.nut");

class AstarAI extends AIController {

    function Start();

    static buildDriveThroughRoadStation =
      function(stopLocation) {
        //AILog.Info("BuildDriveThroughRoadStation-stopLocation: " + stopLocation);
        foreach (neighbourLocation in stopLocation.getNeighbourhood()) {
          if (AIRoad.BuildDriveThroughRoadStation(stopLocation.id, neighbourLocation.id, AIRoad.ROADVEHTYPE_BUS, AIStation.STATION_NEW)) {
            return true;
          }
        }
        AILog.Info("buildDriveThroughRoadStation was not success.");
        return false;
      }

    static canBuildRoadDepot =
      function(stopLocation) {
        AILog.Info("canBuildRoadDepo-stopLocation: " + stopLocation);
        if (AITile.IsBuildable(stopLocation.id)) {
        AILog.Info("buildable: " + stopLocation);
          foreach (neighbourLocation in stopLocation.getNeighbourhood()) {
            if (AIRoad.IsRoadTile(neighbourLocation.id)) {
              return true;
            }
          }
          AILog.Info("canBuildRoadDepo was not success.");
          return false;
        }
        return false;
      }

}

function AstarAI::Start() {
  AILog.Info("AstarAI started.");
  AILog.Info(AICompany.GetBankBalance(AICompany.COMPANY_SELF));
  ChooseCompanyName();
  AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
  /*AILog.Info("Company name is set");
  AILog.Info("GetLoanAmount: " + AICompany.GetLoanAmount());
  AILog.Info("GetLoanInterval: " + AICompany.GetLoanInterval());
  AILog.Info("GetMaxLoanAmount: " + AICompany.GetMaxLoanAmount());
  AILog.Info("GetMapSize: " + AIMap.GetMapSize());*/
  /*local townCount = AITown.GetTownCount ();
  local mostPopulationTown = GetMostPopulationTown();
  local location = AITown.GetLocation (mostPopulationTown);*/
  //LogTile(location/*, mostPopulationTown*/, location);
  //LogTile(location-1/*, mostPopulationTown*/, location);
  /*local cargo = AICargoList();
  foreach (x,y in cargo) {
      AILog.Info(AICargo.GetName(x) + ": " + x);
  }*/
  //LogTileNeigbourhood(location, mostPopulationTown);
  //SearchBuildable(location);

  local route = makeRoute();


  while (true) {
    AILog.Info("in loop.");
    this.Sleep(50);
    logProd(route);
  }
}

function AstarAI::getEngineFor(cargo) {
  local engineList = Engine.getList(AIVehicle.VT_ROAD, AIRoad.ROADTYPE_ROAD);
  local isTruck = function(e) { return e.GetRoadType() == AIRoad.ROADTYPE_ROAD; };
  local canTransport = function (e):(cargo) { return e.CanRefitCargo(cargo); }
  //local isNotArticulated = function(e) { return !e.IsArticulated(); }
  engineList = filter( engineList, isTruck );
  engineList = filter( engineList, canTransport );
  // We can't handle articulated vehicles until we use
  // passthrough stations instead of loading bays
  //engineList = makeArray(filter( engineList, isNotArticulated ));
  engineList = makeArray(engineList);
  if ( engineList.len() > 0 ) {
    local engine;
    foreach( e in engineList ) {
      if (engine == null || engine.GetCapacity(cargo) < e.GetCapacity(cargo)) {
        engine = e;
      }
    }
    return engine;
  } else {
    return null;
  }
}

function AstarAI::makeRoute() {
  local route = SearchValuableRoadRoute();
  AILog.Info("route from: " + route[0].id);
  AILog.Info("route to: " + route[1].id);



  local locationFrom = getClosest(route[0], AstarAI.buildDriveThroughRoadStation)
  if (locationFrom == null) {
    AILog.Error("Cannot find location from! " + AIError.GetLastError());
    return;
  }
  local locationTo;
  if (!AstarAI.buildDriveThroughRoadStation(locationFrom)) {
    AILog.Error("Cannot build station from! " + AIError.GetLastError());
    return;
  }
  locationTo = getClosest(route[1], AstarAI.buildDriveThroughRoadStation);
  if (locationTo == null) {
    AILog.Error("Cannot find location to! " + AIError.GetLastError());
    return;
  }
  if (!AstarAI.buildDriveThroughRoadStation(locationTo)) {
    AILog.Error("Cannot build station to! " + AIError.GetLastError());
    return;
  }

  //local radius = AIStation.GetCoverageRadius(AIStation.STATION_BUS_STOP);
  //logProd(locationFrom, locationTo);

  local roadLocations = SearchPossibleRoadBetweenLocations(locationFrom, locationTo);
  buildRoad(roadLocations);
  local depoLocationFrom = getClosest(locationFrom, AstarAI.canBuildRoadDepot);
  if (!buildRoadDepot(depoLocationFrom)) {
    AILog.Error("Cannot build depot from! " + AIError.GetLastError());
    return;
  }
  local depoLocationTo = getClosest(locationTo, AstarAI.canBuildRoadDepot);
  if (!buildRoadDepot(depoLocationTo)) {
    AILog.Error("Cannot build depot to! " + AIError.GetLastError());
    return;
  }

  local engine = getEngineFor(0);

  local travelInDays = estimateDays(locationFrom, locationTo, engine);
  AILog.Info("distance: " + roadLocations.len());
  AILog.Info("Travel in days: " + travelInDays);

  local flags = AIOrder.OF_NON_STOP_INTERMEDIATE | AIOrder.OF_FULL_LOAD_ANY;

  local vehicleFrom = AIVehicle.BuildVehicle(depoLocationFrom.id, engine._id);
  AIOrder.AppendOrder(vehicleFrom, locationFrom.id, flags);
  AIOrder.AppendOrder(vehicleFrom, locationTo.id, flags);
  AIVehicle.StartStopVehicle(vehicleFrom);

  local vehicleTo = AIVehicle.BuildVehicle(depoLocationTo.id, engine._id);
  AIOrder.AppendOrder(vehicleTo, locationTo.id, flags);
  AIOrder.AppendOrder(vehicleTo, locationFrom.id, flags);
  AIVehicle.StartStopVehicle(vehicleTo);

  AILog.Info("locationFrom: " + locationFrom);
  return Route(locationFrom, locationTo, depoLocationFrom, depoLocationTo);
}

function logProd(route) {
  AILog.Info("route.stationFrom: " + route.stationFrom);
  AILog.Info("stationFrom id: " + AIStation.GetStationID(route.stationFrom.id));
  AILog.Info("valid station id: " + AIStation.IsValidStation(AIStation.GetStationID(route.stationFrom.id)));
  local prodFrom = AIStation.GetCargoPlanned(AIStation.GetStationID(route.stationFrom.id), 0);
  AILog.Info("prodFrom: " + prodFrom);
  local prodTo = AIStation.GetCargoPlanned(AIStation.GetStationID(route.stationTo.id), 0);
  AILog.Info("prodTo: " + prodTo);
  AILog.Info("watiting from: " + AIStation.GetCargoWaiting(AIStation.GetStationID(route.stationFrom.id), 0));
  AILog.Info("watiting to: " + AIStation.GetCargoWaiting(AIStation.GetStationID(route.stationTo.id), 0));
}

function buildRoad(roadLocations) {
  local prevRoad = null;
  foreach (road in roadLocations) {
    if (prevRoad != null) {
      AILog.Info(prevRoad);
      AIRoad.BuildRoad(prevRoad.id, road.id);
    }
    prevRoad = road;
  }
}

function AstarAI::GetMostPopulationTown() {
  local mostPopulationTown = 0;
  local mostPopulation = 0;
  for (local i =0; i < townCount; i++) {
    if (AITown.GetPopulation(i) > mostPopulation) {
      mostPopulation = AITown.GetPopulation(i);
      mostPopulationTown = i;
    }
  }
  AILog.Info(AITown.GetName(mostPopulationTown) + ": " + mostPopulation + "prod pass: " + AITown.GetLastMonthProduction(mostPopulationTown, 0));
  return mostPopulationTown;
}

function AstarAI::getClosest(location, condition) {
  local x = location.x;
  local y = location.y;
  local test = AITestMode();
  local isRoadLocation = condition(Location.getXY(x, y));
  local i = 1;
  while (!isRoadLocation && i < 10) {
    for (local j=0; j < i; j++) {
      AILog.Info("start: " + i)
      x = location.x + i;
      y = location.y + j;
      if (condition(Location.getXY(x, y))) {
        isRoadLocation = true;
        break;
      }
      x = location.x - i;
      y = location.y - j;
      if (condition(Location.getXY(x, y))) {
        isRoadLocation = true;
        break;
      }
      x = location.x;
      y = location.y + j;
      if (condition(Location.getXY(x, y))) {
        isRoadLocation = true;
        break;
      }
      y = location.y - j;
      if (condition(Location.getXY(x, y))) {
        isRoadLocation = true;
        break;
      }
    }
    AILog.Info("road not found in this circle: " + i)
    i++;
  }
  AILog.Info("road found in (x, y): " + x + "," + y);
  return isRoadLocation ? Location.getXY(x, y) : null;
}

/**
 * Start go in X direction always. Can not bypass anything. So not sure it can find possible road
 */
function SearchPossibleRoadBetweenLocations(from, to) {
  local road = [];
  local visitedLocations = {};
  local currentLocation = from;
  local directionX = true;
  local nextLocation;
  AILog.Info(from);
  AILog.Info(to);
  road.append(currentLocation);
  while (!currentLocation.equals(to) && road.len() > 0) {
    // get the next location by direction to the destination
    nextLocation = currentLocation.getNextTo(to, directionX);
    //AILog.Info("next: " + nextLocation);
    if (visitedLocations.rawin(nextLocation.id)) {
      //AILog.Info("already visited: " + nextLocation);
      if (!directionX) { // if we tries to get next by in Y direction and it is already visited, then remove the last/previous from the list, because we can not go forward
        local prevLocation = road.pop();
        visitedLocations.rawset(prevLocation.id, prevLocation.id);
        //AILog.Info(prevLocation);
        currentLocation = prevLocation;
        directionX = true;
      } else { // if it is visited then try to go Y direction
        directionX = false;
      }
      continue;
    }
    if (AIRoad.IsRoadTile(nextLocation.id)) {
      //AILog.Info("is road");
      road.append(nextLocation);
      directionX = nextLocation.x != to.x;
      //AIRoad.BuildRoad(currentLocation.id, nextLocation.id);
      currentLocation = nextLocation;
    } else if (AITile.IsBuildable(nextLocation.id)) {
      //AILog.Info("is buildable");
      road.append(nextLocation);
      directionX = nextLocation.x != to.x;
      //AIRoad.BuildRoad(currentLocation.id, nextLocation.id);
      currentLocation = nextLocation;
      //this.Sleep(1);
    } else if (directionX) {
      directionX = false;
      //AILog.Info("direction changed");
    } else {
      //AILog.Info("road can not build");
      local prevLocation = road.pop();
      //AILog.Info(prevLocation);
      // we can not go forward, we go back to the previous x-1 location and sign al of the skipped location as "visited"
      visitedLocations.rawset(prevLocation.id, prevLocation.id);
      while (nextLocation.x == prevLocation.x && road.len() > 0) {
        prevLocation = road.pop();
        if (nextLocation.x == prevLocation.x) {
          visitedLocations.rawset(prevLocation.id, prevLocation.id);
        } else { // no need remove the last one (because it is in other X coordination)
          road.append(prevLocation);
        }
        //AILog.Info(prevLocation);
      }
      currentLocation = prevLocation;
    }
  }
  return road;
}

function buildRoadDepot(stopLocation) {
  AILog.Info("BuildRoadDepot-stopLocation: " + stopLocation);
  foreach (neighbourLocation in stopLocation.getNeighbourhood()) {
    if (AIRoad.IsRoadTile(neighbourLocation.id) && AIRoad.BuildRoadDepot(stopLocation.id, neighbourLocation.id)) {
      AIRoad.BuildRoad(stopLocation.id, neighbourLocation.id);
      return true;
    }
  }
  AILog.Info("BuildRoadDepot was not success.");
  return false;
}


/**
 * Searches a valuable route for buses. not too far not too close
 */
function AstarAI::SearchValuableRoadRoute() {
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
        local prodFrom = AITown.GetLastMonthProduction(townFrom.id, 0); // TODO 0
        local prodTo = AITown.GetLastMonthProduction(townTo.id, 0);
        if (maxProd < prodFrom + prodTo) {
          maxProd = prodFrom + prodTo;
          fromTownIndex = townFrom.id;
          toTownIndex = townTo.id;
          //AILog.Info(maxProd);
        }
      }
    }
  }
  LogTown(fromTownIndex);
  LogTown(toTownIndex);
  //AILog.Info(maxProd);
  return [Location.get(AITown.GetLocation(fromTownIndex)), Location.get(AITown.GetLocation(toTownIndex))];
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
  local location = Location.get(AITown.GetLocation(townIndex));
  AILog.Info("Name: " + AITown.GetName(townIndex) + ", location: " + location);
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

function AstarAI::ChooseCompanyName() {
  if (!AICompany.SetName("AstarAI")) {
    local i = 2;
    while (!AICompany.SetName("AstarAI #" + i)) {
      i = i + 1;
    }
  }
}

function makeArray(seq) {
  local result = [];
  foreach(x in seq) {
    result.push(x);
  }
  return result;
}

function filter(list, fun) {
  local result = [];
  foreach( value in list ) {
    if (fun(value)) {
      result.append(value);
    }
  }
  return result;
}


function AstarAI::estimateDays(tileFrom, tileTo, engine) {
  local distance = AITile.GetDistanceManhattanToTile(tileFrom.id, tileTo.id);
  local distanceInKm = distance * KMISH_PER_TILE;
  /*local engine = GetEngineFor(cargo, null, null);
  if(!engine) {
    return;
  }*/
  local speed = engine.GetMaxSpeed();
  local travelTimeInDays = distanceInKm  / speed / 24;
  return travelTimeInDays + 2*ROAD_DAYS_AT_STATION; // add a few days for load/unload TODO
}

/**
 * The function called when stopping the AI.
 */
function AstarAI::Stop() {}

function AstarAI::Save() {
  local table = {};
  return table;
}
function AstarAI::Load(version,data) {}
