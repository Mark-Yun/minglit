# Specification: Event Detail Screen (User App)

## 1. Overview
Implement the detailed view for a specific event in the `app_user` application. This screen serves as the primary conversion point where users view event details and proceed through the admission flow (Identity -> Qualification -> Ticket Selection).

## 2. User Stories
- As a **User**, I want to see detailed information about an event (location, time, host, description) so I can decide if I want to attend.
- As a **User**, I want to see the specific entry conditions (age, gender, qualifications) required for the event.
- As a **Guest**, I want to be prompted to login/sign up when I try to join.
- As a **Logged-in User**, I want to see my current admission status (e.g., "Identity Verification Needed", "Eligible") and be guided to the next step.

## 3. Functional Requirements
### 3.1. Data Display
- **Event Header:** Large hero image, Event Title, Host Name.
- **Event Info:** Date/Time, Location (with map preview if possible), Description.
- **Entry Conditions:** Display structured list of conditions (Age, Gender, Occupation, etc.) using `EntryGroupDetail`.

### 3.2. Admission Logic (Trust System)
- Integrate with `EventAdmissionController`.
- **States:**
  - `Guest`: Show "Login to Join".
  - `IdentityRequired`: Show "Verify Identity".
  - `QualificationRequired`: Show "Apply for Qualification".
  - `NotEligible`: Show "Not Eligible" with reason.
  - `Eligible`: Show "Select Ticket".

### 3.3. Interaction
- **Primary CTA:** Dynamic button at the bottom (fixed or sticky) adapting to the admission state.
- **Back Navigation:** Standard back button to return to the list.
- **Refresh:** Pull-to-refresh to reload event data and admission status.

## 4. Technical Requirements
- **Framework:** Flutter (app_user)
- **State Management:** Riverpod (`EventDetailController`, `EventAdmissionController`)
- **Navigation:** GoRouter (Coordinator pattern)
- **Error Handling:** Use `handleMinglitError` for API failures.
- **Components:** Reuse `MinglitButton`, `MinglitImage`, `EntryGroupDetail` (from `minglit_kit`).

## 5. UI/UX Guidelines
- Follow `minglit_kit` design tokens (Colors, Typography, Spacing).
- Ensure "Safe Area" support for notched devices.
- Loading states should use standard skeletons or spinners.

