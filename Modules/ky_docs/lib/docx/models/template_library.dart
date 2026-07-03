import 'package:flutter/material.dart';

import 'document_template.dart';

class TemplateLibrary {
  static List<DocumentTemplate> templates = [
    DocumentTemplate(
      id: 'blank',
      name: 'Blank Document',
      description: 'Start with a clean slate',
      category: 'General',
      icon: Icons.description,
      content: '',
    ),
    DocumentTemplate(
      id: 'meeting_notes',
      name: 'Meeting Notes',
      description: 'Structured meeting documentation',
      category: 'Business',
      icon: Icons.meeting_room,
      content: '''Meeting Notes

Date: [Insert Date]
Time: [Insert Time]
Location: [Insert Location]
Attendees: [List attendees]

Agenda:
1. [Topic 1]
2. [Topic 2]
3. [Topic 3]

Discussion Points:
• [Point 1]
• [Point 2]
• [Point 3]

Action Items:
☐ [Action 1] - Assigned to: [Name] - Due: [Date]
☐ [Action 2] - Assigned to: [Name] - Due: [Date]
☐ [Action 3] - Assigned to: [Name] - Due: [Date]

Next Meeting: [Date and Time]

Notes:
[Additional notes]''',
    ),
    DocumentTemplate(
      id: 'professional_letter',
      name: 'Professional Letter',
      description: 'Formal business letter format',
      category: 'Business',
      icon: Icons.mail,
      content: '''[Your Name]
[Your Address]
[City, State ZIP Code]
[Your Email]
[Your Phone Number]

[Date]

[Recipient Name]
[Recipient Title]
[Company Name]
[Company Address]
[City, State ZIP Code]

Dear [Recipient Name],

[Opening paragraph - State the purpose of your letter]

[Middle paragraph(s) - Provide details, explanations, or supporting information]

[Closing paragraph - Summarize your main points and indicate any desired action]

Sincerely,

[Your Signature]
[Your Typed Name]''',
    ),
    DocumentTemplate(
      id: 'resume',
      name: 'Resume/CV',
      description: 'Professional resume template',
      category: 'Career',
      icon: Icons.person,
      content: '''[YOUR NAME]
[Your Address] | [Phone] | [Email] | [LinkedIn]

PROFESSIONAL SUMMARY
[Brief 2-3 sentence summary highlighting your experience and key qualifications]

EXPERIENCE

[Job Title] | [Company Name] | [Location]
[Start Date] - [End Date]
• [Achievement or responsibility]
• [Achievement or responsibility]
• [Achievement or responsibility]

[Job Title] | [Company Name] | [Location]
[Start Date] - [End Date]
• [Achievement or responsibility]
• [Achievement or responsibility]
• [Achievement or responsibility]

EDUCATION

[Degree] in [Field of Study]
[University Name] | [Location] | [Graduation Year]
• [Relevant coursework, honors, or achievements]

SKILLS
• [Skill Category]: [List specific skills]
• [Skill Category]: [List specific skills]
• [Skill Category]: [List specific skills]

CERTIFICATIONS
• [Certification Name] - [Issuing Organization] ([Year])

PROJECTS
[Project Name]
• [Brief description and key accomplishments]''',
    ),
    DocumentTemplate(
      id: 'project_proposal',
      name: 'Project Proposal',
      description: 'Comprehensive project planning document',
      category: 'Business',
      icon: Icons.folder,
      content: '''Project Proposal

Project Title: [Insert Title]
Prepared by: [Your Name]
Date: [Insert Date]

EXECUTIVE SUMMARY
[Brief overview of the project - 2-3 paragraphs]

PROJECT OBJECTIVES
• [Objective 1]
• [Objective 2]
• [Objective 3]

BACKGROUND
[Context and rationale for the project]

SCOPE OF WORK
Phase 1: [Phase Name]
• [Deliverable 1]
• [Deliverable 2]

Phase 2: [Phase Name]
• [Deliverable 1]
• [Deliverable 2]

TIMELINE
Milestone 1: [Description] - [Date]
Milestone 2: [Description] - [Date]
Milestone 3: [Description] - [Date]

BUDGET
[Budget breakdown and justification]

RESOURCES REQUIRED
• Personnel: [List]
• Equipment: [List]
• Software/Tools: [List]

RISK ASSESSMENT
Risk 1: [Description] - Mitigation: [Strategy]
Risk 2: [Description] - Mitigation: [Strategy]

SUCCESS METRICS
• [Metric 1]
• [Metric 2]
• [Metric 3]

CONCLUSION
[Summary and call to action]''',
    ),
    DocumentTemplate(
      id: 'blog_post',
      name: 'Blog Post',
      description: 'Structured blog article template',
      category: 'Content',
      icon: Icons.article,
      content: '''[Compelling Blog Title]

Meta Description: [SEO-friendly description, 150-160 characters]

Introduction
[Hook your readers with an interesting opening. Present the problem or topic you'll address.]

[Main Point 1]
[Detailed explanation, examples, or story]

[Main Point 2]
[Detailed explanation, examples, or story]

[Main Point 3]
[Detailed explanation, examples, or story]

Conclusion
[Summarize key takeaways and include a call-to-action]

Key Takeaways:
• [Takeaway 1]
• [Takeaway 2]
• [Takeaway 3]

---
Author: [Your Name]
Published: [Date]
Tags: [tag1, tag2, tag3]''',
    ),
    DocumentTemplate(
      id: 'research_notes',
      name: 'Research Notes',
      description: 'Academic research documentation',
      category: 'Academic',
      icon: Icons.science,
      content: '''Research Notes

Topic: [Research Topic]
Date: [Date]
Source: [Source Information]

RESEARCH QUESTION
[Main question or hypothesis]

KEY FINDINGS
1. [Finding 1]
   - Evidence: [Supporting data]
   - Significance: [Why it matters]

2. [Finding 2]
   - Evidence: [Supporting data]
   - Significance: [Why it matters]

3. [Finding 3]
   - Evidence: [Supporting data]
   - Significance: [Why it matters]

METHODOLOGY
[Brief description of research methods]

IMPORTANT QUOTES
"[Quote 1]" (Source, Page)
"[Quote 2]" (Source, Page)

ANALYSIS
[Your interpretation and insights]

RELATED TOPICS TO EXPLORE
• [Topic 1]
• [Topic 2]
• [Topic 3]

REFERENCES
[List of sources in appropriate citation format]

PERSONAL NOTES
[Your thoughts, questions, and connections]''',
    ),
    DocumentTemplate(
      id: 'daily_journal',
      name: 'Daily Journal',
      description: 'Personal reflection and planning',
      category: 'Personal',
      icon: Icons.book,
      content: '''Daily Journal Entry

Date: [Today's Date]
Day: [Day of Week]

GRATITUDE
Today I'm grateful for:
1. [Item 1]
2. [Item 2]
3. [Item 3]

TODAY'S GOALS
☐ [Goal 1]
☐ [Goal 2]
☐ [Goal 3]

MORNING REFLECTION
[How are you feeling? What's on your mind?]

TODAY'S EVENTS
[Describe what happened today]

CHALLENGES & LESSONS
Challenge: [What was difficult?]
Lesson: [What did you learn?]

WINS & ACHIEVEMENTS
• [Achievement 1]
• [Achievement 2]

EVENING REFLECTION
[How did the day go? What would you do differently?]

TOMORROW'S PRIORITIES
1. [Priority 1]
2. [Priority 2]
3. [Priority 3]

MOOD: [Rate 1-10]
ENERGY: [Rate 1-10]
PRODUCTIVITY: [Rate 1-10]''',
    ),
    DocumentTemplate(
      id: 'weekly_report',
      name: 'Weekly Report',
      description: 'Progress tracking and status updates',
      category: 'Business',
      icon: Icons.assessment,
      content: '''Weekly Status Report

Week of: [Date Range]
Submitted by: [Your Name]
Department/Team: [Team Name]

EXECUTIVE SUMMARY
[Brief overview of the week's activities and outcomes]

ACCOMPLISHMENTS
✓ [Accomplishment 1]
✓ [Accomplishment 2]
✓ [Accomplishment 3]

ONGOING PROJECTS
Project 1: [Name]
Status: [On Track / At Risk / Behind Schedule]
Progress: [XX%]
Next Steps: [Description]

Project 2: [Name]
Status: [On Track / At Risk / Behind Schedule]
Progress: [XX%]
Next Steps: [Description]

CHALLENGES & BLOCKERS
• [Challenge 1] - Impact: [High/Medium/Low]
  Solution: [Proposed solution]
• [Challenge 2] - Impact: [High/Medium/Low]
  Solution: [Proposed solution]

KEY METRICS
• [Metric 1]: [Value] (Target: [Target])
• [Metric 2]: [Value] (Target: [Target])
• [Metric 3]: [Value] (Target: [Target])

NEXT WEEK'S PRIORITIES
1. [Priority 1]
2. [Priority 2]
3. [Priority 3]

SUPPORT NEEDED
• [Resource or support needed]

ADDITIONAL NOTES
[Any other relevant information]''',
    ),
    DocumentTemplate(
      id: 'todo_list',
      name: 'Task List',
      description: 'Organized task management',
      category: 'Productivity',
      icon: Icons.checklist,
      content: '''Task List

Date: [Date]

HIGH PRIORITY
☐ [Task 1] - Due: [Date]
☐ [Task 2] - Due: [Date]
☐ [Task 3] - Due: [Date]

MEDIUM PRIORITY
☐ [Task 1] - Due: [Date]
☐ [Task 2] - Due: [Date]
☐ [Task 3] - Due: [Date]

LOW PRIORITY
☐ [Task 1] - Due: [Date]
☐ [Task 2] - Due: [Date]

IN PROGRESS
→ [Task in progress]
→ [Task in progress]

COMPLETED TODAY
✓ [Completed task]
✓ [Completed task]

WAITING ON OTHERS
⏳ [Task] - Waiting for: [Person/Info]
⏳ [Task] - Waiting for: [Person/Info]

NOTES
[Additional notes or context]''',
    ),
  ];
  static List<String> get categories {
    return templates.map((t) => t.category).toSet().toList()..sort();
  }

  static List<DocumentTemplate> getTemplatesByCategory(String category) {
    return templates.where((t) => t.category == category).toList();
  }
}
