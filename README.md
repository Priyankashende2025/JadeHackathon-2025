# JadeHackathon-2025
JadeHackathon-2025

AI-Powered Talent Acquisition MVP - Jade Global
Executive Summary
This solution delivers an end-to-end, AI-augmented Talent Acquisition system within Salesforce, designed to automate the entire hiring lifecycle. It directly addresses Jade's key challenges: inefficient resume screening, lack of standardization, interview coordination overhead, and post-offer candidate drop-off. The MVP provides immediate value through automation and insights, with a clear roadmap for future enhancements.
Current MVP Scope (What We Are Delivering Now)
1. Core Data Model & Automation
Objects Configured:
Candidate (Contact Object): Enhanced with custom fields, including a ri Resume Text Details field for pasting raw resume text.
Job Requisition (Custom Object - Job_Requisition__c): Contains job title, description, required skills, department, status (Open/Closed), and hiring manager.
Application (Junction Custom Object - Application__c): Links a Candidate to a Job Requisition. Tracks application stage and AI-generated fields.
Automated AI Resume Screening: An Apex Trigger automatically initiates screening upon Application creation. It reads the Resume Text Details and Job Description to dynamically generate:
AI Screening Status, AI Match Score, AI Skills Matched, AI Summary.
2. Talent Acquisition App & Central Homepage
A custom Salesforce App named "AI Talent Acquisition" provides a centralized workspace for the TA team.
Homepage Dashboard: The app's homepage features a dynamic dashboard with key components:
Open Job Requisitions vs. Applications: A bar chart showing all open jobs and the number of applications each has received, providing a quick pipeline overview.
Today's Tasks & Events: A list component displaying the current user's pending tasks (e.g., "Follow up with Candidate X") and calendar events (e.g., "Interview with Candidate Y at 2 PM") for the day.
Recent Activities: A feed of recently created records (new Applications, new Job Requisitions) and comments logged by team members.
3. Embedded Analytics & Actions
Job Requisition Page: Each Job Requisition record detail page includes an embedded related list  that displays only the Top 5 Applications for that specific job, sorted by the AI Match Score in descending order. This allows recruiters to instantly see the best candidates for any given role.
Candidate Actions: From any Candidate or Application record, the TA team can:
Schedule Meetings: Use the Salesforce "New Event" button to schedule interviews. The system pre-populates the candidate's details and allows linking to the Application.
Log Follow-ups: Quickly create Tasks (e.g., "Call for initial screening," "Send follow-up email") directly from the record, ensuring all communication is tracked.
4. Reporting & Dashboards
Key Reports: Open Jobs, Application Pipeline, Top Applications by AI Score.
TA Team Dashboard: Includes the Top 5 Applications component and other key metrics.
5. Email Notification
Communications: From Salesforce Candidate record send interview email , reminders , and post-interview feedback.



Future Enhancements: Addressing the Full TA Lifecycle
The MVP architecture is designed to scale and address all stated challenges.
1. Resume Screening & Standardization (High Priority)
Future Solution:
Azure AI Integration: Integrate Azure AI Document Intelligence to automatically parse uploaded PDF resumes, extracting text, skills, and experience into structured fields, eliminating manual copy-paste.
Resume Standardization Tool: Build a Salesforce Lightning Component that uses the parsed data to auto-generate a standardized Jade resume format. The tool would:
Remove personal contact details as per policy.
Use Azure AI's language services to check for grammar and spelling errors.
Ensure consistent formatting, fonts, and structure.
Benefit: One-click resume standardization for client submissions, saving hours of manual reformatting.
2. Intelligent Interview Scheduling (Medium Priority)
Future Solution:
Calendar API Integration: Integrate with Google Calendar/Microsoft Outlook APIs.
Scheduler Tool: Develop a tool where a recruiter can select a candidate and panelists. The system checks everyone's real-time calendar availability and suggests optimal time slots.
Automated Coordination: The tool automatically sends out calendar invites to all parties and manages rescheduling requests.
Benefit: Eliminates the endless email chain for scheduling.
3. Post-Offer Candidate Engagement (High Priority)
Future Solution:
Automated Nurture Campaigns: Use Salesforce Marketing Cloud or Pardot to build a personalized email journey.
Automated Activities: The system will automatically create tasks for the TA team to conduct check-in calls at regular intervals (e.g., 2 weeks after offer, 1 week before join date).
Content Delivery: Automatically send onboarding documents, team introductions, and company culture updates.
Benefit: Systematic, warm candidate experience that significantly boosts joining ratios.
4. Advanced Analytics & Einstein Prediction Builder
Future Solution: Use Einstein AI to predict the probability of a candidate dropping out post-offer or the likelihood of a job offer being accepted, allowing for proactive intervention.

Installation & Setup Steps for MVP
Prerequisites:
A Salesforce Sandbox or Developer Edition org.
Appropriate user permissions for configuration.
Configuration Steps:
Deploy Metadata: Deploy all custom objects, fields, page layouts, and the custom app.
Configure Homepage: Edit the App's homepage layout to add the dashboard components (Open Jobs chart, Today's Tasks list, Recent Activities feed).
Configure Job Requisition Page: Add the "Top 5 Applications" related list/LWC to the Job Requisition page layout.
Implement Automation: Deploy the Apex Trigger and Queueable Class for AI screening (code from previous section).
Build Reports and Dashboard: Create the reports and overall TA dashboard.
User Training: Train the TA team on using the homepage, scheduling from records, and understanding the AI scores.
This solution provides a powerful, scalable foundation that transforms Jade's TA process from a manual, reactive function into a streamlined, AI-driven, and proactive strategic operation.
