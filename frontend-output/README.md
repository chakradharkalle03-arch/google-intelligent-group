# Frontend Output Documentation

## Google Intelligent Group Multi-Agent System - Frontend UI

This document describes the frontend user interface output for the Google Intelligent Group Multi-Agent System built with LangChain 1.0 & Next.js.

## Screenshots

### Real Demo UI Screenshot
See `frontend_UI_pannel.png` for a visual representation of the actual running application interface showing:
- Supervisor Agent result section with comprehensive summary
- Right sidebar panels (Map, Calendar, Telephone, Research)
- Input section with Run button
- Complete UI layout and design

## UI Layout

### Header Section
- **Title**: "Google Intelligent Group Multi-Agent System with LangChain 1.0 & Next.js"
- **Status Indicator**: "System Online" (green indicator in top right corner)

### Main Content Area

#### 1. Supervisor Agent Result (Primary Output Section - Top Left)
The Supervisor Agent result section displays a comprehensive summary of all agent actions:

**Structure:**
- **Greeting**: Personalized greeting addressing the user's query
- **Agent Summaries**: Detailed breakdown of each agent's actions:
  - **GoogleMap Agent**: Restaurant search results with ratings, addresses, and phone numbers
  - **Calendar Agent**: Calendar event creation with event details (date, time, location, description)
  - **Telephone Agent**: Call attempt status and results
  - **Research Agent**: Status (needed/not needed)
- **Summary Section**: Final summary with key actions taken and next steps

**Example Output:**
```
Hello! I'm here to help you find a good Indian restaurant near Taipei 101 and make a reservation for tomorrow at 7:00 PM.

GoogleMap Agent: I found several highly-rated Indian restaurants near Taipei 101 for you. The top recommendation, with a 4.9 rating, is **Oye Punjabi Indian Restaurant**. It's located at No. 121號, Yanji St, Da'an District, Taipei City, Taiwan 106, and their phone number is 02 2775 2065. Other options included Balle Balle Indian Restaurant & Bar, Khana Khazana, Saffron 46, and Mayur Indian Kitchen.

Calendar Agent: Based on your request and the restaurant selected, I've gone ahead and added a calendar event for you. It's for a 'Dinner Reservation at Oye Punjabi Indian Restaurant' tomorrow at 7:00 PM, located at No. 121號, Yanji St, Da'an District, Taipei City, Taiwan 106. The description includes the restaurant's phone number: 02 2775 2065.

Telephone Agent: I attempted to make the reservation for you at Oye Punjabi Indian Restaurant (+886227752065) for tomorrow at 7:00 PM. However, I encountered a technical issue and was unable to connect to the Fonoster server to complete the call. This means the reservation could not be confirmed at this time.

Research Agent: This agent was not needed for your query, as it's typically used for general information and research questions.

In summary: I've identified a highly-rated Indian restaurant for you, Oye Punjabi, and created a calendar event with all the details. Unfortunately, I was unable to complete the reservation call due to a server connection issue. You may need to try making the reservation yourself by calling Oye Punjabi at 02 2775 2065, or we can try again if the server issue is resolved!
```

#### 2. Right Sidebar Panels (Detailed Agent Outputs)

##### Map Panel
**Title**: "Here are some Indian restaurants near Taipei 101:"

**Content**: List of restaurants with:
- Restaurant name
- Address
- Phone number
- Rating

**Example:**
- **Oye Punjabi Indian Restaurant**
  - Address: No. 121號, Yanji St, Da'an District, Taipei City, Taiwan 106
  - Phone: 02 2775 2065
  - Rating: 4.9

- **Balle Balle Indian Restaurant & Bar 巴雷巴雷印度餐廳**
  - Address: 105, Taiwan, Taipei City, Songshan District, Guangfu N Rd. 12號1樓
  - Phone: 02 2570 7265
  - Rating: 4.9

- **Khana Khazana 饗印**
  - Address: 110, Taiwan, Taipei City, Xinyi District, Section 1, Keelung Rd. 366號1樓
  - Phone: 02 8786 9366

##### Calendar Panel
**Title**: "I've added a calendar event for you:"

**Content**: Calendar event details:
- **Event**: Dinner Reservation at Oye Punjabi Indian Restaurant
- **Date**: Tomorrow
- **Time**: 7:00 PM
- **Location**: No. 121號, Yanji St, Da'an District, Taipei City, Taiwan 106
- **Description**: Reservation for an Indian restaurant. Phone: 02 2775 2065

##### Telephone Panel
**Content**: Call attempt status and details:
```
I attempted to make a call to Oye Punjabi Indian Restaurant (+886227752065) to book a table for tomorrow at 7:00 PM, but I was unable to connect to the Fonoster server. Please ensure the Fonoster server is running and try again.
```

##### Research Panel
**Content**: Agent status:
```
Research Agent: Not needed for this query. This agent is used for general information and research questions.
```

#### 3. Input Section (Bottom Left)
- **Input Field**: Textarea for entering user queries
- **Character Counter**: Displays character count (e.g., "107 chars")
- **Run Button**: Purple button with lightning bolt icon (⚡) positioned beside the input field

**Example Query:**
```
Please help me find a good Indian restaurant near Taipei 101 and make a reservation for tomorrow at 7:00 PM
```

## UI Features

### Layout Structure
- **Left Column (2/3 width)**:
  1. Supervisor Agent result (top)
  2. Task Status (when processing)
  3. Input field with Run button (bottom)

- **Right Column (1/3 width)**:
  1. Map panel
  2. Calendar panel
  3. Telephone panel
  4. Research panel

### Design Elements
- Clean, modern white background with purple/pink accents
- Card-based layout with rounded corners
- Scrollable content areas for long outputs
- Real-time status updates
- System Online indicator

### Interactive Elements
- Input textarea for queries
- Run button for submitting queries
- Character counter
- Scrollable result panels
- Real-time task execution tracking

## Technical Implementation

- **Framework**: Next.js 14
- **Styling**: Tailwind CSS v4
- **State Management**: React Hooks
- **Streaming**: Server-Sent Events (SSE)
- **Backend API**: Quart API (Python)

## User Flow

1. User enters query in Input field
2. User clicks Run button
3. System shows "Doing Task..." status
4. Supervisor Agent coordinates sub-agents
5. Real-time updates show task execution steps
6. Results appear in Supervisor Agent result section
7. Detailed outputs appear in right sidebar panels
8. Final summary is displayed

## Example Use Case

**Query**: "Please help me find a good Indian restaurant near Taipei 101 and make a reservation for tomorrow at 7:00 PM"

**Result**:
- GoogleMap Agent finds restaurants
- Calendar Agent creates event
- Telephone Agent attempts call (may fail if Fonoster server not running)
- Research Agent skipped (not needed)
- Comprehensive summary provided in Supervisor Agent result
