---
name: create-apex-test-class
description: "Workflow for creating or improving Salesforce Apex test classes in a Salesforce DX project. Use when asked to add @isTest coverage, create controller or trigger tests, improve deployment coverage, reuse shared test-data helpers, or validate bulk, security, callout, and async behavior."
---

# Create Apex Test Class

Use this skill to build high-signal Apex tests that match the local patterns already present in the target Salesforce DX project.

## When to Use This Skill

- A user asks to create a new Apex test class.
- A user asks to improve coverage for a class, trigger, batch, queueable, or controller.
- A deployment fails because Apex coverage is too low.
- A change adds new business logic and needs focused assertions, mocks, or bulk-path coverage.

## Project Signals to Reuse

- Check for a neighboring test class before inventing a new pattern.
- Reuse an existing shared test-data helper when the project already has one.
- Follow nearby naming conventions. Prefer the dominant local style around the target class instead of introducing a new naming pattern.

## Step-by-Step Workflow

1. Inspect the production class, related metadata, and any existing tests for the same feature area.
2. Choose the test class name based on the closest local pattern instead of introducing a third naming style.
3. Create only the test data needed for the behavior under test. Use `@TestSetup` when multiple methods share the same baseline data.
4. Wrap the action under test in `Test.startTest()` and `Test.stopTest()` when the code uses async work, limits-sensitive logic, or callouts.
5. Assert business outcomes, not just execution. Verify returned records, field values, side effects, and collection sizes.
6. Cover realistic edge cases:
   - empty input or no matching data
   - bulk input for trigger or service logic
   - permission or security-sensitive queries
   - error paths, especially around callouts or validation
7. If the code performs callouts, use the appropriate `HttpCalloutMock` or platform mock pattern instead of relying on live endpoints.

## Gotchas

- **Do not rely on org data** unless the requirement explicitly forces `SeeAllData=true`.
- **Do not stop at happy-path coverage** for triggers, queueables, or record transformers; add assertions for bulk behavior and final state.
- **Do not assert only `System.assert(true)`-style conditions**. Every test should prove a meaningful outcome.
- **Do not duplicate factory logic** if a nearby helper or shared test-data factory already creates the needed records.

## Quick Checklist

- [ ] Test class name matches the local convention near the target class.
- [ ] Test data is isolated and deterministic.
- [ ] `Test.startTest()` and `Test.stopTest()` are used where they add value.
- [ ] Assertions verify behavior, not just coverage.
- [ ] Async, bulk, callout, and empty-result paths are covered when relevant.

## References

- Nearby test classes in the target project
- Existing shared test-data helpers or factory utilities
