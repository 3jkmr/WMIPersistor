# WMIPersistor

# Description:
WMIPersistor is a PowerShell-based tool designed to create, query, and delete WMI Event Subscriptions on Windows systems. It allows penetration testers to create persistence mechanisms via WMI events.

# Key Features:
Create WMI Event Subscriptions: 
Monitor specific processes and trigger custom PowerShell payloads when those processes start.

Query Existing Subscriptions: 
Display all current Event Filters, Event Consumers, and Filter-to-Consumer Bindings, with full details including WQL queries and encoded payloads.

Delete Subscriptions Safely: 
Remove selected subscriptions dynamically by name or partial name. Includes checks to ensure the subscription exists before deletion.

Admin Awareness: 
Warns the user if not run with administrative privileges, since creating or deleting WMI event subscriptions requires elevated permissions.

Payload Encoding: 
Accepts raw PowerShell commands and automatically encodes them in Base64 for execution.

Interactive Menu: 
Simple, user-friendly menu for all operations, returning to the main menu after each action.
