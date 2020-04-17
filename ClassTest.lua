require "Base.namespace"
require "Base.class"
require "Base.global"

local function printc(msg1, ...)
    local msg = {msg1}
    for i = 1, select("#", ...) do
        table.insert(msg, tostring(select(i, ...)))
    end
    print(table.concat(msg))
end

namespace().Test(function()
    namespace().inTest(function()
        class().TestClass(function()
            public()
                static() publicStaticVal = "s1"
                static() function staticPublicFunc()
                    printc("TestClass.staticPublicFunc->cls.publicStaticVal=", cls.publicStaticVal)
                    cls.staticProtectedFunc()
                end

                function TestClass(self) -- constructor
                    printc("TestClass:TestClass")
                    self.publicVal = 1
                    self.protectedVal = "a"
                    self.privateVal = false
                    self:publicFunc()
                end
                function publicFunc(self)
                    printc("TestClass:publicFunc->self.publicVal=", self.publicVal)
                    self:protectedFunc()
                end
                publicVal = nil

            protected()
                static() protectedStaticVal = "sa"
                static() function staticProtectedFunc()
                    printc("TestClass.staticProtectedFunc->cls.protectedStaticVal=", cls.protectedStaticVal)
                    cls.staticPrivateFunc()
                end
                
                function protectedFunc(self)
                    printc("TestClass:protectedFunc->self.protectedVal=", self.protectedVal)
                    self:privateFunc()
                end
                protectedVal = nil

            private()
                static() privateStaticVal = "sfalse"
                static() function staticPrivateFunc()
                    printc("TestClass.staticPrivateFunc->cls.privateStaticVal=", cls.privateStaticVal)
                end
                function privateFunc(self)
                    printc("TestClass:privateFunc->self.privateVal=", self.privateVal)
                end
                privateVal = nil
        end)

        class().TestExtendClass(TestClass, function()
            public()
                function TestExtendClass(self) -- constructor
                    super.TestClass(self)
                    printc("TestExtendClass:TestExtendClass")
                    self.protectedVal = "b"
                    self.privateVal = true
                    self.publicVal = 2
                    self:publicFunc()
                end
                function publicFunc(self)
                    super.publicFunc(self)
                    printc("TestExtendClass:publicFunc")
                end
                static() function staticExtendPublicFunc()
                    printc("TestExtendClass.staticExtendPublicFunc->cls.protectedStaticVal=", cls.protectedStaticVal)
                    cls.protectedStaticVal = "sb"
                    printc("TestExtendClass.staticExtendPublicFunc->cls.protectedStaticVal=", cls.protectedStaticVal)
                    printc("TestExtendClass.staticExtendPublicFunc->TestClass.protectedStaticVal=", TestClass.protectedStaticVal)
                    TestClass.protectedStaticVal = "sb"
                    printc("TestExtendClass.staticExtendPublicFunc->TestClass.protectedStaticVal=", TestClass.protectedStaticVal)
                    printc("TestExtendClass.staticExtendPublicFunc->cls.privateStaticVal=", cls.privateStaticVal)
                    cls.privateStaticVal = "strue"
                    printc("TestExtendClass.staticExtendPublicFunc->cls.privateStaticVal=", cls.privateStaticVal)
                    printc("TestExtendClass.staticExtendPublicFunc->TestClass.privateStaticVal=", TestClass.privateStaticVal)
                    TestClass.privateStaticVal = "strue"
                    printc("TestExtendClass.staticExtendPublicFunc->TestClass.privateStaticVal=", TestClass.privateStaticVal)
                    TestClass.staticPublicFunc()
                end
        end)
    end)
end)
-- TestClass.staticPublicFunc() -- no TestClass in global
-- Test.TestClass.staticPublicFunc() -- no TestClass in Test
-- inTest.TestClass.staticPublicFunc() -- no inTest in global
-- local TestClass = Test.inTest.TestClass
usingNamespace().Test.inTest()
TestClass.staticPublicFunc()
printc("TestClass.privateStaticVal=", TestClass.privateStaticVal)
TestExtendClass.staticExtendPublicFunc()
printc("TestClass.privateStaticVal=", TestClass.privateStaticVal)
local oe = Test.inTest.TestExtendClass()
oe:publicFunc()
