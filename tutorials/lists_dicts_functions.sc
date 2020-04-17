// ----------------------------------------------------------
// lists
// -------------------------------------------------------
(
x = List[1, 2, 3];
x.array.add("foo");
x.postln;
x.clipAt(2).postln;
x.postln;
)
// https://funprogramming.org/ -  has a few sc videos
// https://funprogramming.org/134-Variable-names-and-types-in-SuperCollider.html
// ----------------------------------------------------------
// dictionary
// -------------------------------------------------------
// single letter variables are globally declared

e = ('name':'bla', 'age':22) // dictionary (keys are strings)
e.age // 22
e.height=200 // ( 'name': bla, 'age': 22, 'height': 200 )

// longer names can be decared globally with a preceding~
~superc = "sc";
~superc.postln

// longer names can be decared in scope
(
var processng; // note semicolon
processng = 33;
processng
)

// ----------------------------------------------------------
// functions
// https://funprogramming.org/136-Functions-in-SuperCollider-and-Processing.html
// ----------------------------------------------------------
// functions are objects
f = {arg n, v = 20; ( "something: n:"+n+" v: "+v).postln;} // stores function in a variable (f)

// prints 4x as the return value from the block is printed
(
f.value(1,1);
f.value(3);
f.value(5,3);
)

g = {arg one, two; one+two;} // stores function in a variable (g)

(
g.value(1,1).postln;
g.value(3, 5).postln;
g.value(5,7);
)



// ----------------------------------------------------------
// switch
// http://danielnouri.org/docs/SuperColliderHelp/Language/Control-Structures.html
// ----------------------------------------------------------
(
var x, z;
z = [33,31,30,22, 45];
f = {arg n, v = 20; ( "something: n:"+n+" v: "+v).postln;};
x = switch (z.choose)
	{33}   {  f.value(33,20) }
	{31}   {  f.value(31,20) }
	{30}   {  f.value(30,20) }
	{22}   {  f.value(22,20) }
	{45}   {  f.value(45,20) }
;
x.postln;
)