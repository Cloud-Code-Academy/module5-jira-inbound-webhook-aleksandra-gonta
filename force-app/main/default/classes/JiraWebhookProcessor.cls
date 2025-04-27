/**
 * @description Processor for Jira webhooks
 * Handles issue and project events from Jira
 *
 * STUDENT TASK:
 * Implement the IWebhookProcessor interface to handle Jira webhook events
 * You'll need to process various events like issue/project creation, updates, and deletions
 *
 * IMPORTANT NOTE: without sharing is used to avoid sharing issues with the Jira_Issue__c and Jira_Project__c objects but it is not a good practice
 *
 * @author Student Name
 */
public without sharing class JiraWebhookProcessor implements IWebhookProcessor {
	// Constants for webhook event types
	private static final String EVENT_ISSUE_CREATED = 'jira:issue_created';
	private static final String EVENT_ISSUE_UPDATED = 'jira:issue_updated';
	private static final String EVENT_ISSUE_DELETED = 'jira:issue_deleted';
	private static final String EVENT_PROJECT_CREATED = 'project_created';
	private static final String EVENT_PROJECT_UPDATED = 'project_updated';
	private static final String EVENT_PROJECT_DELETED = 'project_deleted';

	/**
	 * @description Validates the incoming Jira webhook request
	 * @param request The REST request containing the webhook payload
	 * @return Boolean True if the request is valid, false otherwise
	 *
	 * STUDENT TASK:
	 * Implement validation logic for Jira webhooks
	 * - Check for valid JSON by deserializing the request body
	 * - Verify the 'webhookEvent' field exists in the payload
	 * - You can add further validation like checking for specific headers
	 * - Return true if valid, false otherwise
	 *
	 * HINT:
	 * 1. Use try-catch to handle JSON deserialization errors
	 * 2. Cast the deserialized JSON to Map<String, Object>
	 * 3. Check if required keys exist using containsKey()
	 * 4. Example: if (!payload.containsKey('webhookEvent')) { return false; }
	 */
	public Boolean validate(RestRequest request) {
		try {
			String requestBody = request.requestBody.toString();
			Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(
				requestBody
			);

			if (!payload.containsKey('webhookEvent')) {
				return false;
			} else {
				return true;
			}
		} catch (Exception e) {
			Logger.error('Error validating webhook: ' + e.getMessage());
			return false;
		} finally {
			Logger.saveLog();
		}
	}

	/**
	 * @description Processes the Jira webhook request
	 * @param request The REST request containing the webhook payload
	 *
	 * STUDENT TASK:
	 * Implement the main processing logic
	 * - Parse the JSON payload from the request body
	 * - Extract the 'webhookEvent' field to determine the event type
	 * - Call the appropriate handler method based on the event type
	 *
	 * HINT:
	 * 1. Use JSON.deserializeUntyped() to convert the request body to a Map
	 * 2. Extract the event type: String webhookEvent = (String) payload.get('webhookEvent');
	 * 3. Use if/else or switch statements to call the appropriate handler
	 * 4. Example: if (webhookEvent == EVENT_ISSUE_CREATED) { processIssueCreated(payload); }
	 */

	public void process(RestRequest request) {
		try {
			String requestBody = request.requestBody.toString();
			Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(
				requestBody
			);
			String webhookEvent = (String) payload.get('webhookEvent');

			if (webhookEvent == EVENT_ISSUE_CREATED) {
				processIssueCreated(payload);
			} else if (webhookEvent == EVENT_ISSUE_UPDATED) {
				processIssueUpdated(payload);
			} else if (webhookEvent == EVENT_ISSUE_DELETED) {
				processIssueDeleted(payload);
			} else if (webhookEvent == EVENT_PROJECT_CREATED) {
				processProjectCreated(payload);
			} else if (webhookEvent == EVENT_PROJECT_UPDATED) {
				processProjectUpdated(payload);
			} else if (webhookEvent == EVENT_PROJECT_DELETED) {
				processProjectDeleted(payload);
			} else {
				Logger.error('Unknown webhook event: ' + webhookEvent);
				Logger.saveLog();
			}
		} catch (Exception e) {
			Logger.error('Error processing webhook: ' + e.getMessage());
			throw e;
		} finally {
			Logger.saveLog();
		}
	}

	/**
	 * @description Process an issue_created event
	 * @param payload The webhook payload
	 *
	 * STUDENT TASK:
	 * Use this example as a template for other event handlers
	 */
	private void processIssueCreated(Map<String, Object> payload) {
		try {
			// Example implementation:

			// 1. Extract issue data from the payload
			Map<String, Object> issueData = (Map<String, Object>) payload.get('issue');

			// 2. Create a new Jira_Issue__c record using the helper method
			Jira_Issue__c newIssue = createIssueRecord(issueData);

			// 3. Insert the new record
			insert newIssue;

			// 4. Log success
			System.debug('Created Jira issue record: ' + newIssue.Id);
		} catch (Exception e) {
			Logger.error('Error processing issue_created event: ' + e.getMessage());
			throw e;
		} finally {
			Logger.saveLog();
		}
	}

	/**
	 * @description Process an issue_updated event
	 * @param payload The webhook payload
	 *
	 * STUDENT TASK:
	 * Implement logic to update an existing Jira_Issue__c record
	 * If the record doesn't exist, create it
	 */
	private void processIssueUpdated(Map<String, Object> payload) {
		try {
			Map<String, Object> issueData = (Map<String, Object>) payload.get('issue');
			String issueKey = (String) issueData.get('key');
			Jira_Issue__c issueRecord;

			List<Jira_Issue__c> issueList = [
				SELECT Id
				FROM Jira_Issue__c
				WHERE Issue_Key__c = :issueKey
				LIMIT 1
			];

			Jira_Issue__c existingIssue = issueList.isEmpty() ? null : issueList[0];
			if (existingIssue == null) {
				issueRecord = createIssueRecord(issueData);
			} else {
				issueRecord = updateIssueRecord(existingIssue, issueData);
			}

			upsert issueRecord;
			// 4. Log success
			System.debug('Jira issue record: ' + issueRecord.Id);
		} catch (Exception e) {
			Logger.error('Error processing issue_created event: ' + e.getMessage());
			throw e;
		} finally {
			Logger.saveLog();
		}
	}

	/**
	 * @description Process an issue_deleted event
	 * @param payload The webhook payload
	 *
	 * STUDENT TASK:
	 * Implement logic to delete a Jira_Issue__c record
	 */
	private void processIssueDeleted(Map<String, Object> payload) {
		try {
			Map<String, Object> issueData = (Map<String, Object>) payload.get('issue');
			String issueKey = (String) issueData.get('key');

			List<Jira_Issue__c> issueList = [
				SELECT Id
				FROM Jira_Issue__c
				WHERE Issue_Key__c = :issueKey
				LIMIT 1
			];

			Jira_Issue__c existingIssue = issueList.isEmpty() ? null : issueList[0];

			if (existingIssue != null) {
				delete existingIssue;
			}
		} catch (Exception e) {
			Logger.error('Error processing issue_created event: ' + e.getMessage());
			throw e;
		} finally {
			Logger.saveLog();
		}
	}

	/**
	 * @description Process a project_created event
	 * @param payload The webhook payload
	 *
	 * STUDENT TASK:
	 * Implement logic to create a Jira_Project__c record
	 */
	private void processProjectCreated(Map<String, Object> payload) {
		try {
			Map<String, Object> projectData = (Map<String, Object>) payload.get('project');
			Jira_Project__c newProject = createProjectRecord(projectData);

			insert newProject;

			System.debug('Created Jira issue record: ' + newProject.Id);
		} catch (Exception e) {
			Logger.error('Error processing project_created event: ' + e.getMessage());
			throw e;
		} finally {
			Logger.saveLog();
		}
	}

	/**
	 * @description Process a project_updated event
	 * @param payload The webhook payload
	 *
	 * STUDENT TASK:
	 * Implement logic to update an existing Jira_Project__c record
	 * If the record doesn't exist, create it
	 */
	private void processProjectUpdated(Map<String, Object> payload) {
		try {
			Map<String, Object> projectData = (Map<String, Object>) payload.get('project');
			String projectKey = (String) projectData.get('key');
			Jira_Project__c projectRecord;

			List<Jira_Project__c> projectList = [
				SELECT Id
				FROM Jira_Project__c
				WHERE Project_Key__c = :projectKey
				LIMIT 1
			];

			Jira_Project__c existingProject = projectList.isEmpty() ? null : projectList[0];

			if (existingProject == null) {
				projectRecord = createProjectRecord(projectData);
			} else {
				projectRecord = updateProjectRecord(existingProject, projectData);
			}

			upsert projectRecord;
			System.debug('Jira issue record: ' + projectRecord.Id);
		} catch (Exception e) {
			Logger.error('Error processing issue_created event: ' + e.getMessage());
			throw e;
		} finally {
			Logger.saveLog();
		}
	}

	/**
	 * @description Process a project_deleted event
	 * @param payload The webhook payload
	 *
	 * STUDENT TASK:
	 * Implement logic to delete a Jira_Project__c record
	 */
	private void processProjectDeleted(Map<String, Object> payload) {
		try {
			Map<String, Object> projectData = (Map<String, Object>) payload.get('project');
			String projectKey = (String) projectData.get('key');

			List<Jira_Project__c> projectList = [
				SELECT Id
				FROM Jira_Project__c
				WHERE Project_Key__c = :projectKey
				LIMIT 1
			];

			Jira_Project__c existingProject = projectList.isEmpty() ? null : projectList[0];

			if (existingProject != null) {
				delete existingProject;
			}
		} catch (Exception e) {
			Logger.error('Error processing project_created event: ' + e.getMessage());
			throw e;
		} finally {
			Logger.saveLog();
		}
	}

	/**
	 * @description Create a Jira_Issue__c record from issue data
	 * @param issueData The issue data from the webhook
	 * @return Jira_Issue__c The newly created issue record
	 *
	 * STUDENT TASK:
	 * Implement logic to extract issue fields and create a record
	 *
	 * HINT:
	 * 1. Extract data from the issueData map (key, summary, status, etc.)
	 * 2. Map the fields to a new Jira_Issue__c record
	 */
	private Jira_Issue__c createIssueRecord(Map<String, Object> issueData) {
		String issueKey = (String) issueData.get('key');
		String projectKey = issueKey.substringBefore('-');

		Map<String, Object> fields = (Map<String, Object>) issueData.get('fields');
		String summary = (String) fields.get('summary');
		String description = (String) fields.get('description');
		Map<String, Object> issueType = (Map<String, Object>) fields.get('issuetype');
		String issueTypeName = (String) issueType.get('name');
		Map<String, Object> status = (Map<String, Object>) fields.get('status');
		String statusName = (String) status.get('name');

		Jira_Issue__c issue = new Jira_Issue__c(
			Issue_Key__c = issueKey,
			Summary__c = summary,
			Description__c = description,
			Project_Key__c = projectKey,
			Issue_Type__c = issueTypeName,
			Status__c = statusName,
			Last_Updated__c = DateTime.now()
		);
		return issue;
	}

	/**
	 * @description Update a Jira_Issue__c record from issue data
	 * @param existingIssue The existing issue record
	 * @param issueData The updated issue data from the webhook
	 * @return Jira_Issue__c The updated issue record
	 *
	 * STUDENT TASK:
	 * Implement logic to extract issue fields and update a record
	 */
	private Jira_Issue__c updateIssueRecord(
		Jira_Issue__c existingIssue,
		Map<String, Object> issueData
	) {
		Map<String, Object> fields = (Map<String, Object>) issueData.get('fields');
		String summary = (String) fields.get('summary');
		String description = (String) fields.get('description');
		Map<String, Object> issueType = (Map<String, Object>) fields.get('issuetype');
		String issueTypeName = (String) issueType.get('name');
		Map<String, Object> status = (Map<String, Object>) fields.get('status');
		String statusName = (String) status.get('name');

		existingIssue.Summary__c = summary;
		existingIssue.Description__c = description;
		existingIssue.Last_Updated__c = DateTime.now();
		existingIssue.Issue_Type__c = issueTypeName;
		existingIssue.Status__c = statusName;

		return existingIssue;
	}

	/**
	 * @description Create a Jira_Project__c record from project data
	 * @param projectData The project data from the webhook
	 * @return Jira_Project__c The newly created project record
	 *
	 * STUDENT TASK:
	 * Implement logic to extract project fields and create a record
	 */
	private Jira_Project__c createProjectRecord(Map<String, Object> projectData) {
		String projectKey = (String) projectData.get('key');
		String name = (String) projectData.get('name');
		String projectId = String.valueOf(projectData.get('id'));
		String description = String.valueOf(projectData.get('description'));

		Jira_Project__c project = new Jira_Project__c(
			Project_Key__c = projectKey,
			Name = name,
			Project_Name__c = name,
			Project_ID__c = projectId,
			Description__c = description,
			Created_Date__c = DateTime.now()
		);
		return project;
	}

	/**
	 * @description Update a Jira_Project__c record from project data
	 * @param existingProject The existing project record
	 * @param projectData The updated project data from the webhook
	 * @return Jira_Project__c The updated project record
	 *
	 * STUDENT TASK:
	 * Implement logic to extract project fields and update a record
	 */
	private Jira_Project__c updateProjectRecord(
		Jira_Project__c existingProject,
		Map<String, Object> projectData
	) {
		String name = (String) projectData.get('name');
		String description = String.valueOf(projectData.get('description'));

		existingProject.Name = name;
		existingProject.Project_Name__c = name;
		existingProject.Description__c = description;

		return existingProject;
	}
}
