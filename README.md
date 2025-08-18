# IALAB
This repository contains projects on logic-based problem solving using Prolog and Answer Set Programming (Clingo). It includes implementations of search algorithms and constraint-based scheduling solutions applied to different domains such as pathfinding and timetabling.

### Funzionamento ida star
```
ida_star(Sol, Costo)
    ↓
ida_loop([[Iniziale]], H0, Sol, Costo)
    ↓
bounded_search([...], Threshold, Result, NewThreshold)
    ↓
   ↳ se trovata → Result = found(Sol, Costo)
   ↳ se no → ida_loop(..., NewThreshold, ...)
```
Moves set to resolve puzzle: Move tile 2 from position 4 to position 7 (empty)
- Move tile 4 from position 7 to position 8 
- Move tile 6 from position 8 to position 5 
- Move tile 2 from position 5 to position 4 
- Move tile 3 from position 4 to position 1 
- Move tile 1 from position 1 to position 2 
- Move tile 2 from position 2 to position 5 
- Move tile 3 from position 5 to position 4 
- Move tile 5 from position 4 to position 3 
- Move tile 7 from position 3 to position 0 
- Move tile 1 from position 0 to position 1 
- Move tile 2 from position 1 to position 2 
- Move tile 3 from position 2 to position 5 
- Move tile 5 from position 5 to position 4 
- Move tile 4 from position 4 to position 7 
- Move tile 8 from position 7 to position 6 
- Move tile 7 from position 6 to position 3 
- Move tile 4 from position 3 to position 4 
- Move tile 5 from position 4 to position 5 
- Move tile 6 from position 5 to position 8 

 Total moves: 20 

**SolutionPath =**
- [[7,3,1,5,e,6,8,2,4],
- [7,3,1,5,2,6,8,e,4],
- [7,3,1,5,2,6,8,4,e],
- [7,3,1,5,2,e,8,4,6],
- [7,3,1,5,e,2,8,4,6],
- [7,e,1,5,3,2,8,4,6],
- [7,1,e,5,3,2,8,4,6],
- [7,1,2,5,3,e,8,4,6],
- [7,1,2,5,e,3,8,4,6],
- [7,1,2,e,5,3,8,4,6],
- [e,1,2,7,5,3,8,4,6],
- [1,e,2,7,5,3,8,4,6],
- [1,2,e,7,5,3,8,4,6],
- [1,2,3,7,5,e,8,4,6],
- [1,2,3,7,e,5,8,4,6],
- [1,2,3,7,4,5,8,e,6],
- [1,2,3,7,4,5,e,8,6],
- [1,2,3,e,4,5,7,8,6],
- [1,2,3,4,e,5,7,8,6],
- [1,2,3,4,5,e,7,8,6],
- [1,2,3,4,5,6,7,8,e]]
  
**Cost = 20**