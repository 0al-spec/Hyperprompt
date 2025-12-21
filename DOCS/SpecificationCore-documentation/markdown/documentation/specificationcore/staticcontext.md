# staticContext(_:)

## Symbol Metadata
- **Identifier:** doc://specificationcore.SpecificationCore/documentation/SpecificationCore/staticContext(_:)
- **Module:** SpecificationCore
- **Symbol Kind:** func
- **Role Heading:** Function
- **Catalog Identifier:** doc://specificationcore.SpecificationCore/documentation/SpecificationCore
- **Catalog Title:** SpecificationCore

## Summary
Creates a static context provider

## Discussion

### Parameters
- `context`: The static context to provide

### Return Value

A StaticContextProvider with the given context

## Declarations
```swift
func staticContext<Context>(_ context: Context) -> StaticContextProvider<Context>
```
