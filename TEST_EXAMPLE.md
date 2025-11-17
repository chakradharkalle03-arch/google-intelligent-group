# 🧪 Test Example: Full Multi-Agent Workflow

## Example Query

```
Please help me find a good Indian restaurant near Taipei 101 and make a reservation for tomorrow evening at 7:00 PM.
```

---

## Expected Workflow

### Step 1: Supervisor Planning
- ✅ Analyzes query
- ✅ Identifies needed agents:
  - `use_googlemap: true` (finds restaurants)
  - `use_calendar: true` (makes reservation)
  - `use_telephone: true` (calls restaurant)
  - `use_research: false` (not needed)

### Step 2: GoogleMap Agent Execution
- ✅ Searches for "Indian restaurant near Taipei 101"
- ✅ Returns top results with:
  - Restaurant name
  - Address
  - Phone number
  - Rating
- ✅ Results passed to other agents

### Step 3: Telephone Agent Execution
- ✅ Extracts phone number from GoogleMap results
- ✅ Calls restaurant via Fonoster
- ✅ Logs call status
- ✅ Result: "Call initiated to [restaurant]"

### Step 4: Calendar Agent Execution
- ✅ Extracts event details:
  - Date: "tomorrow"
  - Time: "19:00" (7:00 PM)
  - Title: "Dinner Reservation at [Restaurant Name]"
- ✅ Uses restaurant info from GoogleMap:
  - Location: Restaurant name + address
  - Description: Restaurant details + phone
- ✅ Creates calendar event
- ✅ Result: "Event 'Dinner Reservation at [Restaurant]' added to calendar"

### Step 5: Supervisor Summary
- ✅ Combines all agent results
- ✅ Generates cohesive summary
- ✅ Returns final response

---

## Expected Outputs

### GoogleMap Agent Output:
```
🗺️ Found 5 result(s) for 'Indian restaurant near Taipei 101':

1. **Restaurant Name**
   📍 Address: [Address]
   ⭐ Rating: 4.5/5.0
   ☎️ Phone: +886-2-XXXX-XXXX
```

### Telephone Agent Output:
```
☎️ Call Status: initiated
   📞 Phone Number: +886-2-XXXX-XXXX
   💬 Message: Calling regarding: [query]
```

### Calendar Agent Output:
```
✅ Event 'Dinner Reservation at [Restaurant Name]' added to calendar for [Date] at 19:00
```

### Supervisor Summary:
```
[Cohesive summary combining all results]
```

---

## Verification Checklist

- [ ] GoogleMap Agent finds restaurants
- [ ] Telephone Agent extracts phone from GoogleMap results
- [ ] Telephone Agent makes call
- [ ] Calendar Agent extracts date/time correctly ("tomorrow evening at 7:00 PM" → tomorrow, 19:00)
- [ ] Calendar Agent uses restaurant name from GoogleMap
- [ ] Calendar Agent creates event with full details
- [ ] All agent outputs displayed in frontend
- [ ] Supervisor generates final summary

---

## How to Test

1. **Start the system:**
   ```powershell
   .\run_web.ps1
   ```

2. **Open frontend:** http://localhost:3000

3. **Enter query:**
   ```
   Please help me find a good Indian restaurant near Taipei 101 and make a reservation for tomorrow evening at 7:00 PM.
   ```

4. **Watch the streaming responses:**
   - Status: "Analyzing query..."
   - Status: "Searching for locations..."
   - GoogleMap Agent output appears
   - Status: "Initiating phone call..."
   - Telephone Agent output appears
   - Status: "Managing calendar..."
   - Calendar Agent output appears
   - Status: "Generating final summary..."
   - Final summary appears

5. **Check Agent Dashboard:**
   - GoogleMap Agent card shows restaurant results
   - Telephone Agent card shows call status
   - Calendar Agent card shows event creation
   - Supervisor Response shows final summary

---

## Success Criteria

✅ All 3 agents (GoogleMap, Telephone, Calendar) execute  
✅ GoogleMap results passed to Telephone and Calendar  
✅ Calendar event created with restaurant details  
✅ Time correctly parsed: "tomorrow evening at 7:00 PM" → tomorrow, 19:00  
✅ All outputs visible in frontend  
✅ Final summary combines all results  

---

## Troubleshooting

### If GoogleMap Agent doesn't run:
- Check API key in `backend/.env`
- Verify Places API is enabled in Google Cloud Console

### If Telephone Agent doesn't run:
- Check if phone number found in GoogleMap results
- Verify Fonoster server is running (optional)

### If Calendar Agent doesn't run:
- Check time parsing (should handle "evening at 7:00 PM")
- Verify restaurant info passed from GoogleMap

### If agents don't connect:
- Check supervisor agent planning logic
- Verify `previous_results` passed correctly

---

**Ready to test! 🚀**

