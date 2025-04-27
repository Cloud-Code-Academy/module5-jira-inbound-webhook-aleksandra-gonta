public with sharing class JiraWrapper {
	public class ProjectWrapper {
		public String name;
		public String key;
		public String id;
		public String description;
	}

	public class IssueWrapper {
		public String key;
		public Fields fields;
	}

	public class Fields {
		public String summary;
		public String description;
		public IssueType issuetype;
		public Status status;
	}

	public class IssueType {
		public String name;
	}

	public class Status {
		public String name;
	}
}
