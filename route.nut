class Route {
  stationFrom = null;
  stationTo = null;
  depotFrom = null;
  depotTo = null;

  constructor(locationFrom, locationTo) {
    this.locationFrom = locationFrom;
    this.locationTo = locationTo;
  }
}

function Town::_tostring() {
    return "[locationFrom: " + locationFrom + ", locationTo: " + locationTo + "]";
}
