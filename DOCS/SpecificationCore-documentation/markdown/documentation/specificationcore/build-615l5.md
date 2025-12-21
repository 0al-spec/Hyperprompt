# build(_:)

## Symbol Metadata
- **Identifier:** doc://specificationcore.SpecificationCore/documentation/SpecificationCore/build(_:)-615l5
- **Module:** SpecificationCore
- **Symbol Kind:** func
- **Role Heading:** Function
- **Catalog Identifier:** doc://specificationcore.SpecificationCore/documentation/SpecificationCore
- **Catalog Title:** SpecificationCore

## Summary
Creates a specification builder starting with the given specification

## Discussion

### Parameters
- `specification`: The initial specification

### Return Value

A SpecificationBuilder for fluent composition

## Declarations
```swift
func build<S>(_ specification: S) -> SpecificationBuilder<S.T> where S : Specification
```
