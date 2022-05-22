/*
 * Class that wraps engine ids
 */

class Engine
{
    constructor(id, subType)
    {
	_id = id;
	_capacity = {};
	transportType = _GetTransportType();
	this.subType = subType;

	assert(typeof(id) == "integer");
	assert(transportType != null);
    }

    static function GetList(vehicleType, subType);
    function GetRoadType();
    function GetId();
    function CanRefitCargo(cargoId);
    function GetCapacity(cargoId);
    function IsArticulated();

    function _GetTransportType();
    function _tostring();

    //static _logger = Log.GetLogger("Engine");
    static _engines = {};

    transportType = null;
    subType = null;
    _id = null;
    _capacity = null;




};


function Engine::GetList(vehicleType, subType)
{
    local result = [];
    local ids = tableKeys(AIEngineList(vehicleType));
    foreach( id in ids ) 
    {
	if (vehicleType == AIVehicle.VT_ROAD && AIEngine.GetRoadType(id) != subType)
	    continue;
	if (vehicleType == AIVehicle.VT_RAIL && AIEngine.GetRailType(id) != subType)
	    continue;

	if ( !(id in Engine._engines))
	{
	    Engine._engines[id] <- Engine(id, subType);
	}
	result.push(Engine._engines[id]);
    }
    return result;
}


function Engine::GetId()
{
    return _id;
}

function Engine::_tostring()
{
    return "[Engine " + AIEngine.GetName(_id) + "]";
}


function Engine::GetName()
{
    return AIEngine.GetName(_id);
}


function Engine::GetMaxSpeed()
{
    return AIEngine.GetMaxSpeed(_id);
}


function Engine::GetRunningCost()
{
    return AIEngine.GetRunningCost(_id);
}


function Engine::GetCargoType()
{
    return AIEngine.GetCargoType(_id);
}


function Engine::_GetCapacityFromDepot(cargoId, depotId)
{
    local result = null;
    local vehicleId = AIVehicle.BuildVehicle(depotId, _id);
    if (!AIVehicle.IsValidVehicle(vehicleId))
    {
	if (AIError.GetLastError() == AIVehicle.ERR_VEHICLE_WRONG_DEPOT)
	{
	    return null;
	}
	else
	{
	    AILog.Info("GetCapacity unable to build vehicle:", AIError.GetLastErrorString());
	    throw(AIError.GetLastErrorString());
	}
    }
    foreach (c in tableKeys(AICargoList())) 
    {
	if (!AIEngine.CanRefitCargo(_id,c))
            continue;
	if (c in _capacity)
	    continue;
	local capacity = AIVehicle.GetRefitCapacity(vehicleId,c);
	result = capacity;
    }
    AIVehicle.SellVehicle(vehicleId);
    return result;
}

function Engine::_GetCapacity(cargoId, transportType)
{
    AILog.Info("GetCapacity", cargoId, transportType);
    local depots = tableKeys(AIDepotList(transportType));
    foreach(depotId in depots)
    {
	local capacity = _GetCapacityFromDepot(cargoId, depotId);
	if (capacity != null)
	{
	    return capacity;
	}
    }
    local depot = Depot.BuildRandom(transportType, subType);
    local capacity = _GetCapacityFromDepot(cargoId, depot.location);
    depot.Destroy();
    return capacity;
}

function Engine::_GetTransportType()
{

    // To compute the capacity of a non standard value
    // try to build one vehicle and then compute the values for all the cargo
    local transportType = null;
    switch( AIEngine.GetVehicleType(_id))
    {
    case AIVehicle.VT_ROAD:
	transportType = AITile.TRANSPORT_ROAD;
	break;
    case AIVehicle.VT_RAIL:
	transportType = AITile.TRANSPORT_RAIL;
	break;
    case AIVehicle.VT_AIR:
	transportType = AITile.TRANSPORT_AIR;
	break;
    case AIVehicle.VT_WATER:
	transportType = AITile.TRANSPORT_WATER;
	break;
    case AIVehicle.VT_INVALID:
	AILog.Info("GetCapacity: invalid vehicle type passed " + _id);
	assert(false);
	break;
    default:
	AILog.Info("GetCapacity: unknown vehicle type " + _id);
	assert(false);
	}
    return transportType;
}


function Engine::GetCapacity(cargoId)
{
    if (cargoId in _capacity)
    {
	return _capacity[cargoId];
    }
    if ( GetCargoType() == cargoId )
    {
	_capacity[cargoId] <- AIEngine.GetCapacity(_id);
	return _capacity[cargoId];
    }
    local capacity = _GetCapacity(cargoId, transportType);
    if (capacity != null)
    {
	_capacity[cargoId] <- capacity;
    }
    
    AILog.Info("Capacity for", this, ":",capacity);
    if (cargoId in _capacity)
    {
	return _capacity[cargoId];
    }
    return 0;
}


function Engine::GetRoadType()
{
    return AIEngine.GetRoadType(_id);
}


function Engine::CanRefitCargo(cargoId)
{
    return AIEngine.CanRefitCargo(_id, cargoId);
}

function Engine::IsArticulated()
{
    return AIEngine.IsArticulated(_id);
}
