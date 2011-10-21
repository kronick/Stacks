class InterlayerConnector {
  public int topLayer;
  public int topNodeIndex, bottomNodeIndex;

  InterlayerConnector(int topLayer, int topNodeIndex, int bottomNodeIndex) {
    this.topLayer = topLayer;
    this.topNodeIndex = topNodeIndex;
    this.bottomNodeIndex = bottomNodeIndex;
  }  
}
