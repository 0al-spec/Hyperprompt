# spec(_:)

## Symbol Metadata
- **Identifier:** doc://specificationcore.SpecificationCore/documentation/SpecificationCore/spec(_:)
- **Module:** SpecificationCore
- **Symbol Kind:** func
- **Role Heading:** Function
- **Catalog Identifier:** doc://specificationcore.SpecificationCore/documentation/SpecificationCore
- **Catalog Title:** SpecificationCore

## Summary
Creates a specification from a predicate function

## Discussion

### Parameters
- `predicate`: A function that takes a candidate and returns a Boolean

### Return Value

An AnySpecification wrapping the predicate

## Declarations
```swift
func spec<T>(_ predicate: @escaping (T) -> Bool) -> AnySpecification<T>
```
