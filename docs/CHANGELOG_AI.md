# AI Changelog

## DATE: 2026-08-28
**FEATURE**: Solo Race Billing
**CHANGE**: Fixed Solo Race billing logic so the selected loser pays 100% of the bill without falling back to equal splitting.
**AFFECTED SYSTEMS**: Game billing.
**DO NOT MODIFY**: Team Race, Standard Game.

## DATE: 2026-08-28
**FEATURE**: Riverpod Providers
**CHANGE**: Replaced synchronous Stream.value() emissions with const Stream.empty() across all feature providers when clubId is null to prevent setState() called during build exceptions.
**AFFECTED SYSTEMS**: Analytics, Credit, Games, Inventory, Quick Sales providers.
