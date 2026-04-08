# CalBNB – Subscription Tiers: Full Feature Reference

> This document provides a complete breakdown of every feature, module, configuration, and limit available at each subscription tier. For a high-level overview, see the [README.md](README.md).

---

## How Tier Gating Works

The application uses `SubscriptionGuard` widgets throughout the UI. When you attempt to use a feature that requires a higher tier, the app does **one of two things**:

1. **Hides the feature entirely** (e.g., the Inbox icon never appears in the sidebar navigation).
2. **Blocks with an upgrade prompt** (e.g., clicking "Add Property" when you've hit your limit shows a dialog with options to upgrade).

Your company's active tier is stored in Firebase and is checked at runtime on every screen load using Riverpod providers. Downgrades do not delete data — they simply restrict access to it.

---

## 🆓 Free Tier — $0.00/month

**Best for:** Solo hosts managing 1–2 properties with no staff.

### Limits
| Resource | Value |
| :--- | :--- |
| Properties Included | **2** |
| Overage Properties | ❌ Not Allowed |
| Max User Seats | **1** (Admin only) |

### Features & Modules Enabled
- **Calendar View**: See a basic daily and monthly calendar for your properties.
- **Standard Checklists**: Create and assign simple room-by-room to-do lists (text entries only).
- **Manual Status Updates**: Manually change the status of cleaning tasks (no automated assignment).
- **Basic Property Data**: Add property name, address, lockbox PIN, and cleaning notes.
- **Dashboard**: Basic overview of today's check-in and check-out events.

### What Is NOT Available
- ❌ Inviting external users (No Cleaners, Managers, or Inspectors)
- ❌ Team Inbox (requires Silver+)
- ❌ Photo Evidence uploads (requires Bronze+)
- ❌ Payroll Module (requires Gold+)
- ❌ Owner Portal (requires Gold+)
- ❌ Overage properties (limit is hard-capped at 2)

---

## 🥉 Bronze Tier — $9.99/month

**Best for:** Small hosts who need a basic team of cleaners.

### Limits
| Resource | Value |
| :--- | :--- |
| Properties Included | **5** |
| Overage Rate | **$2.00/property/month** |
| Max User Seats | **4** (1 Admin, 3 Cleaners) |

### New Features Unlocked vs Free
- ✅ **Invite Cleaners**: Add up to 3 external cleaning staff members by email.
- ✅ **Mobile App Access for Cleaners**: Cleaner staff can download the CalBNB mobile app and receive job assignments directly.
- ✅ **Photo Evidence (3/clean)**: Cleaners can upload up to 3 photos per cleaning job as proof of completion.
- ✅ **Overage Properties**: Pay $2.00/month for each property beyond the 5 included.

### Property Configuration Available
- Name, Address, City, State, ZIP, Country
- Cleaning Instructions (text notes for the cleaner)
- Cleaning Fee (displayed with your company's local currency symbol)
- Size in `AxBxC` (Rooms × Bathrooms × Floors) format
- Lockbox PIN, House PIN, Garage PIN
- Checklists (custom per-room task lists)

### What Is NOT Available
- ❌ Team Inbox
- ❌ Manager / Inspector roles
- ❌ Scheduling Settings (Recurring clean cadence)
- ❌ Payroll Module
- ❌ Owner Portal

---

## 🥈 Silver Tier — $29.99/month

**Best for:** Growing co-hosting businesses with a mix of cleaning and management staff.

### Limits
| Resource | Value |
| :--- | :--- |
| Properties Included | **15** |
| Overage Rate | **$1.50/property/month** |
| Max User Seats | **10** |

### New Features Unlocked vs Bronze
- ✅ **Team Inbox**: Full in-app channel-based communication is unlocked.
  - `General` channel (visible to all company members)
  - `Cleaners` channel (for cleaning staff)
  - `Inspectors` channel (for quality control staff)  
  - 1-on-1 Direct Messaging between any two team members
  - Unread message badges visible in the main navigation sidebar
- ✅ **Team Roles (Cleaner vs Manager)**: You can now differentiate user roles, giving Managers elevated access to assign cleaning jobs and manage property calendars.
- ✅ **Advanced Scheduling Settings**:
  - **Recurring Clean Cadence**: Configure properties to automatically generate cleaning tasks on a recurring schedule (e.g., every X days), independent of check-out events.
  - This setting is accessible per-property inside the Edit Property form.

### What Is NOT Available
- ❌ Inspector Role (requires Gold+)
- ❌ Payroll Module (requires Gold+)
- ❌ Owner Portal / Linked Owner Accounts (requires Gold+)

---

## 🥇 Gold Tier — $69.99/month

**Best for:** Regional property management companies with owners expecting financial reporting.

### Limits
| Resource | Value |
| :--- | :--- |
| Properties Included | **30** |
| Overage Rate | **$1.25/property/month** |
| Max User Seats | **18** |

### New Features Unlocked vs Silver
- ✅ **Payroll Module & Reports**:
  - Automated earnings calculation per cleaner based on completed jobs and property cleaning fees.
  - Aggregated payout board summarizing all unpaid earnings by staff member.
  - Admins can mark individual employees as "Paid" with date and confirmation.
  - Monthly earning statements downloadable or viewable as in-app charts.
- ✅ **Inspector Role**:
  - A dedicated `Inspector` dashboard displaying all recently completed cleaning jobs.
  - Inspectors can open individual jobs and review uploaded photo evidence room by room.
  - Two-state review system: **Approved** or **Fix Needed** (sends the job back to the cleaner with a notification).
- ✅ **Owner Portal (Linked Owner Accounts)**:
  - Register a property owner as a special `Owner` role user.
  - Link their account directly to one or more of your properties in the property settings.
  - When the owner logs in, they see an isolated, read-only dashboard showing only: their property's booking calendar and financial statements. They cannot see team chats, payroll details for other properties, or any other company data.

### What Is NOT Available
- ❌ Multi-Currency Billing override (requires Platinum+)
- ❌ White Labeling (requires Diamond)
- ❌ Advanced Analytics (requires Diamond)
- ❌ Priority WhatsApp Support (requires Diamond)

---

## 💎 Platinum Tier — $199.99/month

**Best for:** Large-scale enterprise property management companies.

### Limits
| Resource | Value |
| :--- | :--- |
| Properties Included | **60** |
| Overage Rate | **$1.00/property/month** |
| Max User Seats | **39** |

### New Features Unlocked vs Gold
- ✅ **Multi-Currency Billing**: Configure your company to operate using a currency other than USD. The Cleaning Fee display, payroll reports, and financial statement calculations automatically switch to display in the configured currency symbol (e.g., `S/` for Peruvian Sol, `€` for Euro).
- ✅ Everything from Free → Gold is included.

### What Is NOT Available
- ❌ White Labeling (requires Diamond)
- ❌ Advanced Analytics (requires Diamond)
- ❌ Priority WhatsApp Support (requires Diamond)

---

## 💠 Diamond Tier — $299.99/month

**Best for:** Very large operations or agencies reselling CalBNB capabilities under their own brand.

### Limits
| Resource | Value |
| :--- | :--- |
| Properties Included | **100** |
| Overage Rate | **$0.75/property/month** (the lowest available rate) |
| Max User Seats | **106** |

### New Features Unlocked vs Platinum
- ✅ **White Labeling**: Customize the application's branding to match your company's identity. This includes custom colors, logos, and branding throughout the interface.
- ✅ **Advanced Analytics**: Access to deeper data visualizations across the entire property portfolio. Track performance metrics for cleaning completion times, inspection approval rates, and financial trends over time.
- ✅ **Priority WhatsApp Support**: Direct, priority access to the CalBNB support team via a dedicated WhatsApp channel. Issues are escalated and resolved faster than standard ticket support.
- ✅ Everything from Free → Platinum is included.

---

## ↔️ Feature Comparison at a Glance

| Feature | Free | Bronze | Silver | Gold | Platinum | Diamond |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Calendar Sync** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Basic Checklists** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Invite Cleaners** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Photo Evidence** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Team Inbox** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Recurring Schedules** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Manager Role** | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Payroll Module** | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| **Inspector Role** | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| **Owner Portal** | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| **Multi-Currency** | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| **White Labeling** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Advanced Analytics** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Priority Support** | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Overage Properties** | ❌ | $2.00 | $1.50 | $1.25 | $1.00 | $0.75 |
