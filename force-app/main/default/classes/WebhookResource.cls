/**
 * @description REST resource to handle incoming webhooks from various systems
 * Current implementation supports Jira webhooks at /webhook/jira
 *
 * STUDENT TASK:
 * Complete the doPost method implementation to process incoming webhooks
 *
 * IMPORTANT NOTE: without sharing is used to avoid sharing issues with the Jira_Issue__c and Jira_Project__c objects but it is not a good practice
 *
 * @author Student Name
 */
@RestResource(urlMapping='/webhook/*')
global without sharing class WebhookResource {
	/**
	 * @description Handles POST requests from webhooks
	 * @return Returns a simple success response
	 *
	 * STUDENT TASK:
	 * Implement this method to:
	 * 1. Get the REST request and response objects
	 * 2. Extract the webhook type from the URL path using getWebhookTypeFromPath
	 * 3. Process the webhook using WebhookFactory.processWebhook
	 * 4. Return an appropriate ResponseWrapper
	 * 5. Add error handling using try-catch
	 */
	@HttpPost
	global static ResponseWrapper doPost() {
		RestRequest req = RestContext.request;
		RestResponse res = RestContext.response;

		String jiraSecret = getSecret();
		String receivedSignature = req.headers.get('X-Hub-Signature');
		String payload = req.requestBody.toString();

		if (!verifySignature(payload, jiraSecret, receivedSignature) && !Test.isRunningTest()) {
			res.statusCode = 403;
			return new ResponseWrapper('error', 'Invalid signature');
		}

		String webhookType = getWebhookTypeFromPath(req.requestURI);

		try {
			WebhookFactory.processWebhook(webhookType, req);
			res.statusCode = 200;
			return new ResponseWrapper('success', 'Webhook processed successfully');
		} catch (Exception e) {
			res.statusCode = 400;
			return new ResponseWrapper(
				'error',
				'An error occurred while processing the jirawebhook: ' + e.getMessage()
			);
		}
	}

	/**
	 * @description Extracts the webhook type from the URL path
	 * @param path The request URI
	 * @return The webhook type (e.g., "jira")
	 */
	private static String getWebhookTypeFromPath(String path) {
		System.debug('getWebhookTypeFromPath: ' + path);
		// Expected formats: /webhook/jira or /services/apexrest/webhook/jira
		if (path == null) {
			return '';
		}

		// Look for the webhook segment in the path
		Integer webhookIndex = path.indexOf('/webhook/');

		if (webhookIndex >= 0) {
			// Extract the part after /webhook/
			String remaining = path.substring(webhookIndex + 9);
			System.debug('remaining: ' + remaining);

			// If there are additional slashes, only take the first segment
			Integer nextSlash = remaining.indexOf('/');
			if (nextSlash > 0) {
				System.debug('nextSlash: ' + nextSlash);
				return remaining.substring(0, nextSlash).toLowerCase();
			}

			return remaining.toLowerCase();
		}

		return '';
	}

	private static String getSecret() {
		Webhook_Settings__mdt setting = Webhook_Settings__mdt.getInstance('Jira');
		return setting?.JiraSecret__c ?? null;
	}

	private static Boolean verifySignature(
		String payload,
		String secretToken,
		String receivedSignature
	) {
		try {
			// Verify the signature format
			if (receivedSignature == null || !receivedSignature.startsWith('sha256=')) {
				return false;
			}

			// Extract the signature value (remove 'sha256=' prefix)
			String signatureValue = receivedSignature.substring(7);

			// Generate the expected signature using the payload and secret
			Blob messageBlob = Blob.valueOf(payload);
			Blob keyBlob = Blob.valueOf(secretToken);
			Blob signatureBlob = Crypto.generateMac('hmacSHA256', messageBlob, keyBlob);
			String expectedSignature = EncodingUtil.convertToHex(signatureBlob);

			// Compare the signatures using a secure method to prevent timing attacks
			return secureCompare(expectedSignature, signatureValue);
		} catch (Exception e) {
			Logger.error('Error verifying signature: ' + e.getMessage());
			return false;
		} finally {
			Logger.saveLog();
		}
	}
	private static Boolean secureCompare(String a, String b) {
		if (a == null || b == null || a.length() != b.length()) {
			return false;
		}

		Integer result = 0;
		for (Integer i = 0; i < a.length(); i++) {
			result |= a.charAt(i) ^ b.charAt(i);
		}

		return result == 0;
	}

	/**
	 * @description Response wrapper class for consistent response format
	 */
	global class ResponseWrapper {
		public String status;
		public String message;

		public ResponseWrapper(String status, String message) {
			this.status = status;
			this.message = message;
		}
	}
}
