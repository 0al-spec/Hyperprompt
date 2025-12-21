# build(_:)

## Symbol Metadata
- **Identifier:** doc://specificationcore.SpecificationCore/documentation/SpecificationCore/build(_:)-oii4
- **Module:** SpecificationCore
- **Symbol Kind:** func
- **Role Heading:** Function
- **Catalog Identifier:** doc://specificationcore.SpecificationCore/documentation/SpecificationCore
- **Catalog Title:** SpecificationCore

## Summary
Creates a specification builder starting with a predicate

## Discussion

### Parameters
- `predicate`: The initial predicate function

### Return Value

A SpecificationBuilder for fluent composition

## Declarations
```swift
func build<T>(_ predicate: @escaping (T) -> Bool) -> SpecificationBuilder<T>
```
