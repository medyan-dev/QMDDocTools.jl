
"""
Module doc string
"""
module ExamplePkg

export 🧇
export 🧇foo
export foo🧇

greet() = print("Hello World!")

"""
This function name is an emoji
"""
🧇() = print("Hello")

"""
This function name has an emoji at the start
"""
🧇foo() = print("Hello")

"""
This function name has an emoji at the end
"""
foo🧇() = print("Hello")

end # module
