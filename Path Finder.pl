% Defines delivery personnel with their ID, capacity, working hours, current object, and location.
deliveryPersonel(dp1, 10, [8, 16], obj6, 3).
deliveryPersonel(dp2, 15, [9, 17], obj7, 4).
deliveryPersonel(dp3, 20, [10, 18], none, 1).
deliveryPersonel(dp4, 12, [11, 19], none, 5).
deliveryPersonel(dp5, 18, [8, 17], none, 2).

% Defines objects with their ID, weight, pickup and dropoff locations, priority, and assigned delivery personnel.
object(obj1, 2, 4, 1, low, none).
object(obj2, 3, 3, 6, high, dp1).
object(obj3, 4, 1, 2, low, none).

% Defines places with their numeric ID and name.
place(1, adminOffice).
place(2, cafeteria).
place(3, engineeringBld).
place(4, library).
place(5, socialSciencesBld).
place(6, lectureHallA).
place(7, instituteX).
place(8, instituteY).

% Defines routes between places with their start and end points, and weight (distance/time).
route(1, 2, 4).
route(2, 1, 4).
route(1, 4, 1).
route(4, 1, 1).
route(1, 3, 3).
route(3, 1, 3).
route(2, 5, 2).
route(5, 2, 2).
route(2, 4, 5).
route(4, 2, 5).
route(5, 4, 2).
route(4, 5, 2).
route(5, 7, 8).
route(7, 5, 8).
route(4, 8, 3).
route(8, 4, 3).
route(3, 6, 2).
route(6, 3, 2).
route(6, 8, 3).
route(8, 6, 3).


% Predicate to check if a given time is within working hours.
workingHours(Time) :-
    Time >= 9,
    Time =< 18.

% Finds a path between two places, calculating the total weight (distance/time).
find_path(Start, End, Path, TotalWeight) :-
    dfs(Start, End, [Start], 0, RevPath, TotalWeight),
    reverse(RevPath, Path).

% Depth-first search to find a path between two points, accumulating the total weight.
dfs(Start, End, Visited, WeightSoFar, [End|Visited], TotalWeight) :-
    route(Start, End, Weight),
    TotalWeight is WeightSoFar + Weight,
    !.
dfs(Start, End, Visited, WeightSoFar, Path, TotalWeight) :-
    route(Start, Next, Weight),
    Next \== End,
    \+member(Next, Visited),
    NewWeight is WeightSoFar + Weight, % Update the weight
    dfs(Next, End, [Next|Visited], NewWeight, Path, TotalWeight),
    !.
    
% Gets paths for pickup and dropoff, including the total time for both.
getPaths(Location, Pickup, TimeToPickup, Dropoff, TimeToDropoff, TotalTime, PickupPath, DropfoffPath) :-
    find_path(Location, Pickup, PickupPath, TimeToPickup),
    find_path(Pickup, Dropoff, DropfoffPath, TimeToDropoff),
    TotalTime is TimeToPickup + TimeToDropoff.


% Checks if a personnel is working at a given shipping time.
isPersonnelWorking(ShippingTime, WorkStart, WorkEnd) :-
    ShippingTime >= WorkStart,
    ShippingTime < WorkEnd.


% Checks if an object's weight can be carried by a personnel's capacity.
isCarriable(Weight, Capacity) :-
    Weight =< Capacity.


% Checks if a delivery can be completed before the personnel's work ends.
isReachable(WorkEnd, ShippingTime, TotalTime) :-
    EndTime is ShippingTime + TotalTime,
    EndTime =< WorkEnd.


%it prints available personnels to the screen
printAvailablePersonnels(ObjectID, ShippingTime) :-
    delivery(ObjectID, _, _, _, ShippingTime),
    format('').


% Finds available personnel for a given object and shipping time.
findAvailablePersonnel(ObjectID, DPID, TotalTime, PickupPath, DropfoffPath, ShippingTime) :-
    object(ObjectID, Weight, Pickup, Dropoff, _, none),
    deliveryPersonel(DPID, Capacity, [WorkStart, WorkEnd], none, Location),
    workingHours(ShippingTime),
    isPersonnelWorking(ShippingTime, WorkStart, WorkEnd),
    isCarriable(Weight, Capacity),
    getPaths(Location, Pickup, _, Dropoff, _, TotalTime, PickupPath, DropfoffPath),
    isReachable(WorkEnd, ShippingTime, TotalTime),
    format('~w can deliver ~w in ~w hours and route is [', [DPID, ObjectID, TotalTime]),
    printPlaceNames(PickupPath),
    format(' (pickup location) -> '),
    printPlaceNamesExceptFirst(DropfoffPath),
    format(']~n').

% Determines the delivery status of an object.
delivery(ObjectID, Status, PickupPath, DropfoffPath, ShippingTime) :-
    object(ObjectID, _, _, _, _, DeliveryPersonID),
    (   DeliveryPersonID \= none ->  Status = carryingBy(DeliveryPersonID),
    format('~w is currently carrying ~w',  [DeliveryPersonID, ObjectID])
    ;   findall((DPID, TotalTime),
                findAvailablePersonnel(ObjectID, DPID, TotalTime, PickupPath, DropfoffPath, ShippingTime),
                DeliveryStatus),
        (   DeliveryStatus = [] -> Status = no_available_delivery_personnel,
            format('there is no available delivery personnel')
        ;   Status = available(DeliveryStatus)
        )
    ),
    !.
    
% Handles cases where the object does not exist.
delivery(ObjectID, 'There is no Object', _, _, _) :- format('there is no object named ~w', ObjectID).


% Helper predicates for printing place names.
printPlaceNamesExceptFirst([]).
printPlaceNamesExceptFirst([_|Rest]) :-
    printPlaceNames(Rest).
    
transformPlaces([], []).
transformPlaces([Num|NumTail], [Name|NameTail]) :-
    place(Num, Name),
    transformPlaces(NumTail, NameTail).


printPlaceNames(NumberList) :-
    transformPlaces(NumberList, NameList),
    atomic_list_concat(NameList, ' -> ', NamesString),
    write(NamesString).



