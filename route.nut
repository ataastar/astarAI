class Route {
  stationFrom = null;
  stationTo = null;
  depotFrom = null;
  depotTo = null;

  constructor(locationFrom, locationTo, depotFrom, depotTo) {
    this.stationFrom = locationFrom;
    this.stationTo = locationTo;
    this.depotFrom = depotFrom;
    this.depotTo = depotTo;
  }
}

function Town::_tostring() {
    return "[locationFrom: " + locationFrom + ", locationTo: " + locationTo + ", depotFrom: " + depotFrom + ", depotTo: " + depotTo + "]";
}
