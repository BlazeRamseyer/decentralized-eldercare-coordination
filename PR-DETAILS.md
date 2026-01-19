## Summary
This PR introduces the `caregiver-registry` smart contract for comprehensive eldercare coordination with verified caregivers, ratings, and assignment tracking on the Stacks blockchain.

## Changes
- Implemented caregiver registration with full profile management
- Built credential verification and certification tracking system
- Created assignment management with hour logging
- Integrated rating and review system with average calculation
- Added availability status management
- Built background verification framework
- Created comprehensive read-only query functions

## Contract Features

### Caregiver Registration
- Register with name, bio, and specializations
- Set hourly rates and availability
- Link wallet addresses to caregiver profiles
- Prevent duplicate registrations
- Track registration timestamps

### Profile Management
- Update bio and specializations
- Modify hourly rates
- Toggle availability status
- Maintain profile history

### Credential & Verification
- Add certifications with issuer details
- Track certification expiration dates
- Background check verification by contract owner
- Verification timestamp tracking

### Assignment Management
- Create new care assignments
- Track assignment duration and hours
- Complete assignments with hour logging
- Maintain active/completed status
- Automatic caregiver statistics updates

### Rating System
- 1-5 star rating scale
- Optional text reviews
- Average rating calculation
- Rating count tracking
- Client-only rating authorization

## Data Structures
- **Caregivers**: Complete profiles with statistics and verification
- **Caregiver By Wallet**: Quick wallet-to-ID lookup
- **Certifications**: Credential tracking with expiry dates
- **Assignments**: Care assignment records with hours
- **Ratings**: Reviews and ratings with timestamps
- **Availability Schedule**: Day-of-week schedules (structure defined)
- **Emergency Contacts**: Contact information (structure defined)

## Error Handling
- Duplicate registration prevention
- Authorization validation
- Rating range validation (1-5)
- Completed assignment verification
- Owner-only verification control

## Technical Details
- 369 lines of clean Clarity code
- 8 public functions for state modification
- 9 read-only functions for queries
- 7 data maps for comprehensive tracking
- 2 nonce counters for ID generation
- 6 error constants

## Key Workflows

### Caregiver Onboarding
1. Register with `register-caregiver`
2. Add certifications with `add-certification`
3. Wait for background verification
4. Set availability

### Assignment Lifecycle
1. Client creates assignment with `create-assignment`
2. Caregiver provides care
3. Client completes with `complete-assignment`
4. Client rates with `rate-caregiver`

## Security Considerations
- Wallet-based authentication
- Owner-only background verification
- Client-only assignment completion
- Rating authorization checks
- Immutable historical records

## Testing Recommendations
- Test registration and duplicate prevention
- Verify authorization on all protected operations
- Test rating calculation logic
- Validate assignment lifecycle
- Test certification tracking
