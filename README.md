# SkillSwap

The **SkillSwap** application is designed to create a seamless and engaging skill exchange experience for students.

## Features

- **Secure User Authentication**: Powered by Supabase email login.
- **Skill Posts**: Create posts specifying the skill offered and the exchange preference.
  - *Barter System*: Trade a skill for a skill (or help).
  - *Custom Offers*: Exchange skills for money, treats, or other suitable compensation.
  - *Tags*: Include relevant tags like "Urgent" or "Quick Help".
- **Feed**: Scrollable, card-based feed for easy browsing of all posts.
- **Real-Time Chat**: One-to-one messaging powered by Supabase Realtime. Supports text messages and image sharing (via Supabase Storage) with a clean interface. Includes a "Confirm Swap" option directly within chats.
- **Swap System**: Track and manage swaps as pending or completed.
- **Discovery**: Built-in search bar, exchange type filters, and visible post tags.
- **Trust & Reputation**: Rating system with optional reviews. Profile screens display user skills, ratings, and completed swaps.
- **Additional Functionalities**:
  - Bookmark posts for later.
  - View full swap history.
  - Receive simple in-app notifications.
  - **Open Requests**: A dedicated section where students can post help requests.

## Design

The overall design focuses on a modern, clean, and aesthetic UI, ensuring a minimal yet elegant user experience:
- Gradient AppBar
- Card-based layouts
- Rounded corners and proper spacing
- Google Fonts (like Poppins)

---
*Built with Flutter & Supabase.*
