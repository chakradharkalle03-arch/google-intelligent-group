# 📝 Example Queries for Testing

## 🎯 Full Workflow Queries (Multi-Agent)

### Restaurant Reservation (Complete Flow)
```
Find a nice Italian restaurant near Taipei 101 and make a dinner reservation for tomorrow at 7 PM
```

```
Find an Indian restaurant near me and book a table for tonight at 8 PM
```

```
Search for Japanese restaurants near Xinyi District and reserve a table for tomorrow at 6:30 PM
```

```
Find a good Chinese restaurant near National Taiwan University and make a reservation for Friday at 7:30 PM
```

---

## 🗺️ GoogleMap Agent Queries

### Basic Location Search
```
Find Italian restaurants near Taipei 101
```

```
Search for coffee shops near me
```

```
Find hotels near Ximending
```

```
Show me restaurants near National Taiwan University
```

```
Find bakeries near Zhongshan Station
```

### Specific Cuisine/Location
```
Find Thai restaurants near Songshan Airport
```

```
Search for Korean BBQ restaurants near Taipei Main Station
```

```
Find Mexican restaurants near Daan Park
```

```
Show me French restaurants near Shilin Night Market
```

---

## 📅 Calendar Agent Queries

### Add Events
```
Add a meeting to my calendar for tomorrow at 2 PM
```

```
Schedule a dinner reservation for tonight at 7 PM
```

```
Book an appointment for next Monday at 10 AM
```

```
Add a lunch meeting for Friday at 12:30 PM
```

### View Calendar
```
What's on my calendar tomorrow?
```

```
Show me my schedule for today
```

```
List my events for this week
```

```
What appointments do I have?
```

---

## ☎️ Telephone Agent Queries

### Direct Phone Calls
```
Call +886912345678
```

```
Call the restaurant at +886223456789
```

### Combined with GoogleMap (Auto-extract phone)
```
Find a restaurant near Taipei 101 and call them
```

```
Search for Italian restaurants and call the first one
```

---

## 🔍 Research Agent Queries

### General Information
```
What is artificial intelligence?
```

```
Tell me about the history of Taipei
```

```
Explain how machine learning works
```

```
What are the best practices for software development?
```

### Specific Topics
```
Research the benefits of renewable energy
```

```
Tell me about LangChain framework
```

```
What is the difference between REST and GraphQL?
```

---

## 🎯 Complex Multi-Agent Scenarios

### Scenario 1: Complete Restaurant Booking
```
Find a nice restaurant near Taipei 101, call them to check availability, and book a table for tomorrow at 7 PM if available
```

### Scenario 2: Event Planning
```
Find a good venue near Xinyi District, research what events are happening there, and add it to my calendar for next Saturday
```

### Scenario 3: Business Research
```
Find coffee shops near National Taiwan University, research their ratings, and call the top-rated one
```

---

## 💡 Tips for Best Results

1. **Be Specific**: Include location, time, and type of business
   - ✅ Good: "Find Italian restaurants near Taipei 101"
   - ❌ Less clear: "Find restaurants"

2. **Include Time**: For calendar/reservations, specify date and time
   - ✅ Good: "Book a table for tomorrow at 7 PM"
   - ❌ Less clear: "Book a table"

3. **Combine Agents**: Ask for multi-step tasks
   - ✅ Good: "Find a restaurant and make a reservation"
   - ✅ Good: "Search for places and call them"

4. **Use Natural Language**: The system understands natural queries
   - ✅ Good: "Find me a nice place to eat"
   - ✅ Good: "What's happening tomorrow?"

---

## 🧪 Test Queries by Category

### Quick Tests (Single Agent)
- `Find coffee shops near me`
- `What's on my calendar tomorrow?`
- `Research artificial intelligence`
- `Call +886912345678`

### Medium Tests (2 Agents)
- `Find restaurants near Taipei 101 and show me their details`
- `Find a restaurant and add it to my calendar for tomorrow`

### Full Tests (3+ Agents)
- `Find an Italian restaurant near Taipei 101, call them, and book a table for tomorrow at 7 PM`
- `Search for restaurants, call the first one, and schedule a reservation`

---

## 🎨 Example Conversation Flow

**User:** "Find a nice Italian restaurant near Taipei 101 and make a dinner reservation for tomorrow at 7 PM"

**System Response:**
1. 🗺️ GoogleMap Agent: Finds Italian restaurants
2. ☎️ Telephone Agent: Calls restaurant (if phone available)
3. 📅 Calendar Agent: Creates reservation event
4. 🤖 Supervisor: Generates summary

**Result:** Complete reservation with restaurant details, call status, and calendar event

---

## 📋 Query Templates

### Restaurant Search Template
```
Find [CUISINE] restaurants near [LOCATION]
```

### Reservation Template
```
Find a [TYPE] restaurant near [LOCATION] and make a reservation for [DATE] at [TIME]
```

### Research Template
```
Research [TOPIC]
```

### Calendar Template
```
[ACTION] [EVENT] for [DATE] at [TIME]
```

---

**Happy Testing! 🚀**

