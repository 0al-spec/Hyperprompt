# All about Swift Package Manager Traits

Discover how traits act as feature flags, enabling conditional compilation, optional dependencies, and advanced package configurations.

Swift work like feature flags for Swift packages. They let developers conditionally compile code and toggle optional dependencies on or off. Consumers can enable specific traits, disable defaults, and check availability in code using the #if TraitName syntax. 📦

To see traits in action, let’s build a small library with optional features. For this example, we’ll create a simple FooLib package that defines two traits, Bar and Baz. Here’s what the manifest looks like:

```Swift
import PackageDescription

let package = Package(
    name: "foo-lib",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "FooLib",
            targets: ["FooLib"],
        ),
    ],
    
    traits: [
        
        .default(
            enabledTraits: [
                "Bar",   
            ]
        ),
        
        .init(
            name: "Bar",
            description: "A custom bar trait",
            enabledTraits: []
        ),
        
        .init(
            name: "Baz",
            description: "A custom baz trait",
            enabledTraits: [
                "Bar"
            ]
        ),
    ],
    targets: [
        .target(
            name: "FooLib",
        ),
        .testTarget(
            name: "FooLibTests",
            dependencies: [
                .target(name: "FooLib"),
            ]
        ),
    ]
)
```

With the traits defined, let’s look at the library code. Traits can be checked at compile time using the #if directive. Here’s a simple Foo struct exposed as a public API:

```Swift
public struct Foo {
    
    public init() {
    }
    

#if Bar
    public func bar() -> String {
    
    #if Baz
        return "bar and baz"
    #else
        return "bar"
    #endif
    }
#endif


#if Baz
    public func baz() -> String {
        return "baz"
    }
#endif
}
```

Swift lets you conditionally compile code based on enabled traits. Traits can wrap optional imports or regular code, allowing behavior to change with the configuration.

Avoid defining , since they can cause issues with package graph resolution. ⚠️

Next, let’s look at testing a library with package traits, using the new Swift framework:

```Swift
import Testing
@testable import FooLib

@Suite
struct FooLibTestSuite {

#if Bar
    @Test
    func bar() async throws {
        let foo = Foo()
        let result = foo.bar()
        #if Baz
        #expect(result == "bar and baz")
        #else
        #expect(result == "bar")
        #endif
    }
#endif

#if Baz
    @Test
    func baz() async throws {
        let foo = Foo()
        let result = foo.baz()
        #expect(result == "baz")
    }
#endif
}
```

Just like in the library, you can use conditional checks to see if a trait is enabled. When running tests, the default traits defined in the package manifest are automatically enabled:

```bash
swift test --parallel
```

To test the package with different traits, use the --traits flag to list them. You can also enable every trait with --enable-all-traits or turn off the default ones with --disable-default-traits:

```bash
swift test --parallel --traits Bar,Baz
```

```bash
swift test --parallel --traits Baz
```

```bash
swift test --parallel --enable-all-traits
```

```bash
swift test --disable-default-traits
```

If you look at the test output, you’ll notice that the bar and baz test functions only run when their corresponding traits are enabled. If the default traits are disabled, no tests will run.

The swift build command also supports these trait-related build flags. This is especially useful for unit testing in a CI environment. Covering all possible scenarios helps catch trait-related issues early. 🤖

Trait names are namespaced per package, which means multiple packages can define the same trait names. Here’s how to use a package with traits in a very basic Example application:

```Swift
import PackageDescription

let package = Package(
    name: "example",
    platforms: [
        .macOS(.v15),
    ],
    dependencies: [
        .package(
            path: "../foo-lib",
        ),
    ],
    targets: [
        .executableTarget(
            name: "Example",
            dependencies: [
                .product(name: "FooLib", package: "foo-lib"),
            ]
        ),
    ]
)
```

This is the usual manifest file you’ve already seen—nothing new, no trait-specific code. When you add a dependency without explicitly selecting traits, the default traits are enabled automatically.

In this example, the Bar trait is enabled by default in your application code, without the need for conditional checks—because it was defined as a default trait in the library’s manifest file. Here’s how to use the FooLib with the default traits enabled:

```Swift
import FooLib

@main
struct Entrypoint {

    static func main() {
        
        let foo = Foo()
        
        let bar = foo.bar()
        print("Bar trait is available", bar)
    }
}
```

This is pretty much the same as the following package dependency setup:

```Swift
.package(
    path: "../foo-lib",
    traits: [
        .defaults,
    ]
),
```

You can also override the defaults and enable specific traits as needed. For example, to enable Baz, you could write:

```Swift
.package(
    path: "../foo-lib",
    traits: [
        .init(name: "Baz"),
    ]
),
```

Please note that Xcode can sometimes behave unpredictably, and you may need to clean the build cache when changing enabled traits. Even in Xcode 26, previous configurations and builds are heavily cached. Hopefully Apple will address this soon, but since it’s not a trivial problem to fix, don’t get frustrated—just clear your cache and derived data folder if things don’t work as expected. 😅

Now, in your code you should also be able to use the baz function:

```Swift
import FooLib

@main
struct Entrypoint {

    static func main() {
        
        let foo = Foo()
        
        let bar = foo.bar()
        print("Bar trait is available", bar)

        let baz = foo.baz()
        print("Baz trait is available", baz)
    }
}
```

Traits go far beyond simple conditional compilation, and to see their real value we need to place them in a larger, more complex setup. So let’s raise the bar with a more advanced example—buckle up, we’re going deeper:

```Swift
import PackageDescription

let package = Package(
    name: "example",
    platforms: [
        .macOS(.v15),
    ],
    traits: [
        .default(enabledTraits: ["MyBasicExampleApp"]),
        
        .init(
            name: "MyBasicExampleApp",
            description: "Builds and runs a basic app",
            enabledTraits: []
        ),
        
        .init(
            name: "MyFullExampleApp",
            description: "Builds and runs a full example app",
            enabledTraits: [
                "MyBarFlag",
            ]
        ),
        
        .init(name: "MyBarFlag"),
        .init(name: "MyBazFlag"),
    ],
    dependencies: [
        .package(
            path: "../foo-lib",
            traits: [
                
                .init(
                    name: "Bar",
                    condition: .when(
                        traits: [
                            "MyBarFlag",
                        ]
                    )
                ),
                .init(
                    name: "Baz",
                    condition: .when(
                        traits: [
                            "MyBazFlag",
                        ]
                    )
                ),
            ]
        ),
    ],
    targets: [
        .executableTarget(
            name: "Example",
            dependencies: [
                
                .product(
                    name: "FooLib",
                    package: "foo-lib",
                    condition: .when(
                        platforms: [
                            .macOS
                        ],
                        traits: [
                            "MyFullExampleApp",
                        ]
                    )
                ),
            ]
        ),
        
    ]
)
```

As you can see, this setup is more advanced. You can only check local traits with #if conditions, so here we map FooLib’s Bar and Baz traits to local ones (MyBarFlag and MyBazFlag). This also demonstrates how you might build different versions of the app for macOS and Linux with different capabilities. That’s the idea behind the MyBasicExampleApp and MyFullExampleApp traits in this example. 🤔

Here’s how you can check these traits in the example application code:

```Swift
#if MyFullExampleApp
import FooLib
#endif

@main
struct Entrypoint {

    static func main() {
#if MyFullExampleApp
        print("Full app.")

        let foo = Foo()

        #if MyBarFlag
        let bar = foo.bar()
        print("Bar trait is available", bar)
        #endif

        #if MyBazFlag
        let baz = foo.baz()
        print("Baz trait is available", baz)
        #endif
#else
        print("Basic app only.")
#endif
    }
}
```

It’s also important to note that you can’t directly check traits from package dependencies. To conditionally compile your targets, you need to define corresponding “local” traits. For example, a #if Bar check isn’t available in the example package.

Now let’s run the application with different traits:

```bash
swift run
```

```bash
swift run --traits MyBasicExampleApp
```

```bash
swift run --disable-default-traits       
```

```bash
swift run --traits MyFullExampleApp 
```

```bash
swift run --traits MyFullExampleApp,MyBazFlag
```

With package traits, you can turn package features on or off depending on your needs. This is incredibly useful, and many projects already use this pattern to enable features conditionally. For example, the recently released package provides a wide range of traits you can take advantage of.

Don’t confuse package traits with . While the concept is similar, they serve very different purposes. ✅

In my opinion, traits are a powerful addition to the Swift package ecosystem. Other languages, like Rust, have long relied on feature flags, and Swift now has a unified way to achieve the same.

The main concern is that Xcode still lags behind—some Swift package features aren’t fully integrated. I especially miss the ability to toggle traits directly in the IDE, and the caching issue remains a serious problem for many developers. Hopefully this will change soon.
