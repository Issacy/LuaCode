### LuaCode
* [**BASE**] `attribute(startFunc)`  
Create an attribute to modity the running env, when an attribute be created and called, `startFunc` will be run with same args.  
    * [**ATTRIBUTE**] `relative(file)/import(relpath)`  
    Use `relative(file)` to create an env which records full path and dir of the file, then can use `import(relpath)` to require file in relative path.  
    * [**ATTRIBUTE**] `namespace(base).XXX(func)/usingNamespace(base).XXX()`
        * Use `namespace(base).XXX(func)` to create a XXX namespace table in last namespace or `base` or `_G`, then run the `func` which new global variables in `func` env will be insert into XXX namespace, can index multiple namespaces once. (e.g.: `namespace().A.B.C(func)`)  
        * Use `usingNamespace(base).XXX()`to create an env, which will redirect global variable searching from `_G` to XXX namespace in last namespace or `base` or `_G`, this also can index multiple namespaces once.  
    * [**ATTRIBUTE**] `class().XXX([BaseClass], defineFunc)`  
    Create a C++-like class name XXX extends `BaseClass`, which has class member access, static/non-static, and has `super` and `cls` in non-static function env, and `cls` in static function env.  
    _IN-PLAN: support implement or multi-extends_  
        * [**ATTRIBUTE**] `public()/protected()/private()`  
        Change defines to certain access scope.  
        * [**ATTRIBUTE**] `static()`  
        Change next define to static, and change back when done.  
