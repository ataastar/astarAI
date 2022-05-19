class Location {
  id = null;
  x = null;
  y = null;
  
  static locations = {};
  
  constructor(id) {
    this.id = id;
    x = AIMap.GetTileX(id);
    y = AIMap.GetTileY(id);
  }
  
  static function getXY(x, y) {
    return Location.get(AIMap.GetTileIndex(x,y));
  }

  static function get(id) {
    if (Location.locations.rawin(id)) {
      return Location.locations.rawget(id);
    }
    local l = Location(id);
    Location.locations.rawset(id, l);
    return l;
  }
}

function Location::_tostring() {
    return "[Id: " + id + ", X: " + x + ", Y: " + y + "]";
}

function Location::equals(o) {
    return id == o.id;
}

function Location::getNextTo(to, directionX) {
    if (directionX) {
      if (x > to.x) {
        return Location.getXY(x-1, y);
      } else {
        return Location.getXY(x+1, y);
      }
    } else {
      if (y > to.y) {
        return Location.getXY(x, y-1);
      } else {
        return Location.getXY(x, y+1);
      }
    }
}
