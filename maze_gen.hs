--- IMPORTS ---
import Debug.Trace
import System.IO



--- DATA STRUCTURES AND TYPE SYNONYMS ---

-- represents an (x,y) location in the graph indexed from 0
-- top left = (0,0), top right = (0,n-1), bottom left (m,0), bottom right (m-1,n-1)
data Node = Node {x,y :: Int} deriving (Eq, Ord, Show)

-- edge has two nodes
data Edge = Edge {node1, node2 :: Node} deriving (Show)

-- implements equality which ignores direction of the edge (we're considering undirected graph)
instance Eq Edge where
    e1 == e2 = (node1 e1 == node1 e2) && (node2 e1 == node2 e2) || (node1 e1 == node2 e2) && (node2 e1 == node1 e2)

-- the graph represents a graph where all (i,j) with 0 <= i < m, 0 <= j < n are all considered nodes implicitly, this means we just need to remember size and edges
data Graph = Graph {m,n :: Int, edges :: [Edge]} deriving Eq

-- used inside the maze generating function
--                 (current_graph,visited_nodes)
type SearchState = (Graph,[Node])






--- MAZE GENERATION ---

-- start the actual bfs starting with empty graph with given dimension and initial stack
--      m   -> n   -> rel_crossings -> rel_paths -> result_graph 
maze :: Int -> Int -> Int -> Int ->  Graph
maze m n prob_dfs prob_mpaths = addExits $ fst $ fst $ mazeSearch (emptyGraph m n, []) [(startingNode,startingNode)] prob_dfs prob_mpaths random
    where 
        -- set starting node to top left corner
        startingNode = toNode (0,0)
        -- in case I want to start tearing down the walls from middle of maze, use following startingNode: startingNode = toNode (m `div` 2, n `div` 2)

-- checks if a given node is not out of bounds for the given graph
isValidNode :: Node -> Graph -> Bool
isValidNode (Node x y) graph = x >= 0 && x <= (m graph - 1) && y >= 0 && y <= (n graph - 1)

-- returns all neighboring valid nodes for the given node in the given graph
-- used for bfs and dfs
neighbors :: Node -> Graph -> [Node]
neighbors (Node x y) graph = [Node (x + fst offset) (y + snd offset) | offset <- [(1,0),(-1,0),(0,-1),(0,1)], isValidNode (Node (x + fst offset) (y + snd offset)) graph]

-- adds an edge {x,y} to the current graph
--          init_graph -> x -> y -> graph_with_x_y_edge
addEdge :: Graph -> Node -> Node -> Graph
addEdge graph x y = Graph {m = m graph, n = n graph, edges = (Edge { node1 = x, node2 = y}):edges graph}


-- mazeSearch is the main algorithm of this program and performs the random dfs/bfs that generates the maze

-- prob_mpaths parameter is the probability, that after seeing an already visited node, we will create a new path by tearing down the wall between the prev cell and current cell
-- rel_crossings prob parameter just determines, the ratio between putting neighbor nodes at start or end of queue (the ratio between acting like a dfs or bfs)

-- edges_to_search_queue has the format: [(old_node_from_queue,new_node_from_queue)]

--     (init_graph,init_visited) -> edges_to_search_queue -> rel_crossings -> rel_paths -> random -> ((new_graph, new_visited),random)
mazeSearch :: SearchState -> [(Node,Node)] -> Int ->  Int -> Random -> (SearchState,Random)
mazeSearch ss [] prob_dfs prob_mpaths rand = (ss,rand)
mazeSearch (graph,visited) ((prev,cur):queue) prob_bfs prob_mpaths inRand = 
    if cur `elem` visited 
        then mazeSearch (probAddedGraph,visited) queue prob_bfs prob_mpaths thenOutRand 
            -- if the current node was visited, we maybe want to add an edge (based on rel_paths)
    else 
        -- trace (show graph) (mazeSearch (addEdge graph prev cur,cur:visited) ([(cur,next) | next <- left] ++ queue ++ [(cur,next) | next <- right] ) prob_bfs prob_mpaths newRand)
        mazeSearch (addEdge graph prev cur,cur:visited) ([(cur,next) | next <- left] ++ queue ++ [(cur,next) | next <- right] ) prob_bfs prob_mpaths elseOutRand
            -- if the current node was not visited, we do: 
            --  1. add current node to visited 
            --  2. add edge from the previous node to current node to the graph
            --  4. shuffle the neighbors of the current node (especially needed when always putting neighbors to just left or right)
            --  3. we generate lists "left" and "right" that correspond to neighbors that should go at start or end of the queue
            --      (the neighbors in left list get chosen before the neighbors in the right list)
            
    where 
        -- then clause
        (probAddedGraph,thenOutRand) = addEdgeMaybe graph prev cur prob_mpaths inRand
        -- else clause
        (shuffledNeighbors,elseRand2) = shuffle (neighbors cur graph) inRand
        ((left,right),elseOutRand) = splitRand shuffledNeighbors prob_bfs elseRand2







--- STRUCTURES HELPER FUNCTIONS ---

-- converts a coordinate tuple into a node
-- uses record syntax to construct a node value
toNode :: (Int,Int) -> Node
toNode (x,y) = Node {x = x, y = y}

-- converts a tuple of coordinate tuples to edge
toEdge :: ((Int,Int),(Int,Int)) -> Edge
toEdge (n1,n2) =
    let
        node1 = toNode n1
        node2 = toNode n2
    in
        Edge {node1 = node1, node2 = node2}

-- generates an empty graph representing a maze with no walls torn down, the maze will 
-- be generated by tearing down walls until there is no more walls to be deleted
--          height -> width -> result_graph
emptyGraph :: Int -> Int -> Graph
emptyGraph m n = Graph { m = m, n = n, edges = [] } 

-- adds edge representing the exit from the maze (bottom right)
-- works by just adding a corresponding edge to the graph
addExitEdge :: Graph -> Graph
addExitEdge graph = Graph {m = m graph, n = n graph, edges = Edge {node1 = toNode (m graph - 1,n graph - 1), node2 = toNode (m graph ,n graph - 1) } : edges graph }

-- adds edge representing entrance to the maze (top left)
-- works by just adding a corresponding edge to the graph
addEntranceEdge :: Graph -> Graph
addEntranceEdge graph = Graph {m = m graph, n = n graph, edges = Edge {node1 = toNode (- 1, 0), node2 = toNode (0,0) } : edges graph}

-- adds both the exit and the entrance by using function composition
addExits :: Graph -> Graph 
addExits = addExitEdge . addEntranceEdge






--- SHOWING --- 

-- constant representing wall string
wall :: String
wall = "# "

-- constant representing no wall string
blank :: String
blank = "  "


-- !THE INDICES OF THE ALGORITHM/INNER GRAPH REPRESENTATION ARE DIFFERENT THAN THE TEXT REPRESENTATION OF THE MAZE!
-- graph representation has n rows => text representation has 2n + 1 rows

-- returns text representation for single algorithm/inner graph row (so returns two rows of text)
-- a single row in this context means all the vertices in row i and their corresponding edges
-- but also the edges between vertices at rows i and i + 1
--        graph  -> graph_repr_index -> two_corresponding_rows_of_text_repr
showRow :: Graph -> Int -> String
showRow graph i =
    wall ++ concat [showPosRight graph i y | y <- [0 .. (n graph - 1)]] -- odd row of text representation
    ++ "\n" ++
    wall ++ concat [showPosDown graph i y | y <- [0 .. (n graph - 1)]] -- even row of text representation
    ++ "\n"


-- showPosRight is used to print rows with odd indices (text maze representation, starting with top wall with index 0)

-- given x,y positions of a node prints:
-- 1. a blank for this node (nodes are always represented by blank) 
-- 2.
--  a) wall if there is no edge going right
--  b) blank between nodes (x,y) and (x,y+1) if there is an edge
showPosRight :: Graph -> Int -> Int -> String
showPosRight graph x y =
    if toEdge ((x,y),(x,y+1)) `elem` edges graph
        then blank ++ blank -- there is edge (path)
    else blank ++ wall

-- showPosDown is used to print rows with even indices (starting with top wall with index 0) (rows with even indices have at even columns cells, that are always walls)

-- given x,y positions prints:
-- 1. 
--  a) edge between (x,y) and (x+1,y) and if there is one
--  b) wall if no edge
-- 2. a wall symbol
showPosDown :: Graph -> Int -> Int -> String
showPosDown graph x y =
    if toEdge ((x,y),(x+1,y)) `elem` edges graph
        then blank ++ wall -- there is edge (path)
    else wall ++ wall

-- concatenates strings for all rows of graph representation (that means we concatenate pairs of rows) and then drops the first row (drops until newline)
-- the first row of inner graph representation is -1 which is used for displaying maze entrance, we won't only the second part of its text representation => we drop first row
showGraph :: Graph -> String
showGraph graph = dropWhile (/= '\n') $ concat $ [showRow graph i | i <- [-1..(m graph - 1)]]

-- make graph data type implement my custom show
instance Show Graph where
    show = showGraph






-- RANDOM NUMBERS 

-- iterate f start -- creates infinite list starting from start and applying the f function to the result over again

-- START borrowed code from Recodex, author: Tomas Dvorak

type Random = [Int] -- typové synonymum

-- constant representing seed for random
seed :: Int
seed = 123456789

-- nekonecny seznam pseudonahodnych cisel z intervalu 0 .. 2^31-1
random :: Random
random = iterate f seed
  where f x = (1103515245 * x + 12345) `mod` (2 ^ 31)

-- pro zadaný rozsah (dolni, horni) a pseudonahodny generator 
-- vrati pseudonahodne cislo v intervalu dolni..horni 
-- a novou verzi generatoru  
randomR :: (Int, Int) -> Random -> (Int, Random)
randomR (dolni, horni) (r : rand) =
    (dolni + r * (horni - dolni + 1) `div` (2 ^ 31), rand)

-- END of borrowed code

-- splits the given list in two random groups based on given probability
-- prob is the percent probability that any element will end up in left list
--          list   -> prob_right_list -> start_random -> ((list1, list2), end_random)
splitRand :: [a] -> Int -> Random -> (([a],[a]),Random)
splitRand [] prob rand = (([],[]),rand)
splitRand (x:list) prob_right_list inRand = if choice <= prob_right_list then ((next1,x:next2),outRand)
    else ((x:next1,next2),outRand)
    where 
        (choice,rand2) = randomR (0,100) inRand -- get random num between (0,100) and updated random sequence
        ((next1,next2),outRand) = splitRand list prob_right_list rand2 -- recursively get left list and right list after split using updated random sequence

-- shuffles the given list using the given random sequence and returns the shuffled list and the new random seq
--       [list] -> init_rand_seq -> (shuffled_list, fin_rand_seq)
shuffle :: [a] -> Random -> ([a],Random)
shuffle [] rand = ([],rand)
shuffle list inRand = (x:nextList,outRand)  -- x is the picked element to add to start
    where
        (randPos,rand2) = randomR (0,length list - 1) inRand  
        (left,x:right) = splitAt randPos list   -- pick the x element (x is the first element of right list after random split)
        (nextList,outRand) = shuffle (left ++ right) rand2

-- adds edge to the graph only sometimes, the probability in percent is given as fourth parameter
--              graph -> node1 -> node2 -> prob_add_edge -> random_seq -> (new_graph,new_random_seq)
addEdgeMaybe :: Graph -> Node -> Node -> Int -> Random -> (Graph,Random)
addEdgeMaybe graph x y prob_mpaths rand = 
    if n < prob_mpaths 
        then (addEdge graph x y, newRand)
    else (graph,newRand)
    where (n,newRand) = randomR (0,100) rand

-- (for test use) doesn't shuffle the array but has the same interface as shuffle
noShuffle :: [a] -> Random -> ([a],Random)
noShuffle list inRand = (list,inRand)





--- MAIN ---
main = do
    putStr "Enter maze height: "
    hFlush stdout
    heightStr <- getLine
    putStr "Enter maze width: "
    hFlush stdout
    widthStr <- getLine
    putStr "Enter relative crossing amount (0,100): "
    hFlush stdout
    relCrossStr <- getLine
    putStr "Enter relative paths amount (0,100): "
    hFlush stdout
    relPathsStr <- getLine
    let height = (read heightStr :: Int)
        width = (read widthStr :: Int)
        relCross = (read relCrossStr :: Int)
        relPaths = (read relPathsStr :: Int)
    print (maze height width relCross relPaths)



-- SAMPLE METHOD TESTS

-- splitRand
--  fst $ splitRand [0 .. 9] 50 (drop 0 random)

-- shuffle
-- fst $ shuffle [0 .. 9] (drop 0 random)

-- following was used to find bug in splitRand when having prob_right to 100
-- take 100 ( iterate ( \ x -> trace (show $ fst $ splitRand [0 .. 9] 100 (drop x random)) (x+100) ) 0 )