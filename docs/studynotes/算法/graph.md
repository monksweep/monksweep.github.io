```java
public static void saveGraph() {
        List<AiGraphVertex> vertexList = new ArrayList<>();
        List<AiProductModulesDTO> scenicPoiList = AiGraphVertex.findAiProductModules();
        for (AiProductModulesDTO scenicPoi : scenicPoiList) {
            AiGraphVertex vertex = new AiGraphVertex();
            vertex.citycode = scenicPoi.citycode;
            vertex.cityname = scenicPoi.cityname;
            vertex.productmodulesid = scenicPoi.productmodulesid;
            vertex.modulename = scenicPoi.modulename;
            vertex.longitude = scenicPoi.longitude;
            vertex.latitude = scenicPoi.latitude;
            vertex.opentime = scenicPoi.opentime;
            vertex.avgplaytime = scenicPoi.besttimetovisit;
            vertex.save();
            vertexList.add(vertex);
        }

        List<AiGraphEdge> edgeList = getEdges(vertexList);
        for (AiGraphEdge edge : edgeList) {
            edge.save();
        }
    }

    private static List<AiGraphEdge> getEdges(List<AiGraphVertex> vertexList) {
        List<AiGraphEdge> edgeList = new ArrayList<>();

        for (int i = 0; i < vertexList.size(); i++) {
            for (int j = i + 1; j < vertexList.size(); j++) {
                AiGraphVertex vertexA = vertexList.get(i);
                AiGraphVertex vertexB = vertexList.get(j);
                String vertexPoiA = String.join(",", vertexA.longitude, vertexA.latitude);
                String vertexPoiB = String.join(",", vertexB.longitude, vertexB.latitude);

                RouteRes routeRes = PoiUtil.driveRoutePlan(vertexPoiA, vertexPoiB, null, PoiUtil.GAO_DE_KEY);
                if (routeRes != null) {
                    // 从所有的推荐线路中获取时间最短的方式
                    List<Path> paths = routeRes.getPaths();
                    Optional<Path> minPathOptional = paths.stream().reduce((s1, s2) -> Integer.parseInt(s1.getDuration()) < Integer.parseInt(s2.getDuration()) ? s1 : s2);
                    if (minPathOptional.isPresent()) {
                        Path path = minPathOptional.get();

                        int duration = Integer.parseInt(path.getDuration()) / 60;
                        edgeList.add(new AiGraphEdge(vertexA.id, vertexB.id, Double.valueOf(path.getDistance()), duration, routeRes.getTaxi_cost()));
                    }
                }
            }
        }
        return edgeList;
    }

    public static void generateRoutePlan(Long startPoint, String cityCode) {
        AiGraphVertex startPointVertex = AiGraphVertex.findByProductModules(startPoint);

        // 构建图
        SimpleWeightedGraph<AiGraphVertex, DefaultWeightedEdge> graph = buildGraph();

        // 使用迪克斯特拉算法计算单源最短路径
        DijkstraShortestPath<AiGraphVertex, DefaultWeightedEdge> shortestPath = new DijkstraShortestPath<>(graph);

        List<AiRoutePlanBase> routePlanList = new ArrayList<>();

        // 使用弗洛依德算法计算任意两个顶点之间的最短路径
        FloydWarshallShortestPaths<AiGraphVertex, DefaultWeightedEdge> floydWarshallShortestPaths = new FloydWarshallShortestPaths<>(graph);
        ArrayList<AiGraphVertex> vertexes = new ArrayList<>(graph.vertexSet());
        for (int i = 0; i < vertexes.size(); i++) {
            for (int j = i + 1; j < vertexes.size(); j++) {
                AiGraphVertex v1 = vertexes.get(i);
                AiGraphVertex v2 = vertexes.get(j);

                if (!v1.productmodulesid.equals(startPoint) && !v2.productmodulesid.equals(startPoint) && !v1.equals(v2)) {
                    GraphPath<AiGraphVertex, DefaultWeightedEdge> graphPath = floydWarshallShortestPaths.getPath(v1, v2);

                    // v1和v2最短路径之间的所有顶点
                    List<AiGraphVertex> graphPathVertexList = graphPath.getVertexList();
                    String route = graphPathVertexList.stream().map(e -> e.modulename).collect(Collectors.joining("->"));

                    double startToV1SpendTime = shortestPath.getPath(startPointVertex, v1).getWeight();
                    double startToV2SpendTime = shortestPath.getPath(startPointVertex, v2).getWeight();

                    double minSpendTime;
                    double spendTime = graphPath.getWeight();
                    if (startToV1SpendTime < startToV2SpendTime) {
                        minSpendTime = startToV1SpendTime + spendTime;
                    } else {
                        minSpendTime = startToV2SpendTime + spendTime;
                    }


                    System.out.println(startPoint + "->" + route + "最短路径为："+ minSpendTime);
                }
            }
        }
    }

    private static SimpleWeightedGraph<AiGraphVertex, DefaultWeightedEdge> buildGraph() {
        SimpleWeightedGraph<AiGraphVertex, DefaultWeightedEdge> graph = new SimpleWeightedGraph<>(DefaultWeightedEdge.class);
        // 添加顶点
        // TODO 根据条件查询顶点
        List<AiGraphVertex> vertexList = AiGraphVertex.findAll();
        for (AiGraphVertex vertex : vertexList) {
            graph.addVertex(vertex);
        }
        // 添加边
        // TODO 根据条件查询边
        Map<Long, AiGraphVertex> vertexMap = vertexList.stream().collect(Collectors.toMap(e -> e.id, e -> e));
        List<AiGraphEdge> edgeList = AiGraphEdge.findAll();
        for (AiGraphEdge edge : edgeList) {
            AiGraphVertex vertexStart = vertexMap.get(edge.vertexstart);
            AiGraphVertex vertexEnd = vertexMap.get(edge.vertexend);

            DefaultWeightedEdge weightedEdge = graph.addEdge(vertexStart, vertexEnd);
            graph.setEdgeWeight(weightedEdge, edge.spendtime);
        }
        return graph;
    }
```

