# contextProvider(_:)

## Symbol Metadata
- **Identifier:** doc://specificationcore.SpecificationCore/documentation/SpecificationCore/contextProvider(_:)
- **Module:** SpecificationCore
- **Symbol Kind:** func
- **Role Heading:** Function
- **Catalog Identifier:** doc://specificationcore.SpecificationCore/documentation/SpecificationCore
- **Catalog Title:** SpecificationCore

## Summary
Creates a context provider from a closure

## Discussion

### Parameters
- `factory`: The closure that will provide the context

### Return Value

A GenericContextProvider wrapping the closure

## Declarations
```swift
func contextProvider<Context>(_ factory: @escaping () -> Context) -> GenericContextProvider<Context>
```
