# Next Task: Integration-2 — Resolver with Specifications

**Priority:** P1
**Phase:** Phase 7 - Lexer & Resolver Integration with Specs
**Effort:** 6 hours
**Dependencies:** Phase 4 (Resolver) ✅, Phase 3 (Specs) ✅
**Status:** Selected

## Description

Refactor the imperative ReferenceResolver to use declarative specifications from Phase 3 for path validation and classification. Replace imperative path validation with ValidReferencePathSpec, NoTraversalSpec, and IsAllowedExtensionSpec. Use PathTypeDecision for path classification (allowed/forbidden/invalid).

## Next Step

Run PLAN command to generate detailed PRD:
$ claude "Выполни команду PLAN"
