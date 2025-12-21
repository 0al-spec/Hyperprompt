# ||(_:_:)

## Symbol Metadata
- **Identifier:** doc://specificationcore.SpecificationCore/documentation/SpecificationCore/__(_:_:)
- **Module:** SpecificationCore
- **Symbol Kind:** op
- **Role Heading:** Operator
- **Catalog Identifier:** doc://specificationcore.SpecificationCore/documentation/SpecificationCore
- **Catalog Title:** SpecificationCore

## Summary
Logical OR operator for specifications

## Discussion

### Parameters
- `left`: The left specification
- `right`: The right specification

### Return Value

A specification that is satisfied when either specification is satisfied

## Declarations
```swift
func || <Left, Right>(left: Left, right: Right) -> OrSpecification<Left, Right> where Left : Specification, Right : Specification, Left.T == Right.T
```
