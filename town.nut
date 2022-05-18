class Town {
  id = null;
  name = null;
  population = null;
  
  constructor(id, name, population) {
    this.id = id;
    this.name = name;
    this.population = population;
  }
}

function Town::_tostring() {
    return "[Id: " + id + ", Name: " + name + ", population: " + population + "]";
}
