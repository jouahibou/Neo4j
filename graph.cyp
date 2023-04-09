LOAD CSV WITH HEADERS FROM 'https://github.com/pauldechorgnat/cool-datasets/raw/master/ratp/stations.csv' AS line
CREATE (s:stations{
    nom_clean:line.nom_clean,
    nom_gare:line.nom_gare,
    x:toFloat(line.x),
    y:toFloat(line.y),
    trafic:toInt(line.Trafic),
    Ville:line.Ville
    })
MATCH (s:station)
WITH s.ligne AS ligne , collect(DISTINCT s) AS stations
FOREACH (i IN RANGE(0,size(stations)-2) | 
  FOREACH (j IN RANGE (i+1 ,size(stations)-1)|
       CREATE (stations[i])-[:CORRESPONDANCE{temps:240}]->(stations[j]),
       CREATE (stations[j])-[:CORRESPONDANCE{temps:240}]->(stations[i])
        ))
UNWIND stations AS s 
MERGE (1:Ligne {numero:ligne})
CREATE (l)-[:DESSERVI]->(s)

LOAD CSV WITH HEADERS FROM ' https://github.com/pauldechorgnat/cool-datasets/raw/master/ratp/liaisons.csv' AS row
MATCH (a:station{nom_clean:line.start}), (b:station{nom_clean:line.stop})
WITH a,b distance(point(a),point(b)) AS distance
WHERE distance <= 1000 // Condition pour liaison à pied
MERGE (a)-[:A_PIED{temps:round(distance/4000*3600)}] ->(b),
      (b)-[:A_PIED{temps:round(distance/4000*3600)}] ->(a)
WITH line , a.ligne AS ligne1,b.ligne AS ligne2
WHERE ligne1 = ligne2 // Condition pour liaison à metro
MERGE (a)-[:RELIE{temps : round(distance/40000*3600)}]->(b),
       (b)-[:RELIE {temps : round(distance/40000*3600)}] -> (a)      
