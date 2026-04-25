---
description: "Repository-specific guidance for Salesforce Visualforce pages and components."
applyTo: "**/*.page, **/*.component"
---

# Salesforce Visualforce

Use these rules when editing Visualforce pages or components in a Salesforce DX project.

## Core Rules

- Keep business logic in Apex controllers, extensions, or services. Visualforce markup should focus on rendering and binding.
- Pair new page behavior with Apex controller test updates. Do not add Visualforce-only behavior without validating the controller path that drives it.
- Escape rendered output by default. Use `escape="false"` only for trusted, already-sanitized content and make that choice explicit in the related Apex code.
- Prefer standard Visualforce feedback components such as `apex:pageMessages` or `apex:pageMessage` for user-visible errors and warnings.
- Keep bindings explicit and predictable. Avoid repeated getter chains that can trigger extra queries or expensive recomputation during a single page render.

## PDF and Print Rendering

- When using `renderAs="pdf"`, keep styling print-focused and self-contained.
- Do not depend on JavaScript for required PDF output behavior.
- Keep PDF pages deterministic: controllers should provide all final data before render time.

## Page and Controller Boundaries

- Put SOQL, DML, callouts, and branching logic in Apex, not inline in the page.
- If a page needs formatted or transformed data, expose that through a controller property or wrapper instead of composing it in markup.
- Reuse an existing controller or helper when the feature already has one nearby.

## Security

- Treat URL parameters and merged values as untrusted input until validated in Apex.
- Do not expose fields in Visualforce unless the controller path already enforces the correct access rules.
- Prefer controller methods that already use sharing and field-security-aware queries.

## Good Pattern

```xml
<apex:page controller="InvoiceController">
    <apex:pageMessages />
    <apex:pageBlock title="Invoice">
        <apex:outputText value="{!invoiceNumber}" />
    </apex:pageBlock>
</apex:page>
```

## Avoid

```xml
<apex:page>
    <script>
        // Required business behavior in client-side script
    </script>
    {!$CurrentPage.parameters.rawHtml}
</apex:page>
```
