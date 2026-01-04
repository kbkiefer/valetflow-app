# ValetFlow Data Models (Firebase Firestore)

## Collections Structure

### users
```
{
  userId: string (auto-generated)
  email: string
  phone: string?
  firstName: string
  lastName: string
  role: 'admin' | 'manager' | 'employee' | 'resident' | 'property_manager'
  companyId: string (reference)
  communityId: string? (for residents/property managers)
  unitNumber: string? (for residents)
  profilePhotoUrl: string?
  createdAt: timestamp
  updatedAt: timestamp
  isActive: boolean
  fcmTokens: string[] (for push notifications)
}
```

### companies
```
{
  companyId: string (auto-generated)
  name: string
  address: object
  phone: string
  email: string
  logo: string?
  settings: {
    gpsTrackingEnabled: boolean
    photoRequirementLevel: 'none' | 'issues_only' | 'all_pickups'
    notificationDefaults: object
  }
  createdAt: timestamp
}
```

### employees
```
{
  employeeId: string (auto-generated)
  userId: string (reference to users)
  companyId: string (reference)
  employeeNumber: string
  hireDate: timestamp
  position: string
  payRate: number
  vehicleAssigned: string?
  documents: {
    driversLicense: { url: string, expiryDate: timestamp }
    backgroundCheck: { url: string, completedDate: timestamp }
  }
  availability: {
    monday: { available: boolean, startTime: string, endTime: string }
    tuesday: ...
  }
  performance: {
    completionRate: number
    averageTimePerRoute: number
    issueReportCount: number
  }
  isActive: boolean
  createdAt: timestamp
  updatedAt: timestamp
}
```

### communities
```
{
  communityId: string (auto-generated)
  companyId: string (reference)
  name: string
  address: object {
    street: string
    city: string
    state: string
    zip: string
    coordinates: { lat: number, lng: number }
  }
  propertyManagerContact: {
    name: string
    email: string
    phone: string
  }
  serviceDetails: {
    serviceDays: string[] (['monday', 'wednesday', 'friday'])
    serviceTime: string ('evening' | 'morning')
    unitCount: number
    buildingCount: number
  }
  accessInstructions: string
  gateCode: string?
  specialInstructions: string?
  contractInfo: {
    startDate: timestamp
    monthlyRate: number
    billingContact: string
  }
  isActive: boolean
  createdAt: timestamp
  updatedAt: timestamp
}
```

### routes
```
{
  routeId: string (auto-generated)
  companyId: string (reference)
  name: string
  description: string
  communityIds: string[] (references to communities)
  assignedEmployeeId: string? (reference to employees)
  scheduledDays: string[] (['monday', 'wednesday'])
  startTime: string ('18:00')
  estimatedDuration: number (minutes)
  stopOrder: string[] (ordered array of communityIds)
  isActive: boolean
  createdAt: timestamp
  updatedAt: timestamp
}
```

### shifts
```
{
  shiftId: string (auto-generated)
  companyId: string (reference)
  employeeId: string (reference)
  routeId: string (reference)
  scheduledDate: timestamp
  scheduledStartTime: timestamp
  scheduledEndTime: timestamp
  status: 'scheduled' | 'started' | 'completed' | 'cancelled' | 'no_show'
  actualStartTime: timestamp?
  actualEndTime: timestamp?
  clockInLocation: { lat: number, lng: number }?
  clockOutLocation: { lat: number, lng: number }?
  createdAt: timestamp
  updatedAt: timestamp
}
```

### activeShifts (subcollection for live GPS tracking)
```
{
  shiftId: string (same as parent shift)
  employeeId: string (reference)
  routeId: string (reference)
  currentLocation: {
    coordinates: { lat: number, lng: number }
    timestamp: timestamp
    speed: number?
    heading: number?
  }
  routeProgress: {
    currentCommunityId: string?
    completedCommunityIds: string[]
    totalCommunities: number
    completedPickups: number
    totalPickups: number
  }
  startedAt: timestamp
  lastUpdated: timestamp
}
```

### pickups
```
{
  pickupId: string (auto-generated)
  shiftId: string (reference)
  communityId: string (reference)
  employeeId: string (reference)
  scheduledDate: timestamp
  completedAt: timestamp?
  status: 'pending' | 'completed' | 'missed' | 'issue'
  location: { lat: number, lng: number }?
  photoUrls: string[]
  notes: string?
  issueType: string? ('contamination' | 'no_access' | 'overflowing' | 'other')
  createdAt: timestamp
  updatedAt: timestamp
}
```

### issues
```
{
  issueId: string (auto-generated)
  type: 'missed_pickup' | 'contamination' | 'damage' | 'access' | 'other'
  reportedBy: 'employee' | 'resident' | 'admin'
  reportedById: string (userId reference)
  communityId: string (reference)
  unitNumber: string?
  description: string
  photoUrls: string[]
  status: 'open' | 'investigating' | 'resolved' | 'closed'
  priority: 'low' | 'medium' | 'high'
  assignedToId: string? (employeeId reference)
  resolution: string?
  createdAt: timestamp
  resolvedAt: timestamp?
  updatedAt: timestamp
}
```

### notifications
```
{
  notificationId: string (auto-generated)
  userId: string (reference - recipient)
  type: 'driver_nearby' | 'pickup_complete' | 'missed_pickup' | 'schedule_change' | 'announcement'
  title: string
  message: string
  data: object (additional context)
  isRead: boolean
  sentAt: timestamp
  expiresAt: timestamp?
}
```

## Indexes Required

1. **employees**: companyId, isActive
2. **communities**: companyId, isActive
3. **routes**: companyId, assignedEmployeeId
4. **shifts**: employeeId, scheduledDate, status
5. **activeShifts**: employeeId (for live tracking queries)
6. **pickups**: shiftId, communityId, status
7. **issues**: communityId, status, reportedBy
8. **notifications**: userId, isRead, sentAt

## Security Rules Philosophy

- **users**: Can read own profile, admins can read all
- **employees**: Admins/managers full access, employees read-only own data
- **communities**: Admins/managers write, employees/residents read assigned communities
- **routes**: Admins/managers write, employees read assigned routes
- **shifts**: Admins/managers write, employees read/update own shifts
- **activeShifts**: Employees write own location, admins/residents read
- **pickups**: Employees write, all read
- **issues**: All authenticated users can create, admins manage
- **notifications**: Users can only read own notifications

## Real-time Subscriptions

### Admin App:
- `activeShifts` - all active field employees
- `shifts` - today's shifts
- `issues` - open issues

### Field App:
- `shifts/{employeeId}` - employee's shifts
- `routes/{assignedRouteId}` - assigned route details

### Community App:
- `activeShifts` (filtered by nearby geohash) - drivers in area
- `notifications/{userId}` - user's notifications
- `issues` (filtered by communityId + unitNumber) - their issues

## Cloud Functions Needed

1. **updateEmployeeLocation** - Process GPS updates from field app
2. **detectNearbyDrivers** - Geofence detection for community notifications
3. **sendDriverNearbyNotification** - Push notification to residents
4. **createPickupRecords** - Auto-create pickup records when shift starts
5. **calculateShiftMetrics** - Update employee performance stats
6. **sendScheduledReminders** - Cron job for pickup reminders
